# TASK-336 — Real scored Fishing Competition (first competitive mini-game)

Sprint 1 of the "broaden to compete with HM:BtN" plan (2026-09-02).

## Why

Confirmed via code audit (grep for score/placement/leaderboard/rank
across the whole codebase — zero hits): no scored competition exists
anywhere. `BuffaloRace.gd` is a solo time-trial against a fixed
threshold, not a competition against anyone. `FishingCompetitionTrigger.gd`
is pure flavor — it fires a dialogue line and does nothing else; a catch
during the window is mechanically identical to any other catch.

This is the first real "compete and win" loop in the game. **Zero fail
state, per this project's established precedent**: losing costs nothing
and grants a real (if smaller) reward — never a zero or negative
outcome, never an item taken away.

## Read first

- `scenes/festival/FishingCompetitionTrigger.gd` (the file you're
  editing — read it in full, current behavior is: fires once per
  hot-season day-15, 10:00-16:00 window, requires `fishing_skill >= 2`,
  emits `festival_triggered("fishing_competition")` + one dialogue
  line, and does nothing else).
- `scripts/interactables/FishingSpot.gd`'s `cast_line()` — on every
  successful catch it does `SignalBus.craft_completed.emit(item, 1)`
  where `item` is the fish's item_id (e.g. `"pla_nin_big"`,
  `"pla_soi_mid"`, `"pla_chon_small"` — always `<species>_<size>`,
  size is always exactly `"_small"`, `"_mid"`, or `"_big"`).
- `data/fish/fish.json` — confirms the `_small`/`_mid`/`_big` suffix
  convention (do not need to read this file at runtime; the suffix
  string match is sufficient).

## Implementation

Add to `FishingCompetitionTrigger.gd`:

```gdscript
var _competition_active: bool = false
var _player_score: int = 0
```

In `_ready()`, additionally connect `SignalBus.craft_completed.connect(_on_craft_completed)`
(unsubscribe in `_exit_tree()` alongside the existing `minute_ticked`
disconnect).

**Scoring handler** (only counts fish caught while the competition is
active — most catches happen outside the window and must not count):
```gdscript
func _on_craft_completed(item_id: String, qty: int) -> void:
	if not _competition_active or not item_id.begins_with("pla_"):
		return
	var points: int = 1
	if item_id.ends_with("_big"):
		points = 3
	elif item_id.ends_with("_mid"):
		points = 2
	_player_score += points * qty
```

**Start of window** — in the existing `_on_minute_ticked`, right where
it currently does `_triggered_keys[key] = true` / emits the "come cast
your line" dialogue: also set `_competition_active = true` and
`_player_score = 0`. Do not change the existing skill-gate or dedupe
logic above that point.

**End of window** — add a check at the very top of `_on_minute_ticked`
(before the existing season/day/hour gate, so it still runs even once
the window's own condition would otherwise `return` early): if
`_competition_active` and (hour >= 16 for the same day, OR the day/
season has moved past the window entirely — handle both so a save/load
or a day skip doesn't leave the competition stuck open forever), resolve
it:
- Roll a rival score: `randi_range(2, 8)`.
- Determine placement:
  - `_player_score > rival_score` → **1st place**: `GameData.add_silver(30)`, `GameData.add_harmony(10)`.
  - `_player_score == rival_score` → **2nd place / tie**: `GameData.add_silver(15)`, `GameData.add_harmony(5)`.
  - `_player_score < rival_score` (including a `_player_score` of 0 — the player never entered, or caught nothing) → **participation**: `GameData.add_silver(5)`, `GameData.add_harmony(2)`.
- Emit ONE result dialogue line via `SignalBus.show_dialogue.emit("Fah", ...)` naming the placement and both scores (e.g. `"Competition's over — you: 7, the field: 5. First place! (+30 silver, +10 harmony)"`), phrased warmly for every tier (no "you lost," no discouraging language — cozy tone even for participation, matching this project's voice elsewhere).
- Set `_competition_active = false`.

Keep the existing pre-competition skill-gate dialogue ("Come back when
you've practiced more") completely unchanged — that's the entry
requirement, unrelated to this scoring addition.

## Tests

New `tests/test_fishing_competition_scoring.gd` (SceneTree pattern,
mirror `tests/test_new_monsoon_festivals.gd`'s house style):
- Trigger instanced under `Main`, skill gate unchanged (skill < 2 still
  blocks entry with the existing dialogue, no scoring state starts).
- Entering the window with skill >= 2 sets `_competition_active = true`
  and resets `_player_score` to 0.
- Simulate 3 catches during the window (`_on_craft_completed("pla_nin_big", 1)`,
  `_on_craft_completed("pla_nin_mid", 1)`, `_on_craft_completed("pla_nin_small", 1)`)
  → `_player_score == 6` (3+2+1).
- A catch fired while `_competition_active == false` (before the window
  opens, or after it resolves) does NOT add to `_player_score`.
- A non-fish `craft_completed` (e.g. `"rice_grain"`) does not add to
  `_player_score` even while active.
- Force a placement scenario for each of the 3 tiers (mock/override the
  rival roll if needed — e.g. by setting `_player_score` very high for
  a guaranteed win, or very low/0 for a guaranteed participation tier;
  a tie is harder to force deterministically with `randi_range`, so
  either test it via direct unit-level math on the placement logic
  extracted as a small pure function, or accept covering only the win/
  participation tiers if a clean tie-force isn't feasible — use your
  judgment, note which approach you took in a comment) — each grants
  `silver`/`harmony` > 0, confirming the no-fail-state guarantee (every
  tier's reward is strictly positive).
- Window closing resolves the competition exactly once (no double
  payout if `_on_minute_ticked` fires again at the same hour — reuse
  the existing `_triggered_keys` dedupe concept if it helps, or add a
  small "already resolved this year" guard of your own).

## Constraints

- Do not touch `BuffaloRace.gd`, `FishingSpot.gd`, or any other
  festival trigger.
- Do not change the pre-existing skill-gate, dedupe-key, or
  `festival_triggered` emission logic — additive only.
- Run `bash scripts/ci/run_gate.sh all` before considering this done;
  must stay green.
- No git/gh actions — stop after code + tests are written and the gate
  is green. Do not commit, push, open a PR, or merge.
