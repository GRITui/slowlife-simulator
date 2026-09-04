#!/usr/bin/env bash
# start_task.sh — create a per-task worktree, the mechanical first step
# of every dispatch this session has done by hand identically each time.
#
# Usage: scripts/ci/start_task.sh <branch-name>
# Example: scripts/ci/start_task.sh task-364-example
#
# Worktree is created as a sibling directory: ../slowlife-game-<branch-name
# with the "task-" prefix and any trailing "-<slug>" stripped down to a
# short dirname>. Prints the worktree path on success so the caller can
# write/dispatch a prompt into it next.

set -euo pipefail

BRANCH="$1"
# Derive a short worktree dirname from the branch (task-364-foo-bar -> task364)
SHORT="$(echo "$BRANCH" | sed -E 's/^task-([0-9]+).*/task\1/')"
WORKTREE="../slowlife-game-${SHORT}"

if [ -e "$WORKTREE" ]; then
  echo "ERROR: $WORKTREE already exists — pick a different branch name or remove it first." >&2
  exit 1
fi

git worktree add -b "$BRANCH" "$WORKTREE" main
echo "WORKTREE_PATH=$WORKTREE"
