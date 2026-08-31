extends Node2D
var _cached_ring: Node2D = null
var _cached_bounds: Node = null
# WorldRender — TASK-007 world render, Hybrid A/B (Isan 20x16 plain + 3x3 lotus maze)
# Data-driven: zone matrix + prop table below. Builds into parent (Main):
#   Backdrop (Deep Pond #1565C0) -> GroundLayer (flat 32x32) -> WaterOverlay ->
#   BambooRing (edge dressing, 1 tile outside map) -> standing props (direct Main
#   children so Main.y_sort_enabled sorts them with Player/MonkNPC) -> Bounds.
# 3/4 canon REV 2: ground flat, verticals tall art, sort origin at feet/base.

const TILE: int = 48
const GRID: Vector2i = Vector2i(20, 16)
const DEEP_POND := Color("#1565C0")

const GROUND_TILES := {
	"ground_grass": "res://assets/tilesets/ground_grass.png",
	"ground_dryearth": "res://assets/tilesets/ground_dryearth.png",
	"plantable_soil": "res://assets/tilesets/plantable_soil.png",
	"structure_floor": "res://assets/tilesets/structure_floor.png",
	"canal": "res://assets/tilesets/canal.png",
	"water_lotuspond": "res://assets/tilesets/water_lotuspond.png",
	"lotus_maze": "res://assets/environment/lotus_maze.png",
	"dock": "res://assets/environment/dock.png",
	"deep_pond": "", # runtime-generated solid #1565C0
}

# Zone matrix (later zones override earlier). rects are Rect2i(x, y, w, h) in cells.
const ZONES := [
	{"name": "pasture", "tile": "ground_grass", "rect": Rect2i(0, 10, 9, 6)},
	{"name": "dryearth_patch_w", "tile": "ground_dryearth", "rect": Rect2i(0, 10, 2, 1)},
	{"name": "dryearth_patch_e", "tile": "ground_dryearth", "rect": Rect2i(7, 12, 2, 2)},
	{"name": "lotus_pond", "tile": "water_lotuspond", "rect": Rect2i(0, 0, 5, 4)},
	{"name": "temple_yard", "tile": "structure_floor", "rect": Rect2i(17, 0, 3, 3)},
	{"name": "temple_lane", "tile": "structure_floor", "rect": Rect2i(15, 3, 5, 1)},
	{"name": "home", "tile": "structure_floor", "rect": Rect2i(0, 4, 3, 5)},
	{"name": "hall_floor", "tile": "structure_floor", "rect": Rect2i(6, 14, 3, 2)},
	{"name": "paddy_core", "tile": "plantable_soil", "rect": Rect2i(3, 4, 14, 6)},
	{"name": "paddy_south", "tile": "plantable_soil", "rect": Rect2i(9, 10, 5, 3)},
	{"name": "canal_row", "tile": "canal", "rect": Rect2i(9, 13, 8, 1)},
	{"name": "lotus_maze_islet", "tile": "deep_pond", "rect": Rect2i(14, 10, 3, 3)},
]

