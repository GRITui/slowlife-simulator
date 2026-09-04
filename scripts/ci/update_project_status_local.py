#!/usr/bin/env python3
"""Local, model-free variant of update_project_status.sh's Kanban generator.

Same job (regenerate ops/PROJECT_STATUS.md from ops/backlog-inbox.md +
`gh issue list`) but with NO LLM call at all — status-to-Kanban-column and
issue-matching are both 100% deterministic (a fixed status->column map plus
a title-prefix string match), so asking any model, cloud or local, to do
this is pure overhead with a real accuracy risk on top.

WHY this replaces the local-Ollama attempt rather than tuning it further:
tested two locally-available models on 2026-09-04 against this exact task.
qwen2.5-coder:3b (fast, ~100s) hallucinated task rows that don't exist in
its own input table and misfiled a real task (TASK-361, actual status
NEEDS_OWNER_REVIEW) into the wrong column with a fabricated issue number.
qwen3.5:9b timed out after 3+ minutes on this machine's 8GB RAM (this Mac
mini cannot run vLLM either — confirmed separately, no practical Apple
Silicon support and nowhere near the memory headroom it wants). Given the
underlying transformation has zero judgment calls in it, the fix isn't a
better model, it's removing the model — same "lean toward the simpler
approach, skip the LLM step when plain code suffices" principle already
applied in scripts/ci/sync_github_kanban.py.

Deliberately narrower than the cloud version: no Milestones section (that
one genuinely mines sprint-order hints out of backlog prose, which this
script does not attempt), and RACI is a single stated default rule rather
than a per-task table — same accepted simplification, now for a different
reason (no free-text mining at all here, not a model-size concession).
"""

import json
import re
import subprocess
import sys
from datetime import date

REPO = "GRITui/slowlife-simulator"
BACKLOG_PATH = "ops/backlog-inbox.md"
OUT_PATH = "ops/PROJECT_STATUS.md"

STATUS_TO_COLUMN = {
    "SPECCED": "Backlog",
    "NEEDS_OWNER_REVIEW": "Backlog",
    "DOING": "Doing",
    "COMPLETED": "Done",
    "RESOLVED": "Done",
    "RESOLVED_NO_ACTION": "Done",
}


def parse_backlog(path):
    with open(path, encoding="utf-8") as f:
        content = f.read()
    blocks = re.findall(r"<task_item>(.*?)</task_item>", content, re.DOTALL)
    tasks = []
    for block in blocks:
        def grab(tag):
            m = re.search(rf"<{tag}>(.*?)</{tag}>", block, re.DOTALL)
            return m.group(1).strip() if m else ""
        task_id = grab("id")
        if not task_id:
            continue
        tasks.append({
            "id": task_id,
            "source": grab("source"),
            "status": grab("status"),
            "title": grab("title"),
        })
    return tasks


def gh_issues():
    result = subprocess.run(
        ["gh", "issue", "list", "--repo", REPO, "--state", "all", "--limit", "300",
         "--json", "number,title,state"],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        print(f"[warn] gh issue list failed: {result.stderr.strip()}", file=sys.stderr)
        return []
    return json.loads(result.stdout)


def match_issue(task_id, issues):
    marker = f"{task_id}:"
    for issue in issues:
        if issue["title"].startswith(marker):
            return issue
    return None


def render(tasks, issues):
    matched_numbers = set()
    columns = {"Backlog": [], "Doing": [], "Done": []}
    unmapped = []

    for t in tasks:
        issue = match_issue(t["id"], issues)
        num = f"#{issue['number']}" if issue else "(no issue)"
        if issue:
            matched_numbers.add(issue["number"])
        line = f"- {t['id']}: {t['title']} ({num})"
        column = STATUS_TO_COLUMN.get(t["status"])
        if column:
            columns[column].append(line)
        else:
            unmapped.append(f"- {t['id']}: {t['title']} ({num}) — (status unclear: {t['status']})")

    columns["Backlog"].extend(unmapped)

    orphan_issues = [i for i in issues if i["state"] == "OPEN" and i["number"] not in matched_numbers]
    orphan_lines = [f"- #{i['number']}: {i['title']}" for i in orphan_issues] or ["(none)"]

    def section(lines):
        return "\n".join(lines) if lines else "(none)"

    today = date.today().isoformat()

    return f"""# Project Status
_Auto-updated by scripts/ci/update_project_status_local.py (local, deterministic — no model call) — do not hand-edit, it will be overwritten._
Last updated: {today}

## Kanban

### Backlog
{section(columns["Backlog"])}

### Doing
{section(columns["Doing"])}

### Done
{section(columns["Done"])}

### Open GitHub issues not yet in backlog-inbox.md
{section(orphan_lines)}

## RACI (default rule — see scripts/ci/update_project_status_local.py's header comment for why this is a stated rule rather than a per-task table here)
Responsible = Cline (delegate) for source=AI-LOOP tasks, Claude for source=OWNER tasks needing design judgment. Accountable = Claude (Code Quality Review + merge), always. Consulted = blank unless noted in the GitHub issue body. Informed = ops/backlog-inbox.md + the GitHub issue, always.
"""


def main():
    tasks = parse_backlog(BACKLOG_PATH)
    issues = gh_issues()
    output = render(tasks, issues)
    with open(OUT_PATH, "w", encoding="utf-8") as f:
        f.write(output)
    print(f"[info] {len(tasks)} tasks, {len(issues)} gh issues -> wrote {OUT_PATH} ({len(output)} chars)")


if __name__ == "__main__":
    main()
