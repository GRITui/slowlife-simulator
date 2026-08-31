# TASK-026 — Save Compatibility & Migration Tests (Engine/Quality)

**Status:** `proposed` | **Priority:** high | **Category:** ci | **Owner:** data-persistence
**Files:** `tests/test_save_compat.gd`, `scripts/persistence/SaveManager.gd`, `tests/run_tests.gd`, `scripts/ci/run_gate.sh`

## @qa-auditor Findings
- `SaveManager.gd:4` `save_game()` writes `user://savegame.json` v1 (`player_pos`, `inventory`, `harmony`, `season`) but no schema version, no migration, no headless test coverage for round-trip.
- `tests/run_tests.gd:29` covers `GameData` inventory/harmony but not `SaveManager` serialization; `run_engine_tests.gd` has `NavGrid` but no persistence.
- Previous `ENGINE-003` landed SaveManager without `TypedDictionary` versioning — risk on future `TASK-022` `krathong`/`festival` fields or `buffalo_milk`.
- `gdlint` not in CI (`scripts/ci/run_gate.sh:1` only runs `godot --import` + `run_tests`); static typing gaps not caught.

## Plan
- Add `const SAVE_VERSION: int = 2` to `SaveManager`, include `version` in JSON, `func migrate(data:Dictionary) -> Dictionary` (v1→v2 adds `krathong` default 0, `version` field).
- New `tests/test_save_compat.gd` (headless `SceneTree`): `test_round_trip`, `test_migrate_v1`, `test_inventory_int_coercion` (covers `ENGINE-003` float-int bug).
- Update `scripts/ci/run_gate.sh` to run `gdlint` (if installed) before `godot` imports; add `tests/test_save_compat.gd` to `run_tests.gd` or standalone gate.

## Acceptance
- `SaveManager.save_game()` writes versioned JSON, `load_game()` migrates v1→v2, inventory ints coerced.
- `godot --headless --script res://tests/test_save_compat.gd` green; existing `54/54` + `50/50` still green; `gdlint` clean.

## Risk
- Low — additive, no breaking change to `GameData` API; migration keeps old saves loadable.
