# TASK-352 — Building interiors + map transitions (foundation)

Owner-identified gap: the entire game currently lives in exactly one
scene (`scenes/core/Main.tscn`) — no interior buildings, no doors, no
map/scene transitions of any kind exist. Researched via direct codebase
reading plus a free-model (Cline/minimax-m3) second opinion,
cross-checked against the actual code (the free model's answer
contained one factual error, corrected below — never treat its output
as authoritative without verification, same policy as this project's
Gemini-research rule).

This spec is the FOUNDATION only: the `TimeManager` fix, the
`SceneLoader` autoload, the door/warp convention, and ONE proof-of-
concept interior (the player's own farmhouse — already implied by
`ART_STYLE_GUIDE.md`'s farmer/home framing, and the simplest possible
interior with no NPCs to relocate). It does NOT attempt to convert
every existing outdoor building (market, temple, trader's stall) into
enterable interiors — that's follow-up work once this foundation is
proven, tracked separately.

## Why `change_scene_to_file()`, not a mega-scene (read before objecting)

This codebase already keeps all persistent state in autoloads
(`GameData`, `SignalBus`) rather than on `Main`'s own node tree, and
already uses a clean self-registration convention for exactly this
kind of "may not outlive the current scene" node:

```gdscript
# scenes/core/GridManager.gd:32,36 (existing code, unchanged by this task)
func _ready() -> void:
    SignalBus.grid_manager = self
    ...
func _exit_tree() -> void:
    if SignalBus.grid_manager == self:
        SignalBus.grid_manager = null
```

A toggle-visibility "keep everything loaded, just hide interiors"
mega-scene is the wrong fit for this specific codebase: hidden nodes
still run `_process()`, stay signal-connected, and never hit
`_exit_tree()` — defeating the exclusion-list pattern
`tests/perf/test_mobile_budget.gd` already relies on (see that file's
`MiningSpot`/`Noticeboard`/`MountainCaveSpot`/etc. exclusion list,
extended by every unlockable-area task this session). `change_scene_to_file()`
makes the Y-sort budget a true per-area ceiling instead of a
combined-across-everything one, and needs zero new architectural
convention — just the existing registry pattern applied to one more
node class.

## Step 1 — `TimeManager` becomes a true autoload (do this FIRST)

**This is the load-bearing fix.** `TimeManager` is currently a regular
child node instanced inside `Main.tscn`
(`scenes/core/Main.tscn:26`, `[node name="TimeManager" parent="."
instance=ExtResource("2_tm")]`) — NOT in `project.godot`'s
`[autoload]` section (verified: that list is exactly `SignalBus`,
`GameData`, `FrameCap`, `AudioManager`). Its actual clock state
(`day`, `hour`, `minute`, `_accum_minutes` — see
`scenes/core/TimeManager.gd:14-17`) lives ONLY on that node; only
`current_season`/`current_weather` are mirrored to `GameData`. A scene
swap that destroys `Main.tscn` would destroy `TimeManager` with it,
silently resetting the clock to day 1, 06:00 on every building entry.

Fix:
1. Add `TimeManager="*res://scenes/core/TimeManager.tscn"` to
   `project.godot`'s `[autoload]` section (after `GameData`, before
   `AudioManager` — matches the existing rough dependency order).
2. Remove the `TimeManager` node from `scenes/core/Main.tscn` (delete
   the `[node name="TimeManager" ...]` block and its `ExtResource`
   declaration).
3. `SignalBus.time_manager` self-registration in `TimeManager.gd`
   (`_ready()`/`_exit_tree()`) stays exactly as-is — a true autoload
   still benefits from the same registry pattern (other code already
   reads `SignalBus.time_manager`, not `$TimeManager` node paths — grep
   `SignalBus.time_manager` to confirm no caller assumed the OLD node
   path specifically before this change; if any do, fix them to use
   the registry, not a hardcoded path).
4. Regression-check every test that instances `Main.tscn` and expects
   to find `TimeManager` as a child of `main` (`main.get_node_or_null
   ("TimeManager")` or similar) — these now need `SignalBus.time_manager`
   instead, since a true autoload lives at `/root/TimeManager`, not
   under Main. `grep -rn "get_node.*TimeManager\|\\$TimeManager"
   tests/ scenes/ scripts/` yourself and fix every hit.

