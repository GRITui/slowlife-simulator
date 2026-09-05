extends InteriorBase
## FarmHouse — TASK-352. The ONE proof-of-concept interior for the
## scene-transition foundation. Minimal: a 6x5-tile room with a static
## structure_floor + structure_wall tile render, a Player instanced as a
## child, and one Door back to the outdoor World.
##
## TASK-357: extends InteriorBase (the shared skeleton every interior
## uses) — _ready/_exit_tree/_register_self/_spawn_player/_place_player
## all live on the base now, not duplicated here. This file only owns
## the FarmHouse-specific render (the 6x5 tile room + walls), its
## default spawn point (room center), and the no-op plant/water/harvest
## contract (interiors have no plantable soil). Behavior is bit-for-bit
## preserved: the same door-warp resolution, the same
## has_pending_load_position precedence, the same default room-center
## fallback (3*TILE, 3*TILE) — now expressed as an override of
## InteriorBase's default_spawn export instead of a hardcoded literal
## in a duplicated _spawn_player().

const TILE: int = 48
const GRID: Vector2i = Vector2i(6, 5)
# Owner request (2026-09-05): distinct farmhouse interior look instead of
# the generic structure_floor/wall.png shared across every building's
# interior potential. Warm wood-plank floor + woven bamboo wall panel,
# generated via Draw Things (Transparent Image LoRA confirmed working
# this session, same pipeline as the exterior wall/furniture art).
const FLOOR_TILE: String = "res://assets/tilesets/farmhouse_floor.png"
const WALL_TILE: String = "res://assets/tilesets/farmhouse_wall_interior.png"
# TASK-355: extra furniture/decoration sprites so the room doesn't
# read as an empty box. Each points at an existing environment texture
# already in the project — no new art generated, just reused
# Thai-rural props (water jar, clay stove, white cloth, mo hom cloth).
# Loaded lazily inside _build_render() (not as consts) so a failed
# import in one texture doesn't block the whole scene from booting.
const DECOR_PATHS: Dictionary = {
	"water_jar": "res://assets/environment/water_jar.png",
	"clay_stove": "res://assets/environment/clay_stove.png",
	"pha_khao_ma": "res://assets/environment/pha_khao_ma.png",
	"mohom_cloth": "res://assets/environment/mohom_cloth.png",
}
# TASK-360: shrine decor style -> Sprite2D texture path. "basic" keeps
# the same weathered-wood wall front the existing FarmHouseShrine.tscn
# has used since TASK-355, so an unset choice is a visual no-op (the
# spec's "absence means default style" extends to visuals too — no
# flicker on first boot or after a save/load). "ornate" reuses
# mohom_cloth.png — the mo hom sarong hanging already used as decor
# elsewhere in this scene, a patterned Thai-rural cloth that's the
# closest existing asset to "decorated spirit-house" without needing
# new art. New styles append here AND in GameData.DECOR_CATALOGUE.
const SHRINE_STYLE_PATHS: Dictionary = {
	"basic": "res://assets/environment/structure_wall_front.png",
	"ornate": "res://assets/environment/mohom_cloth.png",
}
# TASK-367: bed decor style -> Sprite2D texture path. \"basic\" keeps
# the existing weathered-wood texture (pha_khao_ma.png) used as the bed
# default, so an unset choice is a visual no-op. \"ornate\" reuses
# mohom_cloth.png — the mo hom sarong hanging already used as decor
# elsewhere in this scene, a patterned Thai-rural cloth that's the
# closest existing asset to \"ornate\" bed styling without needing
# new art. New styles append here AND in GameData.DECOR_CATALOGUE.
const BED_STYLE_PATHS: Dictionary = {
	"basic": "res://assets/environment/pha_khao_ma.png",
	"ornate": "res://assets/environment/mohom_cloth.png",
}

@onready var _ground_layer: TileMapLayer = null

func _init() -> void:
	# GDScript doesn't allow redeclaring an inherited @export member, so
	# the room-center override happens here instead of a re-declaration —
	# runs before InteriorBase._ready() reads default_spawn.
	default_spawn = Vector2(3 * TILE, 3 * TILE)

