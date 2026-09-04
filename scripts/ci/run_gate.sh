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

run_save_scene_restore() {
	echo "== save-scene-restore gate: tests/test_save_scene_restore.gd =="
	godot --headless --path . --script res://tests/test_save_scene_restore.gd
}

run_perf() {
	echo "== perf-budget gate: tests/perf/test_mobile_budget.gd =="
	godot --headless --path . --script res://tests/perf/test_mobile_budget.gd
}

run_touch() {
	echo "== touch-target gate: tests/ui/test_touch_targets.gd =="
	godot --headless --path . --script res://tests/ui/test_touch_targets.gd
}

run_scene_transitions() {
	echo "== scene-transitions gate: tests/test_scene_transitions.gd =="
	godot --headless --path . --script res://tests/test_scene_transitions.gd
}

run_area_edges() {
	echo "== area-edges gate: tests/test_area_edges.gd =="
	godot --headless --path . --script res://tests/test_area_edges.gd
}

run_farmhouse_content() {
	echo "== farmhouse-content gate: tests/test_farmhouse_content.gd =="
	godot --headless --path . --script res://tests/test_farmhouse_content.gd
}

run_farmhouse_decor() {
	echo "== farmhouse-decor gate: tests/test_farmhouse_decor.gd =="
	godot --headless --path . --script res://tests/test_farmhouse_decor.gd
}

run_transition_fade() {
	echo "== transition-fade gate: tests/test_transition_fade.gd =="
	godot --headless --path . --script res://tests/test_transition_fade.gd
}

run_fish_almanac() {
	# TASK-358 fish almanac — first-catch collection log for the fishing
	# system. Covers GameData.record_catch() idempotency, the live
	# FishingSpot.cast_line() call site that emits the first-catch
	# dialogue, and the HUD AlmanacLabel readout. The save/load
	# round-trip for fish_almanac itself lives in tests/test_save_compat.gd
	# alongside the other milestones_earned-style entries.
	echo "== fish-almanac gate: tests/test_fish_almanac.gd =="
	godot --headless --path . --script res://tests/test_fish_almanac.gd
}

run_carpenter_upgrade() {
	# TASK-322 carpenter house-kitchen upgrade + TASK-362 silver_ore sink.
	# Was an orphaned standalone test (existed since TASK-322, never wired
	# into this gate) — found and fixed 2026-09-04 while merging TASK-362,
	# same category of gap this project has caught before (test_touch_
	# targets.gd was orphaned the same way, see SHIP_PLAN.md Phase 3).
	echo "== carpenter-upgrade gate: tests/test_carpenter_upgrade.gd =="
	godot --headless --path . --script res://tests/test_carpenter_upgrade.gd
}

run_recipe_unlocks() {
	# TASK-363 recipe discovery via villager friendship. Covers
	# GameData.unlock_recipe()/is_recipe_gated() idempotency,
	# CookingStation.get_all_craftable()'s new gating filter, and the
	# add_affinity() level-crossing unlock hook. The save/load round-trip
	# for recipe_unlocks itself lives in tests/test_save_compat.gd
	# alongside the other milestones_earned-style entries.
	echo "== recipe-unlocks gate: tests/test_recipe_unlocks.gd =="
	godot --headless --path . --script res://tests/test_recipe_unlocks.gd
}

run_particle_drivers() {
	# TASK-366 — RainDriver/HeatHazeDriver were complete, correct scripts
	# that were never actually instanced as nodes in World.tscn (a real
	# bug: the effects never ran in any real session despite passing
	# review). This test instances the real World.tscn, not just the
	# driver script in isolation, specifically so the same class of bug
	# (script correct, node missing) fails loudly here in the future.
	# Also covers the new always-on LeafDriver ambiance.
	echo "== particle-drivers gate: tests/test_particle_drivers.gd =="
	godot --headless --path . --script res://tests/test_particle_drivers.gd
}

run_fog_driver() {
	# TASK-365 fog weather VFX. Bus-only driver script toggles a sibling
	# ColorRect's visible state on SignalBus.weather_changed ("fog" ->
	# visible, anything else -> hidden). Same shape as RainDriver /
	# HeatHazeDriver / DayNightTintDriver; this gate is the first test
	# to assert the full wiring path (script + sibling nodes present in
	# World.tscn + signal-driven toggle actually fires) — guards against
	# the TASK-366 orphan-script class where the .gd exists but no node
	# in the scene tree references it.
	echo "== fog-driver gate: tests/test_fog_driver.gd =="
	godot --headless --path . --script res://tests/test_fog_driver.gd
}

