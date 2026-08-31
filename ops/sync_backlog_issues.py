#!/usr/bin/env python3
"""
sync_backlog_issues.py — Sync GitHub open issues BEFORE picking backlog task.
Fixes missed open issues (ENGINE-006..012) and stale backlog.

Workflow (must run before backlog pick):
  1. git fetch origin main + gh issue list --state open
  2. For each backlog todo with github_issue_number that is CLOSED -> skip pick
  3. For each open issue not in backlog -> add to backlog.json
  4. For each backlog todo without github_issue_number -> create GitHub issue (if --create-missing)

Usage: python3 ops/sync_backlog_issues.py [--dry-run] [--create-missing]
"""
import json
import subprocess
import sys
import re

REPO = "GRITui/slowlife-simulator"
BPATH = "backlog.json"


def gh(args):
    return subprocess.check_output(["gh"] + args, text=True).strip()


def fetch_issues(state="open"):
    out = gh(["-R", REPO, "issue", "list", "--state", state, "--limit", "100", "--json", "number,title,state,url,labels,body"])
    return json.loads(out)


def parse_task_id_from_title(title: str) -> str:
    # Title like "[ENGINE] ENGINE-006: ..." or "[ui] TASK-016: ..."
    m = re.search(r"\b(ENGINE-\d+|TASK-\d+)\b", title)
    return m.group(1) if m else ""


def labels_to_category_priority(labels):
    cat = "gameplay"
    pri = "medium"
    lane = None
    for l in labels:
        n = l["name"]
        if n.startswith("category:"):
            cat = n.split(":", 1)[1]
        elif n.startswith("priority:"):
            pri = n.split(":", 1)[1]
        elif n.startswith("lane:"):
            lane = n.split(":", 1)[1]
    return cat, pri, lane


def main():
    dry = "--dry-run" in sys.argv
    create_missing = "--create-missing" in sys.argv

    data = json.load(open(BPATH))
    issues_all = fetch_issues("all")
    issues_open = [i for i in issues_all if i["state"] == "OPEN"]
    by_num = {i["number"]: i for i in issues_all}
    open_nums = {i["number"] for i in issues_open}

    print(f"Fetched {len(issues_all)} issues ({len(issues_open)} open)")

    # 1. Check backlog -> issue sync (stale closed, missing linkage)
    for t in data["tasks"]:
        num = t.get("github_issue_number")
        if num and num in by_num:
            st = by_num[num]["state"]
            if st == "CLOSED" and t["status"] == "todo":
                print(f"SKIP {t['id']:12} #{num:2} CLOSED but backlog todo -> will skip pick (duplicate PR #{num} already merged)")
            elif st == "OPEN" and t["status"] == "todo":
                print(f"OK   {t['id']:12} #{num:2} OPEN todo")
        elif t["status"] == "todo" and not num:
            # Try fuzzy match by title
            found = None
            ttitle = t["title"].lower()[:40]
            for iss in issues_open:
                if ttitle in iss["title"].lower() or iss["title"].lower()[:40] in t["title"].lower():
                    found = iss
                    break
            if found:
                print(f"LINK {t['id']:12} backlog todo without number -> found open issue #{found['number']} {found['title'][:50]}")
                if not dry:
                    t["github_issue_number"] = found["number"]
                    t["github_issue_url"] = found["url"]
            else:
                print(f"MISSING {t['id']:12} todo without issue -> needs gh issue create: {t['title'][:60]}")
                if create_missing and not dry:
                    title = f"[{t['category']}] {t['id']}: {t['title']}"
                    body = f"Backlog sync: {t['id']} sprint {t.get('sprint','-')} priority {t['priority']}\n\n{t.get('notes','')}\n\nFiles: {', '.join(t.get('files',[]))}\n\nAuto-created by ops/sync_backlog_issues.py"
                    try:
                        out = gh(["-R", REPO, "issue", "create", "--title", title, "--body", body])
                        print(f"  created: {out}")
                        m = re.search(r"/issues/(\d+)", out)
                        if m:
                            t["github_issue_number"] = int(m.group(1))
                            t["github_issue_url"] = out.strip()
                    except subprocess.CalledProcessError as e:
                        print(f"  create failed: {e}")

    # 2. Check open issues not in backlog -> add to backlog
    bnums = {t.get("github_issue_number") for t in data["tasks"] if t.get("github_issue_number")}
    added = 0
    for iss in issues_open:
        num = iss["number"]
        if num not in bnums:
            tid = parse_task_id_from_title(iss["title"])
            if not tid:
                # Fallback: generate id from title
                tid = f"SYNC-{num}"
            # Avoid duplicates by id
            if any(t["id"] == tid for t in data["tasks"]):
                # Link number to existing task with same id but missing number
                for t in data["tasks"]:
                    if t["id"] == tid and not t.get("github_issue_number"):
                        print(f"LINK by id {tid} -> issue #{num}")
                        if not dry:
                            t["github_issue_number"] = num
                            t["github_issue_url"] = iss["url"]
                        break
                continue
            cat, pri, lane = labels_to_category_priority(iss["labels"])
            print(f"ADD   {tid:12} <- open issue #{num:2} {iss['title'][:60]}")
            if not dry:
                new_task = {
                    "id": tid,
                    "title": re.sub(r"^\[[^\]]+\]\s*", "", iss["title"]).replace(f"{tid}:", "").strip() or iss["title"],
                    "status": "todo",
                    "priority": pri,
                    "category": cat,
                    "files": [],
                    "github_issue_url": iss["url"],
                    "github_issue_number": num,
                    "notes": f"Auto-synced from open issue #{num} — missed before workflow fix. {iss['body'][:200] if iss.get('body') else ''}",
                }
                if lane:
                    new_task["lane"] = lane
                # Owner heuristic: engine lane -> set owner for known squads
                if lane == "engine":
                    if "spatial" in cat or "input" in cat:
                        new_task["owner"] = "spatial-physics"
                    elif "audio" in cat:
                        new_task["owner"] = "profiler-inspector"
                    elif "architecture" in cat:
                        new_task["owner"] = "backend-automation"
                    else:
                        new_task["owner"] = "backend-automation"
                data["tasks"].append(new_task)
                added += 1

    if added and not dry:
        print(f"Added {added} missing open issues to backlog")

    if not dry:
        # Backup
        open(BPATH + ".bak", "w").write(json.dumps(data, indent=2))
        json.dump(data, open(BPATH, "w"), indent=2)
        print(f"Wrote {BPATH} (+ .bak) — {len(data['tasks'])} tasks")
    else:
        print("Dry run — no write")


if __name__ == "__main__":
    main()
