#!/usr/bin/env bash
# land_task.sh — the mechanical merge/gate/push/cleanup sequence that's
# been done by hand identically for every task this session (and gotten
# the stash step wrong twice: once swallowing uncommitted backlog-inbox.md
# edits, once needing a recovery pop). Does NOT touch commit messages,
# diff review, or conflict resolution — those stay a human/Claude
# judgment call. Refuses to do anything destructive on failure; always
# leaves a clear trail instead of guessing.
#
# Usage: scripts/ci/land_task.sh <branch-name> <worktree-path> <merge-message-file>
#
# Preconditions this script checks, not assumes:
# - The worktree itself has NO uncommitted changes (you must review the
#   diff and `git commit` in the worktree yourself before calling this —
#   this script will not auto-generate a commit message for actual work).
# - Run from the main repo's working directory.
#
# On any merge conflict: leaves the conflict for manual resolution
# (does NOT abort, since conflict markers + `git status` are exactly
# what's needed to resolve by hand) and exits 1.
# On gate failure AFTER a successful merge: does NOT revert the merge
# (that's a judgment call — fix forward vs revert) — reports clearly
# and exits 1, but still restores any stashed WIP so nothing is lost.
# Only pushes + cleans up the worktree/branch if the gate is fully green.

set -uo pipefail

BRANCH="$1"
WORKTREE="$2"
MERGE_MSG_FILE="$3"

if [ ! -f "$MERGE_MSG_FILE" ]; then
  echo "ERROR: merge message file not found: $MERGE_MSG_FILE" >&2
  exit 1
fi

if [ -n "$(cd "$WORKTREE" && git status --short)" ]; then
  echo "ERROR: $WORKTREE has uncommitted changes. Review and commit them yourself first — this script never auto-commits real work." >&2
  exit 1
fi

STASHED=0
if [ -n "$(git status --short)" ]; then
  echo "=== land_task: stashing main's own WIP before merge ==="
  git stash push -u -m "land_task.sh: WIP before merging $BRANCH"
  STASHED=1
fi

restore_stash() {
  if [ "$STASHED" -eq 1 ]; then
    echo "=== land_task: restoring main's WIP ==="
    git stash pop
  fi
}

echo "=== land_task: merging $BRANCH ==="
if ! git merge --no-ff "$BRANCH" -F "$MERGE_MSG_FILE"; then
  echo "ERROR: merge conflict. Resolve by hand (git status shows the conflicted files), then commit and re-run gate manually — WIP stash left in place until you're done." >&2
  exit 1
fi

echo "=== land_task: running full gate (3x) ==="
if ! bash scripts/ci/stress_gate.sh 3; then
  echo "ERROR: gate failed AFTER merge completed. main now contains the merge commit — decide whether to fix forward or revert (git revert <merge-commit>), this script will not guess. Restoring your WIP stash now." >&2
  restore_stash
  exit 1
fi

echo "=== land_task: pushing ==="
if ! git push origin main; then
  echo "ERROR: push failed (remote may have moved). main has the merge commit locally, gate is green — resolve the push manually (do not force-push). Restoring your WIP stash now." >&2
  restore_stash
  exit 1
fi

echo "=== land_task: cleaning up worktree + branch ==="
git worktree remove "$WORKTREE"
git branch -d "$BRANCH"

restore_stash
echo "=== land_task: done, $BRANCH merged and pushed ==="
