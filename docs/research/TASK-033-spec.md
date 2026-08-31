# TASK-033 — SignalBus + startup hygiene: orphan emit removal & export pruning

**Status:** `proposed` | **Priority:** high | **Category:** performance | **Owner:** backend-automation
**Files:** `scripts/autoload/SignalBus.gd`, `scenes/core/TimeManager.gd`, `project.godot`, `scripts/autoload/GameStateManager.gd`

## Source: QA-AUDIT-2026-08-31 (verdict FAIL — dead contracts)

- `SignalBus.day_night_cycle_changed` (`TimeManager.gd:69`): emitted **every minute** via `_advance_minute()`, **zero listeners repo-wide** — per-minute orphan emit loop and dead contract.
- `scripts/autoload/GameStateManager.gd` + `scripts/autoload/AudioManager.gd`: defined but **not registered in `project.godot` autoloads** — parsed into the export but never instantiated (startup cost, no function).
- `scripts/core/ProfilerOverlay.gd`, `scripts/resource_types/RecipeData.gd`: production-dead (test-only or unreferenced).

## iOS Core Value rationale (Launch Gate criterion 1 — mobile performance)

- Every script in `res://` is parsed at app startup on device; dead autoload
  candidates and unused scripts add measurable launch time on A-series chips.
- Removing a per-minute signal emit and pruning unregistered scripts trims
  the shipped binary and the main-loop cost.

## Plan

1. Remove `day_night_cycle_changed` signal + emit (or gate behind a listener
   check) — update `tests/run_engine_tests.gd:53` contract list accordingly.
2. Either register `AudioManager`/`GameStateManager` as autoloads (if wired
   by a future task) or move them to `scripts/_dormant/` excluded from
   export presets; document choice in `docs/ios_export_template.md`.
3. Engine-gate section asserting the signal is gone and autoload list
   matches `project.godot`.

## Acceptance

- Engine gate green with updated contract; no orphan emits (`grep -rn
  "day_night_cycle_changed" res://` returns only deletion note);
  startup script count reduced. Content 100/100 + save-compat 14/14 stay green.
