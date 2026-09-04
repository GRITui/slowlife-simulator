#!/usr/bin/env bash
# Local, no-model variant of update_project_status.sh — same job, but the
# status->column mapping and issue-title matching are both deterministic,
# so this calls no LLM at all (cloud or local). See
# update_project_status_local.py's header comment for why this replaced
# an earlier local-Ollama attempt (tested and rejected: a 3B model
# hallucinated task rows, a 9B model was too slow for this machine's 8GB
# RAM — this machine can't run vLLM either, confirmed separately).
#
# NOT yet wired into cron. Run manually: bash scripts/ci/update_project_status_local.sh

set -euo pipefail
cd "$(dirname "$0")/../.."

python3 scripts/ci/update_project_status_local.py

echo "== ops/PROJECT_STATUS.md regenerated (local, deterministic) =="

# Same non-destructive commit/push discipline as update_project_status.sh:
# scoped to this one file only, pull --ff-only first, no retry/force-push.
git pull --ff-only origin main >/dev/null 2>&1 || {
	echo "== git pull --ff-only failed, skipping commit this run (local main likely has unpushed work) =="
	exit 0
}
if [ -n "$(git status --porcelain -- ops/PROJECT_STATUS.md)" ]; then
	git add ops/PROJECT_STATUS.md
	git commit -m "chore(status): auto-update ops/PROJECT_STATUS.md [local-deterministic]" >/dev/null
	if git push origin main >/dev/null 2>&1; then
		echo "== ops/PROJECT_STATUS.md committed and pushed =="
	else
		echo "== push failed, left committed locally for the next run to retry =="
	fi
else
	echo "== ops/PROJECT_STATUS.md unchanged, nothing to commit =="
fi