func _build_render() -> void:
	# Interior's own minimal render — a single TileMapLayer with the floor
	# tileset, plus four wall sprite rows. NO outdoor ZONES/PROPS reuse —
	# interiors are a separate, much simpler shape (see spec Step 4).
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var src := TileSetAtlasSource.new()
	var floor_tex: Texture2D = load(FLOOR_TILE) as Texture2D
	src.texture = floor_tex
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
	# TASK-355: a few extra decoration sprites so the room doesn't read
	# as an empty box. Placed away from the bed (72, 72) and shrine
	# (216, 72) positions and away from the door at (144, 240) so the
	# walkable interior cells stay reachable. Failed texture loads are
	# silently skipped — better an empty room than a parse error.
	var decor_cells: Array = [
		# [name, column, row] — column/row in tile units, 0-indexed.
		["clay_stove", 4, 3],     # back-right corner, near the door
		["water_jar", 1, 4],      # bottom-left, against the back wall
		["mohom_cloth", 4, 4],    # bottom-right, mo hom sarong hanging
		["pha_khao_ma", 1, 3],    # left-center, white offering cloth
	]
	for cell in decor_cells:
		var key: String = cell[0]
		var path: String = DECOR_PATHS.get(key, "")
		if path == "":
			continue
		var decor_tex: Texture2D = load(path) as Texture2D
		if decor_tex == null:
			continue
		var sprite := Sprite2D.new()
		sprite.texture = decor_tex
		sprite.centered = false
		sprite.position = Vector2(int(cell[1]) * TILE, int(cell[2]) * TILE)
		add_child(sprite)
	# TASK-360: re-skin the shrine Sprite2D to match GameData.decor_choice().
	# Done LAST so the existing FarmHouseShrine.tscn-provided Sprite2D is
	# already a child of this scene (it is — instanced by FarmHouse.tscn's
	# "[node name=\"Shrine\"]" entry). Catches both first-boot defaults and
	# save/load round-trips (no Shrine-side change needed; GameData already
	# holds the persisted choice before _ready runs).
	_apply_shrine_style()
	# TASK-367: same re-skin-on-ready treatment for the bed slot.
	_apply_bed_style()
	# Listen for live style changes from the new style picker interactable
	# so re-skinning happens in real time without a scene reload.
	SignalBus.decor_style_changed.connect(_on_decor_style_changed)

func _apply_shrine_style() -> void:
	# Resolve the current style -> path, fall back to "basic" if the
	# catalogue has changed underneath us (defensive — should never happen
	# at runtime but keeps a future catalog edit from breaking the room).
	var shrine: Node = get_node_or_null("Shrine")
	if shrine == null:
		return
	var sprite: Sprite2D = shrine.get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	var style: String = GameData.decor_choice("shrine")
	var path: String = SHRINE_STYLE_PATHS.get(style, "")
	if path == "":
		path = String(SHRINE_STYLE_PATHS.get("basic", ""))
	if path == "":
		return
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		return
	sprite.texture = tex

func _apply_bed_style() -> void:
	# Resolve the current style -> path, fall back to "basic" if the
	# catalogue has changed underneath us (defensive — should never happen
	# at runtime but keeps a future catalog edit from breaking the room).
	var bed: Node = get_node_or_null("Bed")
	if bed == null:
		return
	var sprite: Sprite2D = bed.get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	var style: String = GameData.decor_choice("bed")
	var path: String = BED_STYLE_PATHS.get(style, "")
	if path == "":
		path = String(BED_STYLE_PATHS.get("basic", ""))
	if path == "":
		return
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		return
	sprite.texture = tex

func _on_decor_style_changed(slot: String, _style: String) -> void:
	# TASK-367: bed is now a second live slot alongside shrine. Future
	# slots (kitchen, etc.) extend this the same way.
	if slot == "shrine":
		_apply_shrine_style()
	elif slot == "bed":
		_apply_bed_style()

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