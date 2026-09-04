#!/usr/bin/env bash
# dispatch_cline.sh — auto-retrying Cline dispatch across the free-model
# fallback chain documented in CLAUDE.md. Replaces the manual "read the
# log, spot a 429/5xx, re-run with the next model by hand" loop that's
# been done by hand repeatedly across this project's sprints (TASK-360
# hit this 3x in one dispatch, TASK-363 hit it again the next task).
#
# Usage: scripts/ci/dispatch_cline.sh <worktree-dir> <prompt-file> <log-file>
#
# Tries each model in MODELS in order. After each attempt, greps the log
# for the known failure signatures from CLAUDE.md's own documented
# incidents (rate limit, provider 5xx/overload, delisted model "no
# endpoints found", and the hook-dispatch-failed wrapper error that
# always accompanies a real provider failure in this project's Cline
# version) and moves to the next model if any match. Stops as soon as a
# run completes WITHOUT hitting one of those signatures (regardless of
# whether the task itself succeeded — a clean run that produced a bug is
# still a real Code Quality Review job, not a dispatch-infra retry).
#
# Does NOT replace judgment: this only automates the mechanical
# "which model do I try next" loop. Reviewing the diff, running the
# gate, and deciding whether the actual work is correct is still a
# human/Claude job after this script exits.

set -u

WORKTREE="$1"
PROMPT_FILE="$2"
LOG_FILE="$3"

# Ordered fallback chain — mirrors CLAUDE.md's "long-running refactors"
# chain (the closest match to typical dispatch task size). Re-verify
# against CLAUDE.md periodically; this roster rotates.
MODELS=(
  "minimax/minimax-m3:free"
  "nvidia/nemotron-3-ultra-550b-a55b:free"
  "poolside/laguna-xs-2.1:free"
  "cohere/north-mini-code:free"
)

# "hook dispatch failed" is Cline's own wrapper-level error that has
# preceded every single provider failure observed this session (429
# rate limit, 5xx overload, a delisted model, an idle timeout) --
# verified by grepping all 4 real failure logs from this session, 4/4
# hit. Simpler and more robust than enumerating specific downstream
# error strings, which already missed a real failure once (the idle
# timeout case) before this consolidation.
FAILURE_PATTERN='hook dispatch failed'

PROMPT_CONTENT="$(cat "$PROMPT_FILE")"

for MODEL in "${MODELS[@]}"; do
  echo "=== dispatch_cline: trying $MODEL ===" | tee -a "$LOG_FILE"
  ( cd "$WORKTREE" && cline -P cline -m "$MODEL" --thinking low "$PROMPT_CONTENT" ) >> "$LOG_FILE" 2>&1
  if grep -qE "$FAILURE_PATTERN" "$LOG_FILE"; then
    echo "=== dispatch_cline: $MODEL hit a known provider failure, trying next model ===" | tee -a "$LOG_FILE"
    continue
  fi
  echo "=== dispatch_cline: $MODEL completed without a provider-failure signature (review its actual output/diff before trusting it) ===" | tee -a "$LOG_FILE"
  exit 0
done

echo "=== dispatch_cline: every model in the chain hit a provider failure — stopping, do not retry blindly ===" | tee -a "$LOG_FILE"
exit 1