# Standing props. kinds: "wall" (32x48 front, base at cell bottom edge),
# "cap" (32x16 roof cap, sits on wall top), "prop" (tall art, base at cell bottom).
const PROPS := [
	# Temple facade E (front row y=2 on yard, caps y=1)
	{"tex": "res://assets/environment/structure_wall_front.png", "cell": Vector2i(17, 2), "kind": "wall"},
	{"tex": "res://assets/environment/structure_wall_front.png", "cell": Vector2i(18, 2), "kind": "wall"},
	{"tex": "res://assets/environment/structure_wall_front.png", "cell": Vector2i(19, 2), "kind": "wall"},
	{"tex": "res://assets/environment/structure_wall_cap.png", "cell": Vector2i(17, 1), "kind": "cap"},
	{"tex": "res://assets/environment/structure_wall_cap.png", "cell": Vector2i(18, 1), "kind": "cap"},
	{"tex": "res://assets/environment/structure_wall_cap.png", "cell": Vector2i(19, 1), "kind": "cap"},
	# Home hut W (front row y=8 on home floor, caps y=7)
	{"tex": "res://assets/environment/structure_wall_front.png", "cell": Vector2i(0, 8), "kind": "wall"},
	{"tex": "res://assets/environment/structure_wall_front.png", "cell": Vector2i(1, 8), "kind": "wall"},
	{"tex": "res://assets/environment/structure_wall_front.png", "cell": Vector2i(2, 8), "kind": "wall"},
	{"tex": "res://assets/environment/structure_wall_cap.png", "cell": Vector2i(0, 7), "kind": "cap"},
	{"tex": "res://assets/environment/structure_wall_cap.png", "cell": Vector2i(1, 7), "kind": "cap"},
	{"tex": "res://assets/environment/structure_wall_cap.png", "cell": Vector2i(2, 7), "kind": "cap"},
	# Village hall S (front row y=15, caps y=14)
	{"tex": "res://assets/environment/structure_wall_front.png", "cell": Vector2i(6, 15), "kind": "wall"},
	{"tex": "res://assets/environment/structure_wall_front.png", "cell": Vector2i(7, 15), "kind": "wall"},
	{"tex": "res://assets/environment/structure_wall_front.png", "cell": Vector2i(8, 15), "kind": "wall"},
	{"tex": "res://assets/environment/structure_wall_cap.png", "cell": Vector2i(6, 14), "kind": "cap"},
	{"tex": "res://assets/environment/structure_wall_cap.png", "cell": Vector2i(7, 14), "kind": "cap"},
	{"tex": "res://assets/environment/structure_wall_cap.png", "cell": Vector2i(8, 14), "kind": "cap"},
	# Maze add-ons: sluice now interactive via scenes/interactables/SluiceGate.tscn (TASK-011) — skip static prop
	# {"tex": "res://assets/environment/sluice_gate_tall.png", "cell": Vector2i(15, 13), "kind": "prop"},
	{"tex": "res://assets/environment/mango_tree_tall.png", "cell": Vector2i(17, 10), "kind": "prop"},
	{"tex": "res://assets/environment/banana_tree_tall.png", "cell": Vector2i(4, 12), "kind": "prop"},
	{"tex": "res://assets/environment/banana_tree_tall.png", "cell": Vector2i(5, 13), "kind": "prop"},
	{"tex": "res://assets/environment/banana_tree_tall.png", "cell": Vector2i(3, 13), "kind": "prop"},
	# Central cooking hearth beside home
	{"tex": "res://assets/environment/clay_stove_tall.png", "cell": Vector2i(2, 9), "kind": "prop"},
]

# Flat decor (grass-level, never y-sorted): bamboo thicket accents in pasture.
const FLAT_DECOR := [
	{"tex": "res://assets/environment/bamboo_thicket.png", "cell": Vector2i(1, 12)},
	{"tex": "res://assets/environment/bamboo_thicket.png", "cell": Vector2i(7, 15)},
]

const MAZE_ORIGIN: Vector2i = Vector2i(14, 10)
const DOCK_CELL: Vector2i = Vector2i(13, 13)

var _source_names := {} # source_id -> tile name
var _ground_layer: TileMapLayer
var _deep_tex: ImageTexture
var _main: Node2D

# Called from Main._ready (after children are readied — Godot blocks child->parent
# add_child during setup, so the build is driven by the parent, not our _ready).
func build(main: Node2D) -> void:
	_main = main
	_build_backdrop(main)
	_build_ground(main)
	_build_water_overlay(main)
	_build_flat_decor(main)
	_build_bamboo_ring(main)
	_build_props(main)
	_build_bounds(main)

# --- Query API (used by tests + future spatial squads) ---

func ground_at(cell: Vector2i) -> String:
	if _ground_layer == null:
		return ""
	var sid: int = _ground_layer.get_cell_source_id(cell)
	return _source_names.get(sid, "")

var _ring_tiles: int = 0 # TASK-031: baked ring tile count (test parity for ring_count)
var _water_mat: ShaderMaterial = null # TASK-032 seasonal water material
var _season_connected: bool = false

const _SEASON_INDEX := {"hot": 0.0, "monsoon": 1.0, "cool": 2.0}

func _apply_season_to_water(season: String) -> void:
	if _water_mat == null:
		return
	_water_mat.set_shader_parameter("season_index", float(_SEASON_INDEX.get(season, 2.0)))

func _on_season_for_water(season: String) -> void:
	_apply_season_to_water(season)

# TASK-032: vertex-only sway for the baked ring + tall organic props.
# Per-sprite material duplicates carry a unique phase (no instance uniforms
# on the compatibility 2D renderer). Caps are skipped (rigid stone/wood).
func _attach_sway(sprite: Sprite2D, phase: float) -> void:
	var mat: ShaderMaterial = (load("res://assets/shaders/foliage_sway.tres") as ShaderMaterial).duplicate()
	mat.set_shader_parameter("phase", phase)
	sprite.material = mat

