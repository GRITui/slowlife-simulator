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
# TASK-026: gdlint advisory pass (style only, non-fatal) — strict typing
# errors are caught by the Godot parser below; gdlint adds naming/spacing
# lint. Install with: pip install gdtoolkit
if command -v gdlint >/dev/null 2>&1; then
	echo "== gdlint pass (advisory) =="
	gdlint scripts/ scenes/ tests/ || echo "gdlint reported style issues (non-fatal)"
else
	echo "== gdlint not installed, skipping (pip install gdtoolkit) =="
fi
godot --headless --import --path . >/dev/null

run_content() {
	echo "== content gate: tests/run_tests.gd =="
	godot --headless --path . --script res://tests/run_tests.gd
}

run_engine() {
	echo "== engine gate: tests/run_engine_tests.gd =="
	godot --headless --path . --script res://tests/run_engine_tests.gd
}

run_save_compat() {
	echo "== save-compat gate: tests/test_save_compat.gd =="
	godot --headless --path . --script res://tests/test_save_compat.gd
}

run_perf() {
	echo "== perf-budget gate: tests/perf/test_mobile_budget.gd =="
	godot --headless --path . --script res://tests/perf/test_mobile_budget.gd
}

case "$GATE" in
	engine) run_engine ;;
	content) run_content ;;
	save) run_save_compat ;;
	perf) run_perf ;;
	all) run_engine && run_content && run_save_compat && run_perf ;;
	*) echo "unknown gate '$GATE' (want: engine|content|save|perf|all)" >&2; exit 2 ;;
esac
