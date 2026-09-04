#!/usr/bin/env bash
# stress_gate.sh — run scripts/ci/run_gate.sh all N times, print each
# run's TESTS: lines, stop early on first failure. Replaces the
# `for i in 1 2 3; do bash scripts/ci/run_gate.sh all ...; done` loop
# that's been hand-typed 5+ times this session for every merge.
#
# Usage: scripts/ci/stress_gate.sh [N]   (default N=3)

set -u
N="${1:-3}"

for i in $(seq 1 "$N"); do
  echo "=== stress_gate run $i/$N ==="
  OUTPUT="$(bash scripts/ci/run_gate.sh all 2>&1)"
  EXIT_CODE=$?
  echo "$OUTPUT" | grep -E "TESTS:|FAIL"
  if [ "$EXIT_CODE" -ne 0 ]; then
    echo "=== stress_gate: run $i FAILED (exit $EXIT_CODE) — stopping early ==="
    exit 1
  fi
done
echo "=== stress_gate: all $N runs green ==="
