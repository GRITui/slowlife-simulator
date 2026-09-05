extends Node2D
## FarmHouseFurniture — TASK-374 Phase 1 + TASK-375 Phase 2. Toggleable
## furniture placement for FarmHouse's interior only.
##
## TASK-374 Phase 1: one item (floor_rug), no rotation.
## TASK-375 Phase 2: 4-direction rotation (T), two new items
## (floor_cushion, small_table), and a session-only "primed" item
## selection (Y) that cycles through OWNED furniture item ids only --
## mirrors TASK-350's _primed_seed_id pattern exactly (third reuse of
## the same shape in this codebase: seeds TASK-350, fishing gear
## TASK-359, furniture TASK-375).
##
## Design: press toggle_furniture_place_mode (F) to enter/exit place
## mode. While active, pressing interact places or picks up the primed
## item at the PLAYER'S OWN current cell -- same convention Player.gd's
## outdoor _try_grid_interact() already uses (floor(global_position /
## TILE)), not mouse-position targeting (this project has no
## mouse-driven UI convention; it's an iOS touch/keyboard target).
## Pressing rotate_furniture (T) while standing on a placed piece
## rotates it 90° clockwise (0->1->2->3->0 wraparound). Pressing
## cycle_furniture_item (Y) cycles which owned item is "primed" for
## the next place action. A player who never touches T or Y sees zero
## behavior change from Phase 1: _primed_furniture_id defaults to ""
## so the place/pickup branch falls back to floor_rug (the Phase 1
## default), and rotation only ever touches existing entries.
##
## Persistence: GameData.placed_furniture (location_id "farmhouse" ->
## Array<{item_id, cell, facing}>), additive, no SAVE_VERSION bump.
## `facing` is a 0..3 rotation index (0=0°, 1=90°, 2=180°, 3=270°).
## Old Phase 1 saves have entries without a `facing` key; every read
## site defends with `entry.get("facing", 0)` so the runtime contract
## is unchanged for them (see GameData.placed_furniture's own comment
## for the no-bump reasoning).

const TILE: int = 48
const GRID: Vector2i = Vector2i(6, 5)
const LOCATION_ID: String = "farmhouse"
const RUG_ITEM_ID: String = "floor_rug"

# TASK-375: item_id -> short display name used as the sprite node-name
# prefix (so "Rug_2_2" / "Cushion_2_2" / "Table_2_2" can coexist on
# the same grid without node-name collisions and the same sprite node
# can be looked up by either name). Texture paths are defined inline
# at the spawn site below -- this dict owns the node-name side only.
const DISPLAY_NAMES: Dictionary = {
	"floor_rug": "Rug",
	"floor_cushion": "Cushion",
	"small_table": "Table",
}

# Cells already occupied by other FarmHouse interactables (from
# FarmHouse.tscn's own node positions) — never a valid placement target.
const OCCUPIED_CELLS: Array = [
	Vector2i(3, 5),  # OutsideDoor (144, 240)
	Vector2i(1, 1),  # Bed (72, 72)
	Vector2i(4, 1),  # Shrine (216, 72)
	Vector2i(5, 2),  # ShrineStylePicker (264, 120)
	Vector2i(1, 2),  # BedStylePicker (72, 120) -- TASK-367
]

var _place_mode: bool = false

# TASK-375: session-only "primed" furniture item for the next place
# action. Mirrors Player.gd's _primed_seed_id (TASK-350). Lives on
# this script (not GameData) so it isn't accidentally serialized by
# SaveManager. Defaults to "" so a player who never presses Y is
# bit-for-bit unchanged from Phase 1: the place/pickup branch falls
# back to RUG_ITEM_ID when this is empty.
var _primed_furniture_id: String = ""

@onready var _hint: Label = $PlaceModeHint if has_node("PlaceModeHint") else null

func _ready() -> void:
	SignalBus.placed_furniture_changed.connect(_on_furniture_changed)
	_refresh_rugs()
	_update_hint()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_furniture_place_mode"):
		_place_mode = not _place_mode
		_update_hint()
		SignalBus.show_dialogue.emit("Farmer", "Place mode: %s." % ("on" if _place_mode else "off"))
		get_viewport().set_input_as_handled()
		return
	if not _place_mode:
		return
	if event.is_action_pressed("cycle_furniture_item"):
		_try_cycle_primed_furniture()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("rotate_furniture"):
		_try_rotate()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact"):
		_try_place_or_pickup()
		get_viewport().set_input_as_handled()

