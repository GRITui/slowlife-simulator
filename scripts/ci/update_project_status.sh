#!/usr/bin/env bash
# Regenerates ops/PROJECT_STATUS.md — a plain, auto-updating Kanban +
# milestones + RACI file for the project sponsor, so status is checkable
# without asking the lead dev directly.
#
# Deliberately mechanical: reads ops/backlog-inbox.md (source of truth for
# <status>/<priority>/RACI-relevant notes) + `gh issue list` (source of
# truth for open/closed + issue numbers), and rewrites the status file to
# match. No judgment calls are needed here — a low-reasoning-effort free
# model is intentionally sufficient and cheaper than a full Claude session.
#
# Run manually: bash scripts/ci/update_project_status.sh
# Run via cron: see the crontab entry installed alongside this script
# (dedup by rewriting the whole table, per this project's own cron rule —
# never `(crontab -l; echo "$LINE") | crontab -`, it duplicates on rerun).

set -euo pipefail
cd "$(dirname "$0")/../.."

REPO="GRITui/slowlife-simulator"
OUT="ops/PROJECT_STATUS.md"

ISSUES="$(gh issue list --repo "$REPO" --state all --limit 60 \
	--json number,title,state,updatedAt \
	--jq '.[] | "\(.number)\t\(.state)\t\(.updatedAt)\t\(.title)"')"
BACKLOG="$(cat ops/backlog-inbox.md)"

PROMPT="You are regenerating a single status file for a non-technical project sponsor who wants to check progress WITHOUT asking the lead dev directly. This is a mechanical data-transformation task — read the context below, do not editorialize, do not add commentary, do not invent facts.

=== gh issue list (number, state, updatedAt, title) ===
${ISSUES}

=== ops/backlog-inbox.md (full contents) ===
${BACKLOG}

=== END CONTEXT ===

Using ONLY the context above, OVERWRITE the file ops/PROJECT_STATUS.md with a markdown file in exactly this shape:

# Project Status
_Auto-updated by scripts/ci/update_project_status.sh — do not hand-edit, it will be overwritten._
Last updated: <today's date, from running the \`date\` command>

## Kanban

### Backlog
- TASK-XXX: <title> (#<issue number>) — one line per task_item whose <status> is SPECCED

### Doing
- TASK-XXX: <title> (#<issue number>) — one line per task_item whose <status> is DOING

### Done
- TASK-XXX: <title> (#<issue number>) — one line per task_item whose <status> is COMPLETED, most recently completed first

### Open GitHub issues not yet in backlog-inbox.md
- #<number>: <title> — list any OPEN issue from the gh issue list with no matching TASK-XXX entry in backlog-inbox.md (match by title text, e.g. an issue titled 'TASK-354: ...' matches a task_item with <id>TASK-354</id>)

## Milestones
Group the Doing/Backlog/Done tasks into whatever sprint groupings are evident from backlog-inbox.md's own text (task descriptions often state things like 'Sprint order: #199 -> #203 -> ...'). List each sprint's tasks and whether the sprint is fully Done, partially Doing, or all Backlog.

## RACI (current sprint's tasks only — the Doing task(s) plus whatever's next in that sprint's stated order)
| Task | Responsible | Accountable | Consulted | Informed |
|---|---|---|---|---|
Fill one row per task in the CURRENT sprint. Default RACI values when not stated explicitly in the backlog notes: Responsible = Cline (delegate) for GDScript/gameplay work, or Claude for shader/UI-safe-area/narrative/save-schema work (backlog-inbox.md's own text usually says which of these applies); Accountable = Claude for the Code Quality Review + merge; Consulted = blank unless the notes mention a research pass or an owner decision was needed; Informed = ops/backlog-inbox.md + the GitHub issue (always).

Rules:
- If a task_item's <status> doesn't cleanly map to Backlog/Doing/Done, put it in Backlog and note '(status unclear)' next to it.
- Keep every line short — this is a glance-able status file, not a report.
- Keep the header comment line telling the sponsor not to hand-edit it.
- Write the file, then stop. Do not summarize what you did in chat output beyond a one-line confirmation."

cline -P openrouter -k "${OPENROUTER_API_KEY:?OPENROUTER_API_KEY not set}" \
	-m minimax/minimax-m3:free --thinking low --auto-approve true \
	-c "$(pwd)" -t 300 "$PROMPT"

echo "== $OUT regenerated =="

# Commit + push so the sponsor can check status on GitHub without needing
# local file access. Scoped to ONLY this one file (never a broad `git add`,
# in case the main checkout has unrelated uncommitted work in progress at
# the time this cron fires) and fully non-destructive: pull --ff-only
# first (never rebase/merge over local state), and if the push still
# fails (e.g. a real push landed in between), log it and stop — no retry
# loop, no force-push, per this project's git safety rules.
git pull --ff-only origin main >/dev/null 2>&1 || {
	echo "== git pull --ff-only failed, skipping commit this run (local main likely has unpushed work) =="
	exit 0
}
if [ -n "$(git status --porcelain -- "$OUT")" ]; then
	git add "$OUT"
	git commit -m "chore(status): auto-update ${OUT} [cron]" >/dev/null
	if git push origin main >/dev/null 2>&1; then
		echo "== ${OUT} committed and pushed =="
	else
		echo "== push failed, left committed locally for the next run to retry =="
	fi
else
	echo "== ${OUT} unchanged, nothing to commit =="
fi
