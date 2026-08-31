#!/usr/bin/env bash
# sync_main.sh — keep local `main` identical to gatekeeper's `origin/main`
# Engine PO Step 1 helper: run before picking next backlog task so the
# autonomous loop never falls behind after squash-merges.
#
# What it does:
#   - fetches origin
#   - hard-resets local `main` to `origin/main` (tracking branch, no local commits)
#   - prunes worktrees and deletes local branches whose remote is gone
# Usage: scripts/ci/sync_main.sh [--no-prune]   (default: prune)
set -euo pipefail
cd "$(dirname "$0")/../.."

DO_PRUNE=true
if [[ "${1:-}" == "--no-prune" ]]; then
	DO_PRUNE=false
fi

if ! git rev-parse --verify origin/main >/dev/null 2>&1; then
	echo "sync_main: origin/main not found — fetching..." >&2
	git fetch origin
fi

echo "== sync_main: fetch origin =="
git fetch origin --prune

# Ensure we're on main (create if missing, e.g. detached HEAD worktree)
if ! git rev-parse --verify main >/dev/null 2>&1; then
	echo "sync_main: local main missing — creating from origin/main"
	git checkout -b main origin/main
else
	git checkout main 2>/dev/null || git checkout main
fi

echo "== sync_main: reset main to origin/main =="
# Show divergence before reset
BEHIND=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo "?")
AHEAD=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo "?")
if [[ "$BEHIND" != "0" || "$AHEAD" != "0" ]]; then
	echo "  local main: ahead $AHEAD, behind $BEHIND — resetting"
fi
git reset --hard origin/main

if [[ "$DO_PRUNE" == "true" ]]; then
	echo "== sync_main: prune worktrees =="
	git worktree prune || true
	echo "== sync_main: delete gone branches =="
	# Delete local branches whose upstream is gone (squash-merged PR branches)
	while IFS= read -r br; do
		# br is like "feature/ENGINE-003-save-load-state-machine"
		br_trim=$(echo "$br" | xargs)
		if [[ -n "$br_trim" && "$br_trim" != "main" ]]; then
			echo "  deleting gone branch $br_trim"
			git branch -D "$br_trim" 2>/dev/null || true
		fi
	done < <(git branch -vv | grep -E "\[.*: gone\]" | sed -E 's/^[ *]*([^ ]+).*/\1/' || true)
fi

echo "== sync_main: done =="
git status --short --branch | head -5
git log --oneline -3 | cat
# Revert stray asset import churn so engine PRs stay scoped
if ! git diff --quiet -- assets/ 2>/dev/null; then
	echo "  note: assets/ has import churn — run 'git checkout -- assets/' before committing engine PRs" >&2
fi
