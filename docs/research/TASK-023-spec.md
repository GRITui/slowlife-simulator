# TASK-023 — SignalBus Legacy Cleanup + Static Typing Hardening (Architectural)

**Status:** `todo` | **Priority:** high | **Category:** architecture | **Owner:** backend-automation
**Files:** `scripts/autoload/SignalBus.gd`, `src/scripts/signalbus.gd`, `scripts/autoload/GameData.gd`, `scripts/autoload/AudioManager.gd`, `scenes/ui/HUD.gd`, `scenes/entities/*`, `tests/run_tests.gd`

## Audit Findings (@qa-auditor)
- `SignalBus.gd:15` duplicate legacy signals: `energy_changed` (never emitted, HUD uses `stamina_changed`), `ui_update_*` (4), `buffalo_fed`, `temple_offering_made`, `festival_triggered` (new) — inconsistent naming.
- `SignalBus.gd:7` `energy_changed` vs `stamina_changed` duplication; `village_harmony_changed` + `village_goodwill_changed` both emitted from `GameData.add_harmony:53` (redundant).
- `GameData.gd:18` `inventory: Dictionary` untyped values; `infrastructure: Dictionary` untyped; no `TypedDictionary` hardening.
- `src/scripts/signalbus.gd:1` is deprecated shim (ENGINE-007) but still `extends Node` with full signal duplication — should be re-export or removed, currently 2 lines only but still loaded.

## Required Changes
- Canonicalize `SignalBus.gd`: keep `minute_ticked`, `season_changed`, `weather_changed`, `stamina_changed`, `binthabat_offered`, `infrastructure_repaired`, `show_dialogue`, `crop_growth_progress`, `crop_harvested`, `day_night_cycle_changed`, `village_harmony_changed`, `festival_triggered`; deprecate `energy_changed` + `ui_update_*` with `@deprecated` comment and not emitted.
- `GameData.gd`: add explicit types `var inventory: Dictionary[String,int]`, `var infrastructure: Dictionary[String,bool]` (Godot 4.4 TypedDictionary) or keep `Dictionary` with typed getters `func get_inventory_item(id:String) -> int` to satisfy `gdlint`.
- `src/scripts/signalbus.gd`: replace with single line `extends "res://scripts/autoload/SignalBus.gd"` or delete and update any legacy `src/` imports (audit `project.godot` autoload already points to canonical).
- Update `tests/run_tests.gd:29` signal list to match canonical (remove `energy_changed`).

## Verification
- `gdlint res/` clean (no untyped `var` warnings) after hardening.
- `godot --headless --path . --script res://tests/run_tests.gd` 54/54 + `run_engine_tests.gd` 50/50 still green — SignalBus contract unchanged for consumers (`HUD`, `GridManager`, `Player`, `MonkNPC`).

## Risk
- Low: only deprecation, no behavioral change. Must keep backward-compat emits for `village_goodwill_changed` until next minor.
