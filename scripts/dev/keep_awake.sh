#!/usr/bin/env bash
# keep_awake.sh — prevent display sleep / screensaver-triggered lock
# during a manual playtest session. Synthetic game input sent to a
# running Godot instance (via DebugInputDriver.gd or similar) does NOT
# count as real user activity to macOS, so a long automated playtest
# session can silently hit the screensaver -> lock screen, killing all
# screenshot-based visual verification until a human unlocks the Mac.
# Hit this for real during a 2026-09-04 playtest session.
#
# Usage: scripts/dev/keep_awake.sh [hours]   (default 4)

set -u
HOURS="${1:-4}"
SECONDS_TOTAL=$((HOURS * 3600))

nohup caffeinate -d -i -t "$SECONDS_TOTAL" > /dev/null 2>&1 &
disown
echo "keep_awake: display+idle sleep prevented for ${HOURS}h (PID $!)"