func _update_hint() -> void:
	if _hint:
		_hint.visible = _place_mode
		_hint.text = "Place mode — [E] place/pick up, [T] rotate, [Y] cycle item, [F] exit"

func _player_cell() -> Vector2i:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return Vector2i(-1, -1)
	var local_pos: Vector2 = player.global_position - global_position
	return Vector2i(floori(local_pos.x / TILE), floori(local_pos.y / TILE))

func _is_valid_cell(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= GRID.x or cell.y >= GRID.y:
		return false
	return cell not in OCCUPIED_CELLS

func _try_place_or_pickup() -> void:
	var cell: Vector2i = _player_cell()
	if not _is_valid_cell(cell):
		SignalBus.show_dialogue.emit("Farmer", "Can't place a rug there.")
		return

	if GameData.has_placed_furniture_at(LOCATION_ID, cell):
		var entry: Dictionary = GameData.get_placed_furniture_at(LOCATION_ID, cell)
		var entry_item_id: String = String(entry.get("item_id", ""))
		if GameData.remove_placed_furniture(LOCATION_ID, entry_item_id, cell):
			GameData.add_item(entry_item_id, 1)
			SignalBus.show_dialogue.emit("Farmer", "Picked up the %s." %
				_display_name_for(entry_item_id).to_lower())
		return

	var item_id: String = _active_furniture_id()
	if not GameData.has_item(item_id, 1):
		# Soft-fail with the item's real name so the message makes
		# sense after the player starts cycling (Phase 1's "You don't
		# have a floor rug" line would be wrong for cushion/table).
		SignalBus.show_dialogue.emit("Farmer", "You don't have a %s to place." %
			_display_name_for(item_id).to_lower())
		return

	GameData.remove_item(item_id, 1)
	GameData.add_placed_furniture(LOCATION_ID, item_id, cell)
	SignalBus.show_dialogue.emit("Farmer", "Placed a %s." %
		_display_name_for(item_id).to_lower())

# TASK-375: which item a press of [E] will try to place / pick up.
# Returns _primed_furniture_id when it's set AND the player still owns
# >=1 of it (the cycle path always re-primes from owned items, so
# this is the common condition), otherwise falls back to floor_rug --
# the Phase 1 default that preserves behavior for a player who never
# touches the cycle action.
func _active_furniture_id() -> String:
	if _primed_furniture_id != "" and GameData.has_item(_primed_furniture_id, 1):
		return _primed_furniture_id
	return RUG_ITEM_ID

# TASK-375: rotate the piece the player is standing on, 90° clockwise.
# Wraps 0->1->2->3->0. Soft-fails with a dialogue line when the cell
# is empty (no exception, matching _try_place_or_pickup()'s tone for
# an invalid cell).
func _try_rotate() -> void:
	var cell: Vector2i = _player_cell()
	if not GameData.has_placed_furniture_at(LOCATION_ID, cell):
		SignalBus.show_dialogue.emit("Farmer", "Nothing to rotate here.")
		return
	var entry: Dictionary = GameData.get_placed_furniture_at(LOCATION_ID, cell)
	var current: int = int(entry.get("facing", 0))
	var new_facing: int = GameData.set_placed_furniture_facing(LOCATION_ID, cell, current + 1)
	if new_facing < 0:
		# Shouldn't be reachable (the has_placed_furniture_at check
		# above passes), but keep the soft-fail shape for safety.
		SignalBus.show_dialogue.emit("Farmer", "Nothing to rotate here.")
		return
	SignalBus.show_dialogue.emit("Farmer", "Rotated to %d°." % (new_facing * 90))

# TASK-375: cycle which owned furniture item is "primed" for the next
# place action. Same sorted-iteration / wrap-around / "no items" shape
# as Player.cycle_primed_seed() (TASK-350) and any future gear cycle
# (TASK-359) -- session-only state, deterministic order.
func _try_cycle_primed_furniture() -> void:
	var owned: Array[String] = []
	for item_id: String in DISPLAY_NAMES.keys():
		if GameData.has_item(String(item_id), 1):
			owned.append(String(item_id))
	owned.sort() # deterministic, not Dictionary iteration order
	if owned.is_empty():
		_primed_furniture_id = ""
		SignalBus.show_dialogue.emit("Farmer", "No furniture to place.")
		return
	var idx: int = owned.find(_primed_furniture_id)
	_primed_furniture_id = owned[(idx + 1) % owned.size()]
	SignalBus.show_dialogue.emit("Farmer", "Furniture selected: %s." %
		_display_name_for(_primed_furniture_id))

func _display_name_for(item_id: String) -> String:
	# Returns the short display name ("Rug" / "Cushion" / "Table") for
	# dialogue + sprite-node-name use. Falls back to a title-cased
	# derivation so an unrecognized item id still produces a reasonable
	# line ("Floor_rug" -> "Floor Rug").
	if DISPLAY_NAMES.has(item_id):
		return String(DISPLAY_NAMES[item_id])
	var parts: PackedStringArray = item_id.split("_")
	var out: String = ""
	for part: String in parts:
		if part == "":
			continue
		if out != "":
			out += " "
		out += part.capitalize()
	return out if out != "" else item_id

func _texture_path_for(item_id: String) -> String:
	# TASK-375: per-item texture lookup. floor_rug keeps the existing
	# mohom_cloth.png (Phase 1's choice). floor_cushion reuses
	# pha_khao_ma.png -- a second existing cloth texture in
	# assets/environment/ (also used as the bed's "basic" decor).
	# small_table reuses clay_stove.png -- nothing table-shaped exists
	# in assets/environment/ or props/, so we follow this project's
	# established placeholder-art precedent (e.g. the tiny invisible
	# Sprite2D convention in FarmHouseShrineStylePicker.tscn) and pick
	# the closest neutral furniture-shaped prop already in the project.
	match item_id:
		"floor_rug": return "res://assets/environment/mohom_cloth.png"
		"floor_cushion": return "res://assets/environment/pha_khao_ma.png"
		"small_table": return "res://assets/environment/clay_stove.png"
	return "res://assets/environment/mohom_cloth.png"

func _on_furniture_changed(location_id: String, item_id: String, cell: Vector2i, is_placed: bool) -> void:
	if location_id != LOCATION_ID:
		return
	var sprite_name: String = "%s_%d_%d" % [_display_name_for(item_id), cell.x, cell.y]
	# Resolve the current facing for this cell (if any). Used to
	# (re)apply rotation_degrees whenever the sprite (re)spawns --
	# whether it's the first place, a pickup-then-replace cycle, or
	# the rotation itself (which re-emits the placed signal).
	var facing: int = 0
	if is_placed:
		var entry: Dictionary = GameData.get_placed_furniture_at(LOCATION_ID, cell)
		facing = int(entry.get("facing", 0))
	if is_placed:
		if has_node(sprite_name):
			# Already live (rotation re-emit, or refresh) -- just
			# update rotation_degrees in case it changed.
			var existing: Sprite2D = get_node(sprite_name) as Sprite2D
			if existing != null:
				existing.rotation_degrees = float(facing) * 90.0
			return
		var sprite := Sprite2D.new()
		sprite.name = sprite_name
		sprite.texture = load(_texture_path_for(item_id))
		sprite.position = Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE / 2.0)
		sprite.rotation_degrees = float(facing) * 90.0
		add_child(sprite)
	else:
		if has_node(sprite_name):
			get_node(sprite_name).queue_free()

func _refresh_rugs() -> void:
	# Re-materialize any furniture already placed (e.g. loaded from a
	# save) that doesn't have a live sprite yet. The signal handler
	# does the actual spawn; we just drive it with the persisted data
	# so old saves re-appear at the right rotation.
	var list: Array = GameData.placed_furniture.get(LOCATION_ID, [])
	for entry: Dictionary in list:
		_on_furniture_changed(LOCATION_ID, String(entry.get("item_id", "")), entry.get("cell", Vector2i.ZERO), true)
