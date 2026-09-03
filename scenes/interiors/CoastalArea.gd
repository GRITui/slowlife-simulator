extends InteriorBase
## CoastalArea — TASK-357. Second InteriorBase subclass (the Phase-1
## proof-of-concept split from World.tscn). Carves out the eastern cluster
## — CoastalTradingPost, SacredGrove, and the static CarpenterUpgrade
## building — into a small satellite outdoor-feeling area reachable by
## walking off World.tscn's east edge.
##
## Mirrors FarmHouse.gd's "interior that just builds its own minimal
## render and the rest of the skeleton lives on InteriorBase" pattern.
## The two dynamic spots (_ensure_coastal_trading_post, _ensure_sacred_grove)
## preserve their original World.gd gating logic — the lifetime_items_shipped
## >= 200 and companion_bond_tier >= 10 checks move verbatim so a loaded save
## that had the spot before this task lands it the same way after. Each is
## called once here from _build_render() (covers loaded-save boot) and
## once again from _on_minute_ticked_unlocks() (covers a freshly-met gate
## in-session, same shape as World's existing handler).
##
## CarpenterUpgrade moves from World.tscn as a STATIC instanced child
## (see CoastalArea.tscn) — same way it lived under World.tscn before.

const TILE: int = 48
const GRID: Vector2i = Vector2i(5, 5)
const GROUND_TILE: String = "res://assets/tilesets/ground_grass.png"

func _init() -> void:
	# GDScript doesn't allow redeclaring an inherited @export member, so
	# the per-area default spawn override happens here instead of a
	# re-declaration — runs before InteriorBase._ready() reads default_spawn.
	# The west-edge EdgeTransition sets SignalBus.edge_carry_value and the
	# matching incoming edge reads it (via InteriorBase._spawn_player),
	# so in practice most arrivals land at the carried Y, not this default.
	# This is the fresh-boot-into-CoastalArea-with-no-warp fallback.
	default_spawn = Vector2(1 * TILE + TILE / 2.0, 2 * TILE + TILE / 2.0)

func _build_render() -> void:
	# Plain ground_grass tile fill, same simple approach as FarmHouse's
	# tile room — a single TileMapLayer + atlas source. 5x5 is wide enough
	# to fit the three relocated objects (CoastalTradingPost at local
	# tile (1,2), SacredGroveSpot at local tile (3,2), CarpenterUpgrade
	# at local tile (2,4)) plus room to walk to/from the west-edge
	# EdgeTransition at local x=0.
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var src := TileSetAtlasSource.new()
	var tex: Texture2D = load(GROUND_TILE) as Texture2D
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
	# Carry over the dynamic-spawn logic from World.gd's
	# _ensure_coastal_trading_post() and _ensure_sacred_grove() — same
	# gating (lifetime_items_shipped >= 200, companion_bond_tier >= 10),
	# same idempotent get_node_or_null check, same positions relative to
	# the area's local origin. The world-coordinate position vectors
	# below are the original author's verified-clear (16,6) and (19,6)
	# cells; with the area rendered as a single 5x5 ground tile the
	# objects are guaranteed to live inside the area's bounds because
	# the cells are placed relative to the CoastalArea root (which IS
	# the local origin) — i.e. position.y = 6*48 places the object 6 tiles
	# below the area root, well within visual reach of the ground render.
	_ensure_coastal_trading_post()
	_ensure_sacred_grove()
	# Subscribe to minute_ticked so a freshly-met gate unlocks the spot
	# without a reload — same pattern as World.gd's
	# _on_minute_ticked_unlocks(), just for THIS area's two spots.
	SignalBus.minute_ticked.connect(_on_minute_ticked_unlocks)

func _exit_tree() -> void:
	# Disconnect the per-area minute_ticked handler so a CoastalArea
	# unload doesn't leak the signal subscription. InteriorBase._exit_tree
	# already clears SignalBus.grid_manager / SignalBus.world_render.
	if SignalBus.minute_ticked.is_connected(_on_minute_ticked_unlocks):
		SignalBus.minute_ticked.disconnect(_on_minute_ticked_unlocks)
	super._exit_tree()

