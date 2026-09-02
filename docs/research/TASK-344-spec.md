# TASK-344 — Sprint 5: final 2 unlockable areas (Lotus Maze Shore, Coastal Trading Post)

Sprint 5 (final sprint) of the "6 romance + 6 rivals + 5 unlockable
areas" plan. Brings the unlockable-area count from 3 to 5 (Mountain
Cave + Deep Canal Bend + Sacred Grove + these 2). Same constraints as
TASK-337/343 throughout: no map/grid expansion, no new items, no new
persisted field, verified-clear positions.

## Area 4: Lotus Maze Shore (fishing variant, ties into existing flavor lore)

The 3×3 lotus maze (`GridManager.maze_origin = Vector2i(14, 10)`) is
entirely `deep_pond` — NOT walkable. Do not attempt to place anything
inside it. Instead, place a fishing variant at its walkable EDGE,
mirroring how `FishingSpot.gd`'s own `_water_adjacent()` check already
works (adjacent-to-water, not standing in it).

- New file `scripts/interactables/LotusMazeShoreSpot.gd`, mirroring
  `FishingSpot.gd`'s pattern (same as `DeepCanalSpot.gd` from
  TASK-343 — if that task landed first, this is the SAME shape a
  second time; factor out shared logic only if it's trivial to do
  without touching `FishingSpot.gd` itself, otherwise duplication
  between two small spot files is fine and matches this project's
  existing style of small self-contained interactables).
- Gate: `GameData.milestones_earned.size() >= 5` — all 5 existing
  milestones from TASK-331 (`deep_miner`, `master_angler`,
  `inseparable`, `herd_keeper`, `storm_catch`) earned. This is the
  "completionist" unlock — a capstone for players who've engaged with
  every system, not just one skill.
- Reuses `data/fish/fish.json` verbatim, rarity weights biased toward
  `legendary` even harder than `DeepCanalSpot.gd` (this is the
  "ultimate" fishing spot). Ties into existing flavor text —
  `DialogueDB.gd`'s elder `"fishing_hint"` pool already references
  "a giant in the deep canal bend" and "something flashes every color
  in the sun near the lotus maze" — this spot is the mechanical payoff
  for lore that's been sitting unused since TASK-050. Consider (not
  required) a special one-line dialogue flavor referencing this when
  a legendary catch happens here specifically, distinct from the
  standard catch line.
- Position: `Vector2(13 * 48 + 24, 11 * 48)` — verified via a headless
  `ground_at()` probe: tile `(13,11)` is `plantable_soil` (walkable),
  its east neighbor `(14,11)` is `deep_pond` (inside the maze),
  satisfying water-adjacency. Clear of every other node's position.

## Area 5: Coastal Trading Post (economy variant, not a resource-gather spot)

Deliberately different in kind from every other unlockable area so
far — not a gather spot, a better SELLING option. Reuses
`GameData.get_sell_price()`/`sell_item_premium()` verbatim (both
already support an arbitrary `channel` string via `match` — read
`GameData.gd` lines ~299-320 before writing anything, this is simpler
than it sounds).

- `GameData.get_sell_price()`: add one more `match` case,
  `"coastal": return int(ceil(base * 1.25))` — between the existing
  `"market"` (+15%) and `"specialty"` (+45%) tiers. This is the ONLY
  change to `GameData.gd` in this task.
- New helper `GameData.priciest_sellable() -> String`, mirroring the
  existing `cheapest_sellable()` exactly (same loop shape, inverted
  comparison — `price > best_price` instead of `<`).
- New file `scripts/interactables/CoastalTradingPost.gd` — NOT a
  gather spot, no roster, no dig/cast mechanic. On interact, sells the
  single most valuable currently-held sellable item
  (`GameData.priciest_sellable()`) via
  `GameData.sell_item_premium(item, "coastal")`, mirroring
  `TraderNPC`'s `_try_trader_sell()` simplicity (one item per interact,
  no new UI) but inverted (priciest, not cheapest) and at the better
  rate. Soft-fail dialogue if nothing sellable is held.
- Gate: `GameData.lifetime_items_shipped >= 200` — the same threshold
  as the top `stamina_tier` (TASK-326), framing this as "you ship
  enough that the coastal traders come looking for you," not a new
  arbitrary number.
- Position: `Vector2(16 * 48 + 24, 6 * 48)` — verified via a headless
  `ground_at()` probe: tile `(16,6)` is `plantable_soil`, near the
  existing `TraderNPC`/market cluster. Clear of every other node's
  position (re-verify against the current list, which has grown across
  TASK-341/342/343).

## Unlock wiring

Both spots follow the exact `_ensure_mountain_cave()`/
`_on_minute_ticked_unlocks()` pattern from TASK-337 — add both checks
into the SAME existing `_on_minute_ticked_unlocks()` handler in
`Main.gd`, do not create additional `minute_ticked` subscriptions.

## Tests

New `tests/test_lotus_maze_shore.gd` (mirror `tests/test_mountain_cave.gd`'s
structure — gate/unlock/real-Area2D/roster-parity/statistical rarity
check, same shape as `DeepCanalSpot`) and `tests/test_coastal_trading_post.gd`
(gate/unlock/real-Area2D, PLUS: sells the priciest held item not the
cheapest — construct an inventory with 2+ sellable items of different
value and confirm the higher-priced one is chosen and sold at the
`"coastal"` rate specifically, i.e. `price == ceil(base * 1.25)`, not
the base/market/specialty rate; soft-fail with zero mutation when
nothing sellable is held).

## Constraints

- Do not touch `GridManager.gd`, `WorldRender.gd`, `FishingSpot.gd`,
  `TraderNPC.gd`, `fish.json`, or `SELL_PRICES`.
- Do not add any new persisted `GameData` field — both gates read
  already-persisted stats (`milestones_earned`, `lifetime_items_shipped`).
- Run `bash scripts/ci/run_gate.sh all` — check the Y-sort perf budget
  for both (verify sprite/no-sprite, exclusion-list vs bump
  accordingly, same as every prior area).
- **This is the final task in the whole plan** — after this lands and
  the gate is green, the "6 romance + 6 rivals + 5 unlockable areas"
  request is fully delivered. No git/gh actions — stop after code +
  tests are written and the gate is green. Do not commit, push, open a
  PR, or merge.