func ring_count() -> int:
	# Baked single-sprite ring (TASK-031): report baked tile count instead of
	# child count; legacy child-based fallback kept for safety.
	if _ring_tiles > 0:
		return _ring_tiles
	var ring := _main.get_node_or_null("BambooRing") as Node2D
	return ring.get_child_count() if ring else 0

func prop_count() -> int:
	var n: int = 0
	if _main == null:
		return 0
	for c in _main.get_children():
		if c is Sprite2D and c.get_meta("worldrender_prop", false):
			n += 1
	return n

func maze_cells() -> Array:
	var out := []
	for dy in 3:
		for dx in 3:
			out.append(MAZE_ORIGIN + Vector2i(dx, dy))
	return out

# --- Builders ---

func _build_backdrop(main: Node) -> void:
	var bd := Polygon2D.new()
	bd.name = "Backdrop"
	bd.z_index = -30
	bd.color = DEEP_POND
	bd.polygon = PackedVector2Array([
		Vector2(-TILE * 10, -TILE * 8), Vector2(TILE * (GRID.x + 10), -TILE * 8),
		Vector2(TILE * (GRID.x + 10), TILE * (GRID.y + 9)), Vector2(-TILE * 10, TILE * (GRID.y + 9)),
	])
	main.add_child(bd)

func _build_ground(main: Node) -> void:
	var ts := _make_tileset()
	var layer := TileMapLayer.new()
	layer.name = "GroundLayer"
	layer.z_index = -20
	layer.tile_set = ts
	for y in GRID.y:
		for x in GRID.x:
			var cell := Vector2i(x, y)
			layer.set_cell(cell, _source_id_for(_zone_tile_at(cell)), Vector2i(0, 0))
	main.add_child(layer)
	_ground_layer = layer

func _build_water_overlay(main: Node) -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var names := ["lotus_maze", "dock"]
	var sids := {}
	for t_name in names:
		var src := TileSetAtlasSource.new()
		src.texture = load(GROUND_TILES[t_name]) as Texture2D
		src.texture_region_size = Vector2i(TILE, TILE)
		src.create_tile(Vector2i(0, 0))
		sids[t_name] = ts.add_source(src, -1)
	var layer := TileMapLayer.new()
	layer.name = "WaterOverlay"
	layer.z_index = -14
	layer.tile_set = ts
	# TASK-032: seasonal water tint — single shared material, one uniform write
	# per season change (SignalBus.season_changed), no per-frame cost.
	var water_mat: ShaderMaterial = load("res://assets/shaders/water_seasonal.tres") as ShaderMaterial
	if water_mat != null:
		layer.material = water_mat
		_water_mat = water_mat
		if not _season_connected:
			SignalBus.season_changed.connect(_on_season_for_water)
			_season_connected = true
		_apply_season_to_water(GameData.current_season)
	for cell in maze_cells():
		layer.set_cell(cell, sids["lotus_maze"], Vector2i(0, 0))
	layer.set_cell(DOCK_CELL, sids["dock"], Vector2i(0, 0))
	main.add_child(layer)

func _build_flat_decor(main: Node) -> void:
	for d in FLAT_DECOR:
		var s := _flat_sprite(d["tex"], d["cell"])
		s.z_index = -5
		main.add_child(s)

func _build_bamboo_ring(main: Node) -> void:
	# TASK-031 perf budget: bake all 76 ring tiles into ONE ImageTexture so
	# the ring costs a single draw call (was 76 individual Sprite2D draws —
	# the dominant offender in the idle draw-call audit). Pixel-identical:
	# each 32x48 tile is blitted at the same cell-relative offset the old
	# _base_sprite produced (centered horizontally in the 48px cell).
	var src_tex: Texture2D = load("res://assets/environment/bamboo_wall_tall.png")
	var src_img: Image = src_tex.get_image()
	if src_img != null:
		src_img.convert(Image.FORMAT_RGBA8)
		var canvas: Image = Image.create((GRID.x + 2) * TILE, (GRID.y + 2) * TILE, false, Image.FORMAT_RGBA8)
		var tw: int = src_img.get_width()
		var th: int = src_img.get_height()
		var x_off: int = (TILE - tw) / 2
		_ring_tiles = 0
		for x in range(-1, GRID.x + 1):
			for y in [-1, GRID.y]:
				canvas.blit_rect(src_img, Rect2i(0, 0, tw, th), Vector2i((x + 1) * TILE + x_off, (y + 1) * TILE))
				_ring_tiles += 1
		for y in range(0, GRID.y):
			for x in [-1, GRID.x]:
				canvas.blit_rect(src_img, Rect2i(0, 0, tw, th), Vector2i((x + 1) * TILE + x_off, (y + 1) * TILE))
				_ring_tiles += 1
		var ring := Sprite2D.new()
		ring.name = "BambooRing"
		ring.z_index = -5
		ring.texture = ImageTexture.create_from_image(canvas)
		ring.centered = false
		# Canvas px (0,0) is world cell (-1,-1) top-left == (-TILE, -TILE).
		ring.position = Vector2(-TILE, -TILE)
		# TASK-032: crown-weighted sway on the whole baked ring (1 material).
		_attach_sway(ring, 0.0)
		main.add_child(ring)