func _on_minute_ticked_unlocks(_day: int, _hour: int, _minute: int) -> void:
	# CoastalArea's own lazy unlock poll, same shape as World.gd's.
	# Only the two spots that live here; MountainCave/DeepCanal/etc stay
	# under World's handler (they're not in this area).
	_ensure_coastal_trading_post()
	_ensure_sacred_grove()

func _ensure_coastal_trading_post() -> void:
	# TASK-344: gated on GameData.lifetime_items_shipped >= 200 — the
	# same threshold as stamina_tier 4 (cap), framing this as the
	# natural capstone of the shipping economy. Derive the unlock state
	# live each call — no persisted flag, no schema bump. Called once
	# from _build_render() (covers loaded-save boot) and again from the
	# minute_ticked handler (covers freshly-met gate in-session).
	# TASK-357: moved from World.gd as part of the Phase-1 cluster split;
	# gating logic preserved verbatim. Position is now area-local
	# (tile 1, 2) — the original World-coord (16,6) verified-clear cell
	# reframed against CoastalArea's 5x5 ground render. Two tiles from
	# the west edge so the incoming EdgeTransition's player doesn't
	# spawn directly on top of the trading post.
	if int(GameData.lifetime_items_shipped) < 200:
		return
	if get_node_or_null("CoastalTradingPost") != null:
		return
	var script: GDScript = load("res://scripts/interactables/CoastalTradingPost.gd")
	if script == null:
		return
	var spot: Node2D = script.new() as Node2D
	if spot == null:
		return
	spot.name = "CoastalTradingPost"
	spot.position = Vector2(1 * TILE + TILE / 2.0, 2 * TILE + TILE / 2.0)
	add_child(spot)

func _ensure_sacred_grove() -> void:
	# TASK-343 / TASK-348: gated on GameData.companion_bond_tier() >= 10
	# (the cap, same threshold as the inseparable milestone). Derive
	# the unlock state live each call. TASK-357: moved from World.gd as
	# part of the Phase-1 cluster split; gating logic preserved verbatim.
	# Position is now area-local (tile 3, 2) — across from the trading
	# post on the east side of the area's 5x5 ground render.
	if GameData.companion_bond_tier() < 10:
		return
	if get_node_or_null("SacredGroveSpot") != null:
		return
	var script: GDScript = load("res://scripts/interactables/SacredGroveSpot.gd")
	if script == null:
		return
	var spot: Node2D = script.new() as Node2D
	if spot == null:
		return
	spot.name = "SacredGroveSpot"
	spot.position = Vector2(3 * TILE + TILE / 2.0, 2 * TILE + TILE / 2.0)
	add_child(spot)

## BUGFIX (per FarmHouse.gd's same-shape lesson): Player.gd's
## _try_grid_interact() / _mounted_interact_3x3() call gm.plant()/
## water()/harvest() DIRECTLY with no has_method() guard. Without these
## three methods, pressing interact inside CoastalArea throws a runtime
## error since SignalBus.grid_manager points at this instance while
## inside. CoastalArea's three nodes don't have plantable soil either —
## soft-fail, never crash.
func plant(_cell: Vector2i, _crop: Resource) -> bool:
	return false

func water(_cell: Vector2i) -> bool:
	return false

func harvest(_cell: Vector2i) -> int:
	return 0

func is_plantable(_cell: Vector2i) -> bool:
	# No plantable soil in this outdoor-feeling coastal area — the
	# ground_grass tile is for walking, not planting. Mirrors the
	# FarmHouse.gd interior convention; the outdoor World scene uses
	# its real WorldRender-driven ground_at() / is_plantable() instead.
	return false

func ground_at(_cell: Vector2i) -> String:
	# WorldRender.gd's ground_at() contract — CoastalArea's rendered
	# ground is uniform ground_grass (one tile type), so this is the
	# whole report regardless of cell.
	return "ground_grass"