run_dialogue_portrait() {
	# TASK-376. World.gd's dialogue_portrait display logic was always
	# correct, but no "Portrait" node ever existed under
	# DialogueLayer/Panel in World.tscn — same orphan-wiring class as
	# TASK-366/369/373 (script/logic correct, scene node missing). This
	# instances the real World.tscn and drives SignalBus.show_dialogue
	# to confirm the portrait actually shows/hides for real speakers.
	echo "== dialogue-portrait gate: tests/test_dialogue_portrait.gd =="
	godot --headless --path . --script res://tests/test_dialogue_portrait.gd
}

run_farmhouse_furniture() {
	# TASK-374 Phase 1: floor_rug placement, FarmHouse-only, no rotation.
	# Instances the real FarmHouse.tscn (not a mock) and drives the real
	# toggle_furniture_place_mode/interact input actions.
	echo "== farmhouse-furniture gate: tests/test_farmhouse_furniture.gd =="
	godot --headless --path . --script res://tests/test_farmhouse_furniture.gd
}

run_schedules() {
	# TASK-058 schedule waypoint lookup + NPC placement, extended in
	# TASK-379 with a regression guard asserting every SCHEDULES waypoint
	# for every npc_id lands on a non-water tile (found and fixed real,
	# pre-existing bugs for elder/child/handler/headman/fah this way —
	# same orphan-TEST-file class as test_carpenter_upgrade.gd/
	# test_touch_targets.gd before it: this file existed on disk but was
	# never actually wired into this gate).
	echo "== schedules gate: tests/test_schedules.gd =="
	godot --headless --path . --script res://tests/test_schedules.gd
}

run_festival_visual_driver() {
	# TASK-369 — FestivalVisualDriver's PondGlow/FestivalLanterns were
	# complete, correct scripts never instanced as nodes in World.tscn.
	# Same orphan-wiring class as TASK-366; this gate instances the real
	# World.tscn and drives SignalBus.festival_triggered to confirm the
	# effects actually toggle.
	echo "== festival-visual-driver gate: tests/test_festival_visual_driver.gd =="
	godot --headless --path . --script res://tests/test_festival_visual_driver.gd
}

run_completion_tracker() {
	# TASK-378 unified completion tracker (perfection % / checklist screen).
	# Pure aggregation over already-shipped data. Covers the percentage
	# formula, the UI screen's open()/close(), and HUD button wiring.
	echo "== completion-tracker gate: tests/test_completion_tracker.gd =="
	godot --headless --path . --script res://tests/test_completion_tracker.gd
}

case "$GATE" in
	engine) run_engine ;;
	content) run_content ;;
	save) run_save_compat ;;
	save_restore) run_save_scene_restore ;;
	perf) run_perf ;;
	touch) run_touch ;;
	scenes) run_scene_transitions ;;
	area_edges) run_area_edges ;;
	farmhouse_content) run_farmhouse_content ;;
	farmhouse_decor) run_farmhouse_decor ;;
	transition_fade) run_transition_fade ;;
	fish_almanac) run_fish_almanac ;;
	carpenter_upgrade) run_carpenter_upgrade ;;
	recipe_unlocks) run_recipe_unlocks ;;
	particle_drivers) run_particle_drivers ;;
	fog_driver) run_fog_driver ;;
	dialogue_portrait) run_dialogue_portrait ;;
	farmhouse_furniture) run_farmhouse_furniture ;;
	schedules) run_schedules ;;
	festival_visual_driver) run_festival_visual_driver ;;
	completion_tracker) run_completion_tracker ;;
	all) run_engine && run_content && run_save_compat && run_save_scene_restore && run_perf && run_touch && run_scene_transitions && run_area_edges && run_farmhouse_content && run_farmhouse_decor && run_transition_fade && run_fish_almanac && run_carpenter_upgrade && run_recipe_unlocks && run_particle_drivers && run_fog_driver && run_dialogue_portrait && run_farmhouse_furniture && run_schedules && run_festival_visual_driver && run_completion_tracker ;;
	*) echo "unknown gate '$GATE' (want: engine|content|save|save_restore|perf|touch|scenes|area_edges|farmhouse_content|farmhouse_decor|transition_fade|fish_almanac|carpenter_upgrade|recipe_unlocks|particle_drivers|fog_driver|dialogue_portrait|farmhouse_furniture|schedules|festival_visual_driver|completion_tracker|all)" >&2; exit 2 ;;
esac
