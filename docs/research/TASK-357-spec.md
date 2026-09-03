# TASK-357 — Multi-scene world topology: the screen-graph framework for world expansion

Follow-up from TASK-352 (#198) and the HM:BTN world-map gap analysis done
in this session. Not a content task: this is the architecture decision
that determines how every future outdoor area, NPC home, and amenity
building gets added from here on.

## The gap, grounded in the actual code (not the reference screenshot alone)

The owner's HM:BTN map reference shows a world built as a **graph of ~20
small connected screens** (each a handful of buildings or one resource
activity), joined by fixed edges — walking off the right edge of one
screen lands you on the left edge of the next. Building entry (Ellen's
House) and area-to-area travel (Library screen → Supermarket screen) are
literally the same mechanic in that engine: every transition is a warp.

Our world is the opposite shape. Verified directly against the code:

- **One monolithic outdoor scene.** Every dynamic spawn in `World.gd`
  (`_ensure_mining_spot`, `_ensure_mountain_cave`, `_ensure_deep_canal`,
  `_ensure_sacred_grove`, `_ensure_lotus_maze_shore`,
  `_ensure_coastal_trading_post`, `_ensure_forest`, `_ensure_race_course`,
  `_ensure_lopburi`, `_ensure_banana_tree`, `_ensure_cooking_station`,
  `_ensure_chicken_coop`, `_ensure_buffalo`, every festival — ~20 `_ensure_*`
  calls in `_ready()` alone) is instanced as a child of the single
  `World.tscn`, not a separate screen.
- **~20+ named NPCs** (5 romance candidates, 6 rivals, 5 villagers, 2 peer
  NPCs, monk, trader, companion animals — confirmed via
  `scenes/entities/*NPC*.tscn`) and **zero of them have an enterable
  home.** All interaction happens by walking up to them in the open
  world.
- **One enterable building total** (FarmHouse, TASK-352) — Market and
  Temple are decorative tile-zones/structures on the outdoor map, not
  separate screens.
- **A concrete, already-paid technical cost of the monolithic shape:**
  `tests/perf/test_mobile_budget.gd`'s Y-sort ceiling has been raised
  **eight times** as content was added to this one scene (32→36→40→44→
  49→50→51→54→60, per that file's own changelog comments). Every screen
  in a graph-shaped world only Y-sorts what's physically on it; ours
  Y-sorts the entire game's cast and props in one frame, and that number
  keeps climbing.

**The content gap is smaller than it looks.** We already have HM:BTN-
equivalent systems (mining, a wilderness/water cluster, festivals, a
large NPC cast). What's missing is the *spatial framing* — presenting
that content as a legible graph of small places instead of one
increasingly dense map. That's an architecture decision, not a content
backlog.

## Scope: framework + ONE proof-of-concept split (same discipline as TASK-352)

This spec does **not** attempt to redesign the whole map in one pass.
Mirroring TASK-352's own foundation-only scope (SceneLoader + Door
convention + one interior, not "convert every building"), this task
ships:

1. The reusable infrastructure (edge transitions, warp-id namespacing,
   an `InteriorBase`/`AreaBase` refactor, the save-schema fix below).
2. **One** proof-of-concept split: carve the eastern water cluster —
   `DeepCanalSpot` (19,6) and `CoastalTradingPost` (16,6), already
   adjacent on the same row at the map's eastern edge — into a new
   `CoastalArea.tscn`, reachable by walking off `World.tscn`'s east edge.

Every other district (village/amenity buildings, NPC homes, a
market/temple conversion) is explicit follow-up work, tracked as
separate tasks once this framework is proven — not scoped here, for the
same reason TASK-352 didn't try to convert Market/Temple in its first
pass: proving the mechanism cleanly matters more than maximizing area
count in one diff.

## Architecture

### What's reused unchanged

`SceneLoader`, `SignalBus.scene_transition_requested`/`pending_warp_id`,
and the `SignalBus.grid_manager`/`world_render` self-registration
pattern from TASK-352 don't change at all. An area-to-area transition
and a building-door transition are the same underlying signal — this is
exactly the uniformity the HM:BTN reference relies on, and it's already
how our mechanism works. The only new pieces are below.

### New: `EdgeTransition.gd` (walk-through, distinct from `Door.gd`)

`Door.gd` requires facing + an interact press — correct for buildings.
Map-edge crossings in every reference game are **walk-through**, no
button press. Introduce a separate node type rather than overloading
`Door`:

```gdscript
# scenes/interactables/EdgeTransition.gd (new)
extends Area2D
## Walk-through area-to-area transition (map edges), distinct from
## Door.gd's interact-required building entry. Fires once per crossing,
## not once per frame while overlapping — see _player_inside guard.

@export var target_scene_path: String = ""
@export var target_warp_id: String = ""
@export var warp_id: String = ""
## The axis that carries across unchanged (see "Coordinate carry-over"
## below). "x" for a north/south edge, "y" for an east/west edge.
@export var carry_axis: String = "y"

var _player_inside: bool = false

func _ready() -> void:
    add_to_group("edge_transition")
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
    if not body.is_in_group("player") or _player_inside:
        return
    _player_inside = true
    SignalBus.edge_carry_value = body.global_position[carry_axis]
    SignalBus.scene_transition_requested.emit(target_scene_path, target_warp_id)

func _on_body_exited(body: Node) -> void:
    if body.is_in_group("player"):
        _player_inside = false
```

### Coordinate carry-over (the one real design problem a Door doesn't have)

A `Door` warp always lands you at a **fixed point** (the matching door's
position + offset) — correct for building entry. An edge crossing must
NOT snap to a fixed point: walking off the east edge of `World.tscn` at
y=288 should land you on `CoastalArea.tscn`'s west edge at the *same*
y=288, not at some arbitrary door-anchor point. This needs a new
`SignalBus.edge_carry_value: float` (set by the outgoing
`EdgeTransition` before emitting, read by the incoming scene's matching
`EdgeTransition` to position the player along its own edge on the
`carry_axis`). Building `Door` warps are unaffected — they keep using
the existing fixed `spawn_offset` convention untouched.

### Warp-id namespacing

TASK-352 needed exactly two warp ids (`farmhouse_entry`/
`farmhouse_exit`) and flat strings were fine. Once N areas exist, flat
strings collide silently — two unrelated doors both named `"north_exit"`
would resolve to whichever the group-search finds first, with no error.
Adopt `"<scene_stem>_<edge_or_landmark>"` (e.g.
`"world_east_to_coastal"`, `"coastal_west_to_world"`) as a hard
convention from this task forward, and add an engine-test check
(mirroring `test_scene_transitions.gd`'s existing Main.tscn-reference
grep pattern) that fails the gate if two doors/edges anywhere in
`scenes/` share a `warp_id`.

### `InteriorBase.gd` — extract the pattern FarmHouse.gd hard-coded once

`FarmHouse.gd` (TASK-352) hand-writes: build a tile-rect room, self-
register into `SignalBus.grid_manager`/`world_render`, find the door
matching `pending_warp_id` and spawn there or fall back to a default.
Every future interior (NPC houses, a Market interior, a Temple interior)
needs the *exact* same skeleton. Copy-pasting `FarmHouse.gd` per
building is how this codebase accumulates the kind of drift TASK-352's
own review already had to catch once (the missing `plant`/`water`/
`harvest` stand-ins). Extract the shared logic now, while there's only
one caller to refactor safely:

```gdscript
# scripts/core/InteriorBase.gd (new)
extends Node2D
## Shared skeleton for every interior/area scene: self-register,
## resolve pending_warp_id to a door-relative spawn, fall back to a
## configurable default. Subclasses override _build_render() only.

@export var default_spawn: Vector2 = Vector2(72, 72)

func _ready() -> void:
    _build_render()
    _register_self()
    _spawn_player()

func _exit_tree() -> void:
    if SignalBus.grid_manager == self:
        SignalBus.grid_manager = null
    if SignalBus.world_render == self:
        SignalBus.world_render = null

func _build_render() -> void:
    pass # subclass override — construct floor/wall tiles here

func _register_self() -> void:
    SignalBus.grid_manager = self
    SignalBus.world_render = self

func _spawn_player() -> void:
    # ... identical door-lookup/pending_warp_id logic FarmHouse.gd has
    # today, parameterized by default_spawn instead of a hardcoded
    # Vector2(3 * TILE, 3 * TILE) ...
```

`FarmHouse.gd` becomes a thin subclass (just `_build_render()` plus its
`plant`/`water`/`harvest`/`is_plantable`/`ground_at` no-op contract).
`CoastalArea.gd` (this task's proof-of-concept) becomes the second
subclass, proving the base actually generalizes rather than describing
a refactor no second caller ever exercises.

## Save-compat: a real, pre-existing gap this task makes load-bearing

Checked directly (not assumed): `SaveManager.gd`'s save payload writes
`"player_pos": [480, 384]` — **a hardcoded literal, not the player's
actual position** — and no code anywhere reads `player_pos` back on
load. There is also **no field for which scene the player is in.** This
has been silently fine because there was only one scene to boot into.

Once `CoastalArea.tscn` exists, "always boot into `World.tscn`" is no
longer a no-op default — it's a real, silent teleport if a player saves
while in the new area (or, later, while in any interior). Per this
project's own always-escalate rule for save-schema work: **write the
"a save made in CoastalArea boots back into CoastalArea, not World"
test FIRST, confirm it fails, then implement** — the same discipline
TASK-340's migration-indentation bug should have taught us, not
inspection-only confidence.

Required companion fix, in scope for this task (not deferred):
- Add `"scene_path": String` to the save schema, bump `SAVE_VERSION`
  (currently 5 → 6), write the v5→v6 migration (missing `scene_path`
  defaults to `run/main_scene`'s value, preserving every existing save).
- Actually persist and restore real `player_pos` + `scene_path` on
  save/load, instead of the current hardcoded/unread literal.

## Migration plan

**Phase 0 (infra, this task):**
1. `EdgeTransition.gd` + `SignalBus.edge_carry_value`.
2. Warp-id namespacing convention + gate-enforced uniqueness check.
3. `InteriorBase.gd` extraction; refactor `FarmHouse.gd` onto it (proves
   the refactor via its one existing caller before adding a second).
4. Save schema fix (`scene_path`, `SAVE_VERSION` 5→6, migration test
   written first).
5. Carry over TASK-353's spawn-drift/facing fix (#199) to
   `EdgeTransition` as well as `Door` — edge crossings are walk-through,
   so an unfixed instant-re-trigger bug is *worse* here than at a door
   (no interact press to accidentally repeat — just standing near the
   boundary could ping-pong). **TASK-353 should land before or alongside
   this task**, not after.

**Phase 1 (proof-of-concept, this task):** `CoastalArea.tscn` — relocate
`DeepCanalSpot` and `CoastalTradingPost` out of `World.gd`'s
`_ensure_deep_canal`/`_ensure_coastal_trading_post` into the new scene's
`_ready()`, add a matching `EdgeTransition` pair at `World.tscn`'s east
edge / `CoastalArea.tscn`'s west edge. Confirms: the Y-sort budget
measurably drops on `World.tscn` (two fewer participants), the
coordinate carry-over lands the player at the correct parallel offset,
and the whole round trip survives a save/load in either scene.

**Phase 2+ (explicit follow-up, NOT this task):** further district
splits (village/amenity cluster around Market — a real Market interior
is also #201-adjacent follow-up; Temple; a ranch/pasture district for
buffalo/chicken content), and the NPC-homes rollout the gap analysis
flagged (each home is just another `InteriorBase` subclass + `Door`
pair once this framework lands — content/placement work per NPC, not
new architecture).

## Testing strategy

New `tests/test_area_edges.gd`, mirroring `test_scene_transitions.gd`'s
existing structure:
- Edge crossing lands at the correct carried coordinate (not a fixed
  point) in both directions.
- `TimeManager`/clock state survives a `World ↔ CoastalArea` round trip
  (same load-bearing check as TASK-352, now exercised on a second
  scene pair).
- Y-sort budget on `World.tscn` actually decreases by exactly the
  participant count moved to `CoastalArea` — a real, measurable
  regression guard against this refactor accidentally leaving stragglers
  behind.
- Save/load round-trip: save while in `CoastalArea`, reload, confirm
  `scene_path` and position both resolve correctly (the failing-first
  test per the save-compat section above).
- Warp-id collision check across all `scenes/` doors + edges (gate-level,
  not per-file).

## Non-goals (explicit, so this doesn't scope-creep)

- Not converting Market/Temple into interiors (tracked as follow-up,
  #201-adjacent).
- Not building any NPC homes (framework only — `InteriorBase` makes that
  cheap later, doesn't build it now).
- Not relaying out or redesigning `World.tscn`'s existing tile art
  beyond removing the two relocated spots — no broader map redesign.
- Not solving TASK-353/354/356 (#199/#200/#202) — this task assumes
  #199 (spawn-drift/facing fix) lands first or alongside, since edge
  transitions inherit that same risk class; #200 (fade/SFX) and #202
  (ambience/time-pause) apply equally well to edge crossings once built
  but aren't blocking.

## Open questions for the owner

1. Confirm `CoastalArea` as the Phase-1 proof-of-concept slice (chosen
   because `DeepCanalSpot`/`CoastalTradingPost` already sit adjacent at
   the map's eastern edge — no existing content needs to be relocated
   *within* the new scene, only lifted out of `World.gd`) — or name a
   different first slice.
2. `SAVE_VERSION` bump to 6 is a real schema change touching every
   existing save; confirm the migration-test-first requirement above is
   the right bar before this ships (consistent with this project's
   always-escalate rule for save-schema work).
