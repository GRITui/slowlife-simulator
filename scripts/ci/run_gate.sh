#!/usr/bin/env bash
# CI gate runner (@backend-automation). Wraps both test suites with the
# mandatory asset-import pass — .godot/imported/ is gitignored, so a fresh
# clone or CI runner has no .ctex cache for any asset committed after the
# last import. Without this, headless `load()` on newer textures (e.g.
# TASK-006 tall art) silently returns null, and callers that don't guard
# against that (WorldRender.gd's sprite builders) throw non-fatal script
# errors and can fail assertions that count built children.
#
# Usage: scripts/ci/run_gate.sh [engine|content|all]   (default: all)

set -euo pipefail
cd "$(dirname "$0")/../.."

GATE="${1:-all}"

echo "== import pass =="
godot --headless --import --path . >/dev/null

run_content() {
	echo "== content gate: tests/run_tests.gd =="
	godot --headless --path . --script res://tests/run_tests.gd
}

run_engine() {
	echo "== engine gate: tests/run_engine_tests.gd =="
	godot --headless --path . --script res://tests/run_engine_tests.gd
}

case "$GATE" in
	engine) run_engine ;;
	content) run_content ;;
	all) run_engine && run_content ;;
	*) echo "unknown gate '$GATE' (want: engine|content|all)" >&2; exit 2 ;;
esac
