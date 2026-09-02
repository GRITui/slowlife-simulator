# TASK-343 — Sprint 4: 2 more unlockable areas (Deep Canal Bend, Sacred Grove)

Sprint 4 of the "6 romance + 6 rivals + 5 unlockable areas" plan.
Brings the unlockable-area count from 1 (Mountain Cave, TASK-337) to 3.
Same constraints as TASK-337 throughout: no map/grid expansion, no new
items, no new persisted field (every gate below is an already-persisted
stat), each area is one new interactable in an already-verified-clear
map position. Read `docs/research/TASK-337-spec.md` and
`scripts/interactables/MountainCaveSpot.gd` first — both new spots in
this task follow that exact template.

## Area 2: Deep Canal Bend (fishing variant)

- New file `scripts/interactables/DeepCanalSpot.gd`, mirroring
  `scripts/interactables/FishingSpot.gd`'s pattern (read it in full).
  Reuses `data/fish/fish.json`'s existing roster verbatim — no new
  fish. Rarity weights inverted from `FishingSpot._roll_catch()`'s
  existing common/uncommon/rare/legendary weighting so legendary
  species are far more likely here (check `FishingSpot.gd`'s exact
  current weights before inverting — mirror the same "richer vein"
  framing `MountainCaveSpot.gd` used for ore).
  - Gate: `GameData.fishing_skill >= 4` (the existing cap — same
    threshold as the `master_angler` milestone, TASK-331).
  - Does NOT bump `fishing_skill` and does NOT re-trigger
    `master_angler` or `storm_catch` — those surfaces belong to
    `FishingSpot.gd`.
  - Still requires a fishing rod held (`GameData.has_item("fishing_rod", 1)`),
    matching `FishingSpot.gd`'s existing gate.
  - Position: `Vector2(12 * 48 + 24, 14 * 48)` — verified via a
    headless `ground_at()` probe: tile `(12,14)` is `ground_grass`
    (walkable) and its north neighbor `(12,13)` is `canal`, satisfying
    `_water_adjacent()`'s check. Clear of every other node's position.

## Area 3: Sacred Grove (wood-gathering variant)

- New file `scripts/interactables/SacredGroveSpot.gd`, mirroring
  `scenes/entities/ForestTree.gd`'s `chop()` pattern (read it in full
  — it's much simpler than `MiningSpot`/`FishingSpot`, a single daily-
  gated wood yield, tool-bonus-aware). Reuses the same `"wood"` item —
  no new item. The "richer vein" framing here is a higher daily yield
  (e.g. 3 base + axe bonus, vs `ForestTree`'s 1 base + axe bonus) since
  wood has no rarity tiers to invert.
  - Gate: `GameData.companion_bond_tier() >= 4` (the existing max cat-
    bond tier — same threshold as the `inseparable` milestone,
    TASK-331). Thematically: the cat leads you to a grove it trusts you
    enough to show.
  - Daily-gated per spot (mirror `ForestTree.gd`'s once-per-day logic
    if it has one — check before assuming; if `ForestTree.gd` has no
    daily gate and just always yields wood on interact, match that
    instead of inventing a new gate this task doesn't need).
  - Position: `Vector2(19 * 48 + 24, 6 * 48)` — verified via a headless
    `ground_at()` probe: tile `(19,6)` is `ground_grass`, near the
    existing `ForestTree` cluster (`(18,3)`/`(18,5)`/`(19,4)`) for
    thematic proximity, one tile clear of `ForestTree19_4`. Re-verify
    against the current occupied-position list before placing (it has
    grown across TASK-341/342).

## Unlock wiring (both spots, same pattern as `MountainCaveSpot`)

`Main.gd`: `_ensure_deep_canal()` and `_ensure_sacred_grove()`, each
gated on their respective stat, called once from `_ready()` AND
subscribed via the existing `_on_minute_ticked_unlocks()` handler
(from TASK-337 — do not create a second `minute_ticked` subscription
in `Main.gd`, add both checks into the existing handler function).

## Tests

New `tests/test_deep_canal.gd` and `tests/test_sacred_grove.gd`,
mirroring `tests/test_mountain_cave.gd`'s structure and coverage
exactly (default-gate-hides-spot, tick-unlocks, fresh-boot-with-stat-
already-met unlocks immediately, real `Area2D`, roster/item parity
with the base spot, no skill/tier bump, statistical rarity-inversion
check for Deep Canal — Sacred Grove doesn't need the statistical check
since wood has no rarity roll, just assert the yield amount is higher
than `ForestTree`'s).

## Constraints

- Do not touch `GridManager.gd`, `WorldRender.gd`, `FishingSpot.gd`,
  `ForestTree.gd`, `fish.json`, or any `GameData` field.
- Do not duplicate the `master_angler` or `inseparable` milestone
  triggers.
- Run `bash scripts/ci/run_gate.sh all` — Y-sort budget will need
  another look (check whether these spots get sprites; if not, add to
  the exclusion list like `MiningSpot`/`Noticeboard`/`MountainCaveSpot`
  rather than bumping the cap unnecessarily — verify, don't assume).
- No git/gh actions — stop after code + tests are written and the gate
  is green. Do not commit, push, open a PR, or merge.
