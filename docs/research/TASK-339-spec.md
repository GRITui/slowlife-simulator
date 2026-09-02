# TASK-339 — Songkran Cooking Contest (second scored mini-game)

Sprint 3 of the "broaden to compete with HM:BtN" plan (2026-09-02).

## Why this shape, specifically

TASK-330 already balanced festival density to exactly 2 per season
(cool: Loy Krathong + Wan Sart; hot: Songkran + Fishing Competition;
monsoon: Asalha Bucha + Ok Phansa). Adding a brand-new festival day for
a cooking contest would push one season back to 3 and undo that
balancing work. Instead, this task extends `SongkranTrigger.gd`
in-place — exactly the same move TASK-336 made on
`FishingCompetitionTrigger.gd` — reusing Songkran's existing hot-day-3,
12:00-18:00 window rather than adding a new one. This also ties the
36-recipe cooking system into a competitive loop for the first time
(the game's most content-rich, most underused system, per the original
quality verdict).

## Read first

- `scenes/festival/SongkranTrigger.gd` (the file you're editing — read
  it in full; current behavior is flavor-only: fires once per
  hot-season day-3, 12:00-18:00 window, spawns a particle splash, emits
  `festival_triggered("songkran")` + 2 dialogue lines, does nothing
  else).
- `scenes/festival/FishingCompetitionTrigger.gd` — this is the pattern
  to mirror exactly (window-active flag, score accumulator, placement
  helper, window-close resolution). Read it in full before writing
  anything; do not reinvent this shape.
- `scripts/interactables/CookingStation.gd`'s `try_craft()` — on every
  successful craft it does `SignalBus.craft_completed.emit(recipe.id, 1)`.
  **This is the SAME signal `FishingSpot.gd`/`MiningSpot.gd` also emit**
  (fish/ore item_ids), so the scoring handler here must only count
  events whose `item_id` is an actual recipe id — do not use a prefix
  string match like the fishing task did (recipes have no consistent
  id prefix). Load `data/recipes/recipes.json` once and check
  membership + look up `harmony_reward` for the score value (see below).

## Implementation

Add to `SongkranTrigger.gd`:

```gdscript
const RECIPES_PATH: String = "res://data/recipes/recipes.json"
var _recipe_harmony: Dictionary = {} # recipe_id -> harmony_reward, for scoring
var _cook_active: bool = false
var _cook_score: int = 0
```

In `_ready()`, load `data/recipes/recipes.json` (same
`FileAccess.open` + `JSON.parse_string` pattern used elsewhere — see
`CookingStation._load_recipes()` or `FishingSpot._load_roster()` for
the exact shape) and populate `_recipe_harmony[recipe_id] = harmony_reward`
for every entry. Also connect
`SignalBus.craft_completed.connect(_on_craft_completed)` (disconnect in
`_exit_tree()` alongside the existing `minute_ticked` disconnect).

**Scoring handler:**
```gdscript
func _on_craft_completed(item_id: String, qty: int) -> void:
	if not _cook_active or not _recipe_harmony.has(item_id):
		return
	_cook_score += int(_recipe_harmony[item_id]) * qty
```

**Start of window** — in the existing `_on_minute_ticked`, right where
it currently sets `_triggered_keys[key] = true` and emits the two
dialogue lines: also set `_cook_active = true` and `_cook_score = 0`.
Do not change the existing dedupe/particle/dialogue logic above that
point.

**End of window** — same shape as `FishingCompetitionTrigger.gd`'s
`_is_past_window()`/`_resolve_competition()`: add a check at the very
top of `_on_minute_ticked` (before the season/day/hour gate) — if
`_cook_active` and the window has closed (hour >= 18 same day, OR
moved past the day/season entirely), resolve:
- Roll a rival score: `randi_range(4, 14)` (tuned to this contest's
  harmony_reward scale of 3-15 per recipe — winnable with 1-2 solid
  dishes, not trivial).
- Placement: `_player_score > rival_score` → 1st (`GameData.add_silver(30)`,
  `GameData.add_harmony(10)`); `== ` → tie (`add_silver(15)`,
  `add_harmony(5)`); `<` (including 0, if the player cooked nothing) →
  participation (`add_silver(5)`, `add_harmony(2)`). Every tier
  strictly positive — no fail state, matching the fishing contest and
  this project's established precedent.
- Extract the placement logic as its own pure function (e.g.
  `_placement_for(player_score, rival_score) -> String`) exactly like
  `FishingCompetitionTrigger.gd` did — this is what let that task's
  tie tier be tested deterministically without depending on the RNG
  roll; do the same here.
- Emit ONE result dialogue line via `SignalBus.show_dialogue.emit("Elder", ...)`
  naming the placement and both scores, warm tone for every tier (no
  "you lost" — see the fishing contest's dialogue for the exact voice
  to match).
- Set `_cook_active = false`, `_cook_score = 0`.

Do not change `_spawn_splash()` or the particle/dialogue logic at all.

## Tests

New `tests/test_songkran_cooking_contest.gd` (mirror
`tests/test_fishing_competition_scoring.gd`'s structure and coverage
approach exactly — including its documented approach to the
untestable-via-RNG tie tier via the extracted pure placement helper):
- Trigger instanced under `Main`, window opens `_cook_active = true`
  and resets `_cook_score`.
- Cooking 2 recipes during the window (call `_on_craft_completed`
  directly with 2 real recipe ids from `data/recipes/recipes.json`,
  e.g. `"nam_prik"` harmony_reward and one other) sums their
  `harmony_reward` values correctly.
- A `craft_completed` for a FISH or ORE item_id (e.g. `"pla_nin_big"`,
  `"copper_ore"`) during the window does NOT add to `_cook_score` —
  this is the specific cross-signal-reuse bug this task must avoid;
  test it explicitly.
- A craft fired while `_cook_active == false` does not score.
- Window close resolves exactly once (no double payout on a later tick
  at the same hour).
- Every placement tier grants strictly positive silver/harmony (force
  win/participation via `_player_score`, cover tie via the extracted
  pure helper directly, same approach as the fishing contest).

## Constraints

- Do not touch `FishingCompetitionTrigger.gd`, `CookingStation.gd`, or
  any other festival trigger.
- Do not add a new festival day, new `festival_triggered` id, or change
  the existing `"songkran"` dedupe/particle/dialogue-start logic.
- Do not modify `data/recipes/recipes.json`.
- Run `bash scripts/ci/run_gate.sh all` before considering this done;
  must stay green.
- No git/gh actions — stop after code + tests are written and the gate
  is green. Do not commit, push, open a PR, or merge.
