# TASK-330 — Festival density expansion (2 new monsoon festivals)

Sprint 2 of the "3 sprints, complete pending backlog" run (2026-09-02).

## Scope note (read before implementing)

Confirmed via code audit: exactly 4 festival triggers exist today —
`LoyKrathong` (cool, via `FestivalManager.gd`), `WanSartTrigger.gd` (cool),
`SongkranTrigger.gd` (hot), `FishingCompetitionTrigger.gd` (hot). **Zero
monsoon-season festivals exist.** This task adds exactly two, to balance
density to 2 festivals per season.

Both new festivals are **flavor-only** (dialogue + `SignalBus.festival_triggered`
emit) — mirror `SongkranTrigger.gd`'s shape exactly, MINUS the particle
spawn (skip `_spawn_splash()` — no new particle asset is in scope here).
Do NOT add new items, new recipes, or a craft/release mechanic — that
would be a different, larger task (see `WanSartTrigger.gd`'s craft-based
shape for contrast; that is NOT the pattern to copy here).

## Files to create

1. `scenes/festival/AsalhaBuchaTrigger.gd` — Asalha Puja / "Wan Asanha
   Bucha" (candle procession marking the start of Buddhist Lent).
   - `@export var festival_day: int = 5` (early monsoon)
   - Fires when `season == "monsoon"` and `day_of_season() == festival_day`,
     hour window 17-21 (evening candle procession)
   - `SignalBus.festival_triggered.emit("asalha_bucha")`
   - Dialogue via `SignalBus.show_dialogue.emit(...)`, 2 lines from
     different speakers (Elder + Monk, or Elder + Handler — your choice),
     matching the game's established cozy/Buddhist-merit tone (see
     `DialogueDB.gd`'s `"monk"` entries for voice reference — do not
     invent English words like "Lent" in the dialogue text itself, prefer
     "the rains retreat begins" or similar; "Asalha Bucha" as a proper
     noun is fine to say aloud)

2. `scenes/festival/OkPhansaTrigger.gd` — Ok Phansa (end of the rains
   retreat, illuminated boats / candlelit canal procession — thematically
   distinct from Loy Krathong's floating krathong, this is about light on
   the water, not offerings released).
   - `@export var festival_day: int = 28` (late monsoon, near season end)
   - Same shape as above: hour window 18-22, `festival_triggered.emit("ok_phansa")`,
     2 dialogue lines.

Both scripts follow `SongkranTrigger.gd`'s exact structural pattern:
`extends Node`, `add_to_group("festival_manager")`, subscribe to
`SignalBus.minute_ticked` in `_ready()`, unsubscribe in `_exit_tree()`,
year-season dedupe key (`"%d-%s" % [year, season]` via a local
`_triggered_keys: Dictionary`) so it fires once per season per year, not
once per minute in the window.

## Wiring

Exact pattern confirmed in `scenes/core/Main.gd` — `_ensure_songkran()`
(around line 289) and `_ensure_wansart()` (around line 192):

```gdscript
func _ensure_asalha_bucha() -> void:
	if get_node_or_null("AsalhaBuchaTrigger") != null:
		return
	var script: GDScript = load("res://scenes/festival/AsalhaBuchaTrigger.gd")
	if script == null:
		return
	var trigger: Node = script.new()
	trigger.name = "AsalhaBuchaTrigger"
	add_child(trigger)
```

(same shape for `_ensure_ok_phansa()` / `OkPhansaTrigger.gd`). Add both
calls inside `Main._ready()` alongside the existing
`_ensure_songkran()` / `_ensure_fishing_competition()` calls (around
line 61-63) — do not reorder or remove any existing `_ensure_*` call.

## Tests

New `tests/test_new_monsoon_festivals.gd` (SceneTree pattern, see
`tests/test_schedules.gd` or any `tests/test_*.gd` for the house style):
- Both triggers exist under `Main` after boot.
- Setting season to "monsoon" and day/hour to each trigger's window fires
  `festival_triggered` with the correct id, exactly once (a second
  `minute_ticked` call in the same window does not re-fire).
- Outside the season/day/hour window, neither fires.

## Constraints

- Do NOT touch `FestivalManager.gd`, `WanSartTrigger.gd`,
  `SongkranTrigger.gd`, `FishingCompetitionTrigger.gd`, or any existing
  festival's dedupe/day/mechanic — this task is purely additive.
- Do NOT modify `data/recipes/recipes.json`, `GameData.gd`'s item lists,
  or add any new consumable item — flavor-only, no new economy surface.
- Run `bash scripts/ci/run_gate.sh all` before considering this done;
  it must stay green (was: content 100/100, engine 50/50, save-compat
  35/35, perf 6/6, touch 10/10 before this change).
- No git/gh actions — stop after code + tests are written and the gate
  is green. Do not commit, push, open a PR, or merge.
