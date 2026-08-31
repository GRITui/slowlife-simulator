#!/usr/bin/env bash
set -euo pipefail
REPO="GRITui/slowlife-simulator"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
git fetch origin main
git checkout main
git pull --ff-only origin main
gh -R "$REPO" issue list --state open --limit 100 --json number,title,state,url,labels > /tmp/open_issues.json
python3 ops/sync_backlog_issues.py --dry-run
echo "--- ART pending (issue OPEN) ---"
python3 -c "import json;b=json.load(open('backlog.json'));o=set(x['number'] for x in json.load(open('/tmp/open_issues.json')));[print(f\"ART {t['id']} #{t['github_issue_number']} {t['title'][:50]}\") for t in b['tasks'] if t['status']=='todo' and t.get('github_issue_number') in o and t['category'] in ('ui','gameplay')]"