func _build_props(main: Node) -> void:
	for p in PROPS:
		var tex: Texture2D = load(p["tex"])
		var s := Sprite2D.new()
		s.texture = tex
		var base := Vector2(p["cell"].x * TILE + TILE / 2.0, (p["cell"].y + 1) * float(TILE))
		match p["kind"]:
			"cap":
				# cap sits on wall top: spans one tile above the wall boundary,
				# height derived from the texture so it works at any TILE/art scale.
				var cap_half := tex.get_height() / 2.0
				s.position = Vector2(base.x, (p["cell"].y + 1) * float(TILE) - cap_half)
				s.offset = Vector2(0, -cap_half)
			_:
				s.position = base
				s.offset = Vector2(0, -tex.get_height() / 2.0)
		s.set_meta("worldrender_prop", true)
		# TASK-032: sway tall organic props only; caps stay rigid.
		if p["kind"] != "cap":
			_attach_sway(s, float((p["cell"].x + p["cell"].y) % 7) * 0.9)
		main.add_child(s)

func _build_bounds(main: Node) -> void:
	var body := StaticBody2D.new()
	body.name = "Bounds"
	var half := TILE / 2.0
	var walls := [
		{"center": Vector2(GRID.x * half, -half), "size": Vector2((GRID.x + 2) * float(TILE), float(TILE))}, # top
		{"center": Vector2(GRID.x * half, GRID.y * float(TILE) + half), "size": Vector2((GRID.x + 2) * float(TILE), float(TILE))}, # bottom
		{"center": Vector2(-half, GRID.y * half), "size": Vector2(float(TILE), (GRID.y + 2) * float(TILE))}, # left
		{"center": Vector2(GRID.x * float(TILE) + half, GRID.y * half), "size": Vector2(float(TILE), (GRID.y + 2) * float(TILE))}, # right
	]
	for w in walls:
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = w["size"]
		cs.shape = shape
		cs.position = w["center"]
		body.add_child(cs)
	main.add_child(body)

# --- Helpers ---

func _zone_tile_at(cell: Vector2i) -> String:
	var tile := "ground_grass" # base: Isan plain grass
	for z in ZONES:
		if (z["rect"] as Rect2i).has_point(cell):
			tile = z["tile"]
	return tile

func _make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	for t_name in GROUND_TILES:
		var tex: Texture2D
		if t_name == "deep_pond":
			tex = _deep_pond_texture()
		else:
			tex = load(GROUND_TILES[t_name]) as Texture2D
		var src := TileSetAtlasSource.new()
		src.texture = tex
		src.texture_region_size = Vector2i(TILE, TILE)
		src.create_tile(Vector2i(0, 0))
		var sid: int = ts.add_source(src, -1)
		_source_names[sid] = t_name
	return ts

func _source_id_for(t_name: String) -> int:
	for sid in _source_names:
		if _source_names[sid] == t_name:
			return sid
	return -1

func _deep_pond_texture() -> ImageTexture:
	if _deep_tex == null:
		var img := Image.create(TILE, TILE, false, Image.FORMAT_RGB8)
		img.fill(DEEP_POND)
		_deep_tex = ImageTexture.create_from_image(img)
	return _deep_tex

func _base_sprite(tex: Texture2D, cell: Vector2i) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.position = Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * float(TILE))
	s.offset = Vector2(0, -tex.get_height() / 2.0)
	return s

func _flat_sprite(tex_path: String, cell: Vector2i) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(tex_path) as Texture2D
	s.position = Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE / 2.0)
	return s
