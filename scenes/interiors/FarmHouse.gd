extends Node2D
## FarmHouse — TASK-352. The ONE proof-of-concept interior for the
## scene-transition foundation. Minimal: a 6x5-tile room with a static
## structure_floor + structure_wall tile render, a Player instanced as a
## child, and one Door back to the outdoor World. Self-registers
## SignalBus.grid_manager + SignalBus.world_render in _ready() and
## tears the registration down in _exit_tree(), exactly like
## GridManager.gd does today. No crops, no seasons — interiors don't
## inherit the outdoor tile-state model.

const TILE: int = 48
const GRID: Vector2i = Vector2i(6, 5)
const FLOOR_TILE: String = "res://assets/tilesets/structure_floor.png"
const WALL_TILE: String = "res://assets/tilesets/structure_wall.png"

@onready var _ground_layer: TileMapLayer = null
@onready var _player: Node2D = null

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
	# Interior's own minimal render — a single TileMapLayer with the floor
	# tileset, plus four wall sprite rows. NO outdoor ZONES/PROPS reuse —
	# interiors are a separate, much simpler shape (see spec Step 4).
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var src := TileSetAtlasSource.new()
	var tex: Texture2D = load(FLOOR_TILE) as Texture2D
	src.texture = tex
	src.texture_region_size = Vector2i(TILE, TILE)
	src.create_tile(Vector2i(0, 0))
	ts.add_source(src, -1)
	var ground := TileMapLayer.new()
	ground.tile_set = ts
	ground.name = "GroundLayer"
	add_child(ground)
	for x in GRID.x:
		for y in GRID.y:
			ground.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	_ground_layer = ground
	# Walls as plain Sprites around the perimeter (top + sides + bottom).
	# Spans the full 6x5 floor for a 1-tile-thick ring.
	var wall_tex: Texture2D = load(WALL_TILE) as Texture2D
	for x in GRID.x:
		# top wall
		var top := Sprite2D.new()
		top.texture = wall_tex
		top.centered = false
		top.position = Vector2(x * TILE, 0)
		add_child(top)
	for y in GRID.y:
		# left wall (skip top-left already covered), right wall (skip top-right)
		for x_off in [0, GRID.x]:
			var side := Sprite2D.new()
			side.texture = wall_tex
			side.centered = false
			side.position = Vector2(x_off * TILE - TILE, y * TILE)
			add_child(side)

func _register_self() -> void:
	# Interiors self-register with the same slots the outdoor area uses,
	# so scripts that read SignalBus.grid_manager / SignalBus.world_render
	# (e.g. FishingSpot/DeepCanalSpot/LotusMazeShoreSpot) keep working
	# without caring which area is current.
	SignalBus.grid_manager = self
	SignalBus.world_render = self

func _spawn_player() -> void:
	# TASK-352: same pending-warp lookup convention as World.gd — find
	# the door whose warp_id matches the pending value and place the player
	# at door + spawn_offset, then clear pending_warp_id.
	var player_scene: PackedScene = load("res://scenes/entities/Player.tscn")
	if player_scene == null:
		return
	var pl: Node2D = player_scene.instantiate() as Node2D
	if pl == null:
		return
	pl.name = "Player"
	add_child(pl)
	# TASK-357: a save/load restore takes precedence over door-warp
	# resolution — see World.gd's identical check for why. NOTE for the
	# planned InteriorBase.gd refactor (TASK-357): this check must be
	# carried over into the shared base, not dropped during extraction.
	if SignalBus.has_pending_load_position:
		pl.global_position = SignalBus.pending_load_position
		SignalBus.has_pending_load_position = false
	elif SignalBus.pending_warp_id != "":
		var door_node: Node = null
		for d in get_tree().get_nodes_in_group("door"):
			if d is Node2D and String((d as Node).get("warp_id")) == SignalBus.pending_warp_id:
				door_node = d
				break
		if door_node != null:
			pl.global_position = (door_node as Node2D).global_position + Vector2((door_node as Node).get("spawn_offset"))
		else:
			# No matching door (fresh boot into interior) — default to the
			# room's center so the player isn't clipped into a wall.
			pl.global_position = Vector2(3 * TILE, 3 * TILE)
		SignalBus.pending_warp_id = ""
	else:
		pl.global_position = Vector2(3 * TILE, 3 * TILE)

## BUGFIX (Code Quality Review): Player.gd's _try_grid_interact() and
## _mounted_interact_3x3() call gm.plant()/water()/harvest() DIRECTLY, with
## no has_method() guard (only get_plot() is guarded). Without these three
## methods, pressing interact anywhere inside the farmhouse — the very
## first thing a curious player would try — throws a GDScript runtime
## error ("Nonexistent function 'plant'"), since SignalBus.grid_manager
## points at this FarmHouse instance while inside. Keep the same
## "interior has no plantable soil" honesty the spec's is_plantable()/
## ground_at() already establish: soft-fail, never crash.
func plant(_cell: Vector2i, _crop: Resource) -> bool:
	return false

func water(_cell: Vector2i) -> bool:
	return false

func harvest(_cell: Vector2i) -> int:
	return 0

func is_plantable(_cell: Vector2i) -> bool:
	# Interior has no plantable soil — keep the GridManager contract honest
	# so any caller reading grid_manager.is_plantable() still gets a sane
	# answer (always false in here).
	return false

func ground_at(_cell: Vector2i) -> String:
	# WorldRender.gd's ground_at() contract — interiors always report
	# structure_floor regardless of cell (one tile type, no seasonal swap).
	return "structure_floor"