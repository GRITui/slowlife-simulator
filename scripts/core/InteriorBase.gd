extends Node2D
class_name InteriorBase
## InteriorBase — TASK-357. Shared skeleton for every interior/area scene:
## self-register into SignalBus.grid_manager / SignalBus.world_render,
## resolve pending_warp_id to a door-relative or edge-relative spawn,
## fall back to a configurable default. Subclasses override _build_render()
## only (and the no-op plant/water/harvest contract where applicable).
##
## Why: FarmHouse.gd (TASK-352) hand-wrote this whole skeleton once. Every
## future interior (NPC houses, a Market interior, a Temple interior, and
## every further district split like this task's CoastalArea) needs the
## exact same skeleton. Copy-pasting FarmHouse.gd per building is how
## this codebase accumulates the kind of drift TASK-352's own review
## already had to catch once (the missing plant/water/harvest stand-ins).
## Extract now while there's only one existing caller to refactor safely;
## add a second (CoastalArea) so the base actually generalizes rather
## than describing a refactor no second caller ever exercises.
##
## Spawn-resolution precedence (MUST match FarmHouse.gd's existing
## behavior, including the TASK-357 has_pending_load_position check):
##   1. has_pending_load_position (TASK-357 save/load restore — the save
##      can be made anywhere, not just standing at a door or edge).
##   2. pending_warp_id resolving to an EdgeTransition (TASK-357 — place
##      the player at edge.global_position with the carry_axis coordinate
##      drawn from SignalBus.edge_carry_value, NOT at a fixed point).
##   3. pending_warp_id resolving to a Door (TASK-352 — door + offset).
##   4. default_spawn (no warp, fresh boot into this interior).

## Where the player lands when nothing else resolves (fresh boot into the
## interior with no pending warp and no save-load position). Subclasses
## override per scene; FarmHouse defaults to the room center (3 tiles in
## on a 6x5 room), CoastalArea will override to its own default.
@export var default_spawn: Vector2 = Vector2(72, 72)

const PLAYER_SCENE_PATH: String = "res://scenes/entities/Player.tscn"

var _player: Node2D = null

func _ready() -> void:
	_build_render()
	_register_self()
	_spawn_player()

func _exit_tree() -> void:
	# Clear per-area registry slots we own, same shape as the outdoor
	# World scene's contract. Interiors self-register in _ready() so the
	# outgoing Player/move_and_slide machinery keeps reading consistent
	# state during the deferred scene swap.
	if SignalBus.grid_manager == self:
		SignalBus.grid_manager = null
	if SignalBus.world_render == self:
		SignalBus.world_render = null

## Subclass override hook — build the interior's tile render, props, and
## child nodes here. The base does nothing; FarmHouse / CoastalArea /
## future interiors each paint their own (interiors don't inherit the
## outdoor tile-state model).
func _build_render() -> void:
	pass

func _register_self() -> void:
	# Interiors self-register with the same slots the outdoor area uses,
	# so scripts that read SignalBus.grid_manager / SignalBus.world_render
	# (e.g. FishingSpot/DeepCanalSpot/LotusMazeShoreSpot) keep working
	# without caring which area is current. World.gd's _ready() does
	# the same for its own per-area WorldRender child.
	SignalBus.grid_manager = self
	SignalBus.world_render = self

## Instance the Player as a child of this interior and place them at the
## resolved spawn. Mirrors FarmHouse.gd's pre-TASK-357 logic exactly
## (same precedence, same default), with the new edge-warp branch added
## for TASK-357's walk-through area-to-area transitions.
func _spawn_player() -> void:
	var player_scene: PackedScene = load(PLAYER_SCENE_PATH)
	if player_scene == null:
		return
	var pl: Node2D = player_scene.instantiate() as Node2D
	if pl == null:
		return
	pl.name = "Player"
	add_child(pl)
	_player = pl
	_apply_camera_bounds(pl)
	_place_player(pl)

## Bugfix found live (2026-09-04): Player.tscn's Camera2D ships with
## limit_right/limit_bottom hardcoded to the outdoor World's size
## (960x768, see the World camera-clamp fix) so it doesn't show
## unrendered space past the World's own map edge. But every
## InteriorBase subclass is a much smaller room (FarmHouse: 6x5 tiles =
## 288x240; CoastalArea: 5x5 = 240x240) — reusing the outdoor limits let
## the camera show the exact same "flat void past the edge" bug the
## outdoor fix solved, just indoors. Every InteriorBase subclass already
## defines its own GRID/TILE consts (used by its own _build_render()),
## so read those via the script constant map -- GDScript consts aren't
## reachable through plain `get()`/`in`. Leaves Player.tscn's default
## limits alone if a subclass doesn't define both (defensive; not
## expected to trigger for any current or future interior).
func _apply_camera_bounds(pl: Node2D) -> void:
	var cam: Camera2D = pl.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	var consts: Dictionary = get_script().get_script_constant_map()
	if not (consts.has("GRID") and consts.has("TILE")):
		return
	var grid: Vector2i = consts["GRID"]
	var tile: int = int(consts["TILE"])
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = grid.x * tile
	cam.limit_bottom = grid.y * tile

## Resolve the spawn position and assign it. Factored out of
## _spawn_player so the TASK-357 edge-warp branch can share the
## has_pending_load_position / pending_warp_id / default cascade cleanly.
func _place_player(pl: Node2D) -> void:
	# TASK-357 save/load precedence: a save made anywhere (not just at a
	# door/edge) must restore the player to that exact position. MUST be
	# checked before pending_warp_id — a save made mid-area can race with
	# a stale pending warp from an unrelated earlier scene load.
	if SignalBus.has_pending_load_position:
		pl.global_position = SignalBus.pending_load_position
		SignalBus.has_pending_load_position = false
		return
	if SignalBus.pending_warp_id != "":
		# Try an EdgeTransition match first (TASK-357 — carries the
		# player's coordinate on carry_axis from the outgoing scene, not a
		# fixed point like a Door). Walks the edge_transition group the
		# same way FarmHouse.gd's door-warp lookup walks the door group.
		var edge_node: Node = null
		for e in get_tree().get_nodes_in_group("edge_transition"):
			if e is Node2D and String((e as Node).get("warp_id")) == SignalBus.pending_warp_id:
				edge_node = e
				break
		if edge_node != null:
			var axis: String = String((edge_node as Node).get("carry_axis"))
			var edge_pos: Vector2 = (edge_node as Node2D).global_position
			if axis == "y":
				pl.global_position = Vector2(edge_pos.x, SignalBus.edge_carry_value)
			else:
				pl.global_position = Vector2(SignalBus.edge_carry_value, edge_pos.y)
			# Consume the pending warp so a later unrelated scene load
			# doesn't misinterpret a stale value.
			SignalBus.pending_warp_id = ""
			return
		# Fall through to a Door match (TASK-352 — fixed door + offset).
		var door_node: Node = null
		for d in get_tree().get_nodes_in_group("door"):
			if d is Node2D and String((d as Node).get("warp_id")) == SignalBus.pending_warp_id:
				door_node = d
				break
		if door_node != null:
			pl.global_position = (door_node as Node2D).global_position + Vector2((door_node as Node).get("spawn_offset"))
		else:
			# No matching door or edge (fresh boot into interior) — default
			# so the player isn't clipped into a wall.
			pl.global_position = default_spawn
		SignalBus.pending_warp_id = ""
		return
	pl.global_position = default_spawn