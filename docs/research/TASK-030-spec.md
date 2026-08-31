# TASK-030 — Wire FestivalManager into Main + pond krathong interactable (Bugfix/Dead code)

**Status:** `proposed` | **Priority:** medium | **Category:** gameplay | **Owner:** narrative-lead
**Files:** `scenes/core/Main.tscn`, `scenes/festival/FestivalManager.gd`, `scenes/festival/Krathong.tscn`

## @qa-auditor Findings (unhandled-signal / dead-code audit)
- `scenes/festival/FestivalManager.gd` (TASK-022, PR #75) is **never instantiated** — `grep FestivalManager scenes/` finds only the file itself; `SignalBus.festival_triggered` has zero listeners; `try_trigger_festival()` is never called by `TimeManager` or `Main`.
- Net effect: festival mechanic is dead code; `craft_krathong()`/`release_krathong()` unreachable in-game.
- `TimeManager._advance_minute()` already emits `minute_ticked(day, hour, minute)` — the natural trigger point (cool season, day 7).

## Plan
- Instance `FestivalManager` under `Main.tscn`; connect its trigger to `SignalBus.minute_ticked` inside the manager (bus-decoupled, no direct TimeManager reference — use the `SignalBus.time_manager` registry per ENGINE-006).
- Add `Krathong.tscn` (Sprite2D `lotus_pond.png` tint + Area2D, radius 48) — release interaction at pond cell `(2,1)` calls `release_krathong()` (+5 harmony, consumes item).
- Content-gate section: instantiate Main headlessly, force `TimeManager.set_season("cool") + set_time(7, 19, 0)`, assert `festival_triggered` fires once and krathong release path works.

## Acceptance
- Festival triggers exactly once per cool-season day 7 in-engine; `festival_triggered` has ≥1 live listener; gates green.

## Risk
- Low — wiring-only; mechanic logic already merged and typed.
