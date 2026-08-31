#!/usr/bin/env python3
"""
sync_backlog_issues.py — Sync GitHub open issues BEFORE picking backlog task.
Fixes missed open issues (ENGINE-006..012) and stale backlog.
"""
import json, subprocess, sys, os
REPO="GRITui/slowlife-simulator"
BPATH="/Users/grit/slowlife-game/backlog.json"
def gh(a): return subprocess.check_output(["gh"]+a, text=True).strip()
def main():
    dry="--dry-run" in sys.argv
    data=json.load(open(BPATH))
    issues=json.loads(gh(["-R",REPO,"issue","list","--state","all","--limit","100","--json","number,title,state,url,labels"]))
    by={i["number"]:i for i in issues}
    open_nums={i["number"] for i in issues if i["state"]=="OPEN"}
    done=0
    for t in data["tasks"]:
        num=t.get("github_issue_number")
        if num and num in by:
            st=by[num]["state"]
            if st=="CLOSED" and t["status"]=="todo":
                print(f"SKIP {t['id']} #{num} CLOSED but backlog todo -> will skip pick")
        elif t["status"]=="todo" and not num:
            print(f"MISSING {t['id']} todo without issue -> needs gh issue create")
    # check open not in backlog
    bnums={t.get("github_issue_number") for t in data["tasks"] if t.get("github_issue_number")}
    for i in issues:
        if i["state"]=="OPEN" and i["number"] not in bnums:
            print(f"OPEN not in backlog #{i['number']} {i['title'][:60]}")
    if not dry:
        json.dump(data, open(BPATH,"w"), indent=2)
        print(f"synced {BPATH}")
if __name__=="__main__": main()