## Step 2 — `scripts/autoload/SceneLoader.gd` (new autoload)

Single entry point for every scene transition (doors now, save/load
and debug commands later reuse the same path — don't build a
door-specific mechanism that a future non-door transition can't also
use).

```gdscript
extends Node
## SceneLoader — TASK-352. Single entry point for scene transitions.
## Doors emit SignalBus.scene_transition_requested; this autoload is
## the only thing that calls change_scene_to_file(), so every future
## transition source (save/load, debug teleport, festival cutscenes)
## goes through one code path.

func _ready() -> void:
    SignalBus.scene_transition_requested.connect(_on_transition_requested)

func _on_transition_requested(target_scene_path: String, target_warp_id: String) -> void:
    SignalBus.pending_warp_id = target_warp_id
    get_tree().change_scene_to_file(target_scene_path)
```

Add to `project.godot`'s `[autoload]` list AFTER `SignalBus`/`GameData`/
`TimeManager` (it depends on `SignalBus` existing at `_ready()` time —
Godot autoloads initialize in declaration order).

Add to `SignalBus.gd`:
```gdscript
signal scene_transition_requested(target_scene_path: String, target_warp_id: String)
var pending_warp_id: String = ""
```

## Step 3 — Door/warp convention

New `scenes/interactables/Door.gd` + `scenes/interactables/Door.tscn`
(mirrors the existing small-interactable pattern —
`MountainCaveSpot.gd` etc. — a `Node2D` with a programmatically-built
`Area2D`, per this project's own established
"script.new()-instanced-spot needs a programmatic InteractArea, never
`@onready $InteractArea`" lesson from TASK-343):

```gdscript
extends Node2D
## Door — TASK-352. Placed as a real .tscn child (NOT script.new()-
## instanced like the unlockable-area spots) since doors are fixed,
## hand-placed level geometry, not dynamically-gated content — a real
## .tscn instance CAN safely use @onready $InteractArea here; this is
## the ForestTree.gd case, not the MountainCaveSpot.gd case.

@export var target_scene_path: String = ""
@export var target_warp_id: String = ""
## This door's OWN id — when a door elsewhere targets this warp id,
## the player spawns at this door's position (see spawn_offset).
@export var warp_id: String = ""
@export var spawn_offset: Vector2 = Vector2(0, 48)  # one tile south of the door

@onready var _area: Area2D = $InteractArea

var _player_in_range: bool = false

func _ready() -> void:
    add_to_group("door")
    _area.body_entered.connect(_on_body_entered)
    _area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
    if not _player_in_range:
        return
    if event.is_action_pressed("interact"):
        SignalBus.scene_transition_requested.emit(target_scene_path, target_warp_id)
        get_viewport().set_input_as_handled()

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("player"):
        _player_in_range = true

func _on_body_exited(body: Node) -> void:
    if body.is_in_group("player"):
        _player_in_range = false
```

Each area's root script (see Step 4) finds the door matching
`SignalBus.pending_warp_id` in the `"door"` group and positions the
player at `door.global_position + door.spawn_offset` on `_ready()`,
then clears `SignalBus.pending_warp_id = ""`.

## Step 4 — Rename `Main` -> `World`, extract an `AreaShell` base

`scenes/core/Main.tscn`/`Main.gd` become `scenes/core/World.tscn`/
`World.gd` (the outdoor area) — a rename, not a rewrite; every
existing `_ensure_*` function, NPC, and unlockable-area spot stays
exactly where it is. Do NOT attempt to split `World.gd`'s many
`_ensure_*` functions apart in this task — that's unrelated cleanup,
out of scope.

New `scenes/interiors/FarmHouse.tscn` + `scenes/interiors/FarmHouse.gd`
— the ONE proof-of-concept interior for this task. Minimal: a small
room (e.g. 6x5 tiles) with its own `GridManager`/`WorldRender`-
equivalent (a much simpler one — an interior has no crops, no
seasons-driven ground, likely just a static floor tileset + walls; do
NOT reuse `WorldRender.gd`'s outdoor `ZONES`/`PROPS` constants —
write a small interior-specific render setup, or even a plain
hand-authored `.tscn` background sprite if the interior has zero
interactive tiles yet), one `Door` back outside, and self-registers
`SignalBus.grid_manager`/(a new) `SignalBus.world_render` in `_ready()`/
`_exit_tree()` exactly like `GridManager.gd` does today. Add
`world_render: Node = null` next to `SignalBus.grid_manager` in
`SignalBus.gd` while this is being built — migrate `FishingSpot.gd`/
`DeepCanalSpot.gd`/`LotusMazeShoreSpot.gd`'s existing `get_parent()
.get_node("WorldRender")` lookups to the new registry slot in the same
PR (small, mechanical change, but leaving the old pattern half-migrated
would be worse than not starting).

Place ONE `Door` instance in `World.tscn` near the player's home
position (verify a clear tile via the established `ground_at()`
headless-probe convention every prior spot task has used) targeting
`res://scenes/interiors/FarmHouse.tscn` / `warp_id="farmhouse_entry"`,
and one `Door` inside `FarmHouse.tscn` targeting
`res://scenes/core/World.tscn` / `warp_id="farmhouse_exit"` (the
outdoor door's own `warp_id`).

## Step 5 — Fix the hard-snapped player spawn

`World.gd`'s `_ready()` (formerly `Main.gd`) currently hard-snaps the
player to `Vector2(480, 384)` unconditionally on every boot. Change
to: if `SignalBus.pending_warp_id != ""`, find the matching door and
spawn there (per Step 3); otherwise (fresh boot / loaded save with no
pending warp) keep the existing `(480, 384)` default.

## Tests

New `tests/test_scene_transitions.gd`:
- `TimeManager` is a true autoload: `Engine.has_singleton` or
  equivalent check, OR simpler — assert `SignalBus.time_manager` is
  non-null and NOT a child of a loaded `World.tscn` instance (proves
  it survived independently of the scene tree).
- Advance the clock (e.g. `SignalBus.time_manager.day = 5`), trigger a
  transition via `SignalBus.scene_transition_requested.emit(...)`,
  confirm `SignalBus.time_manager.day` is STILL `5` after the swap —
  this is the single most important regression guard given what this
  whole task exists to fix.
- Door -> interior -> door -> back outside round-trip: player position
  ends up correctly at each side's warp target, not the default
  `(480, 384)` snap.
- `SignalBus.pending_warp_id` is cleared (back to `""`) after being
  consumed, so a THIRD unrelated scene load later doesn't
  misinterpret a stale pending warp.
- Regression: `tests/perf/test_mobile_budget.gd` still loads
  (now-renamed) `World.tscn` and passes at the same participant
  budget — confirm the rename didn't silently break this gate's own
  `load("res://scenes/core/Main.tscn")` call (needs updating to
  `World.tscn`).
- Regression: grep every test file for `Main.tscn` / `"Main"` node-name
  assumptions and update each one found — do not leave any test
  silently loading a path that no longer exists.

## Constraints

- Do not convert any OTHER existing building (market, temple, trader
  stall) into an enterable interior in this task — FarmHouse is the
  only proof-of-concept. Follow-up tasks extend the same convention.
- Do not attempt a fade-to-black transition effect in this task —
  instant `change_scene_to_file()` matches the genre precedent (both
  Stardew Valley and Harvest Moon: Back to Nature swap instantly, no
  loading screen) and keeps this task's scope to the architecture, not
  polish. A fade effect can hook into `SceneLoader.gd` later without
  changing its public contract.
- Do not refactor `World.gd`'s (formerly `Main.gd`'s) existing
  `_ensure_*` functions — rename the file, don't restructure it.
- Do not touch `WorldRender.gd`'s outdoor `ZONES`/`PROPS` constants —
  the interior needs its own, much simpler render setup, not a
  parameterized version of the outdoor one.
- Run `bash scripts/ci/run_gate.sh all` — expect to need to fix
  existing tests that assumed `Main.tscn`/`"Main"` node name; find and
  fix every one via grep, not just the ones you happen to notice fail.
- No git/gh actions — stop after code + tests are written and the gate
  is green. Do not commit, push, open a PR, or merge.
