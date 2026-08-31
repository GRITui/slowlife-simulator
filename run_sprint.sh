#!/bin/bash
set -e

# run_sprint.sh — Autonomous sprint loop for slowlife-simulator
# Checks backlog.json for todo items and cycles PO -> Gatekeeper.

if [ ! -f "backlog.json" ]; then
  echo "backlog.json not found"
  exit 1
fi

# Count todo items (requires jq, fallback to python3)
if command -v jq >/dev/null 2>&1; then
  TODO_COUNT=$(jq '[.tasks[] | select(.status=="todo")] | length' backlog.json)
else
  TODO_COUNT=$(python3 -c "import json; print(sum(1 for t in json.load(open('backlog.json'))['tasks'] if t.get('status')=='todo'))")
fi

echo "Found $TODO_COUNT todo item(s) in backlog.json"

if [ "$TODO_COUNT" -eq 0 ]; then
  echo "No todo items — sprint complete."
  exit 0
fi

# Loop through each todo item sequentially
for i in $(seq 1 "$TODO_COUNT"); do
  echo "=== Sprint cycle $i/$TODO_COUNT ==="
  echo "[PO] Processing next task in backlog.json..."
  opencode run --agent po "Process next task in backlog.json"

  echo "[Gatekeeper] Checking open PRs, running godot --headless tests, and merging..."
  opencode run --agent gatekeeper "Check open PRs, run godot --headless tests, and merge"

  if [ "$i" -lt "$TODO_COUNT" ]; then
    echo "Sleeping 3s before next cycle..."
    sleep 3
  fi
done

echo "Sprint complete: $TODO_COUNT cycle(s) finished."
