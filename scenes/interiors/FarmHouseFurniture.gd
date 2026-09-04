extends Node2D
## FarmHouseFurniture — TASK-374 Phase 1. Toggleable furniture placement
## for FarmHouse's interior only, scoped to a single item (floor_rug), no
## rotation. A real, separate placement concept from the outdoor
## plant/water/harvest grid contract (GridManager.gd/NavGrid.gd) — does
## not touch either.
##
## Design: press toggle_furniture_place_mode (F) to enter/exit place
## mode. While active, pressing interact places or picks up a rug at the
## PLAYER'S OWN current cell — same convention Player.gd's outdoor
## _try_grid_interact() already uses (floor(global_position / TILE)),
## not mouse-position targeting (this project has no mouse-driven UI
## convention; it's an iOS touch/keyboard target).
##
## Persistence: GameData.placed_furniture (location_id "farmhouse" ->
## Array<{item_id, cell}>), additive, no SAVE_VERSION bump (see
## SaveManager.gd's own comment at the save/load sites).

const TILE: int = 48
const GRID: Vector2i = Vector2i(6, 5)
const LOCATION_ID: String = "farmhouse"
const RUG_ITEM_ID: String = "floor_rug"

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
	if _place_mode and event.is_action_pressed("interact"):
		_try_place_or_pickup()
		get_viewport().set_input_as_handled()

func _update_hint() -> void:
	if _hint:
		_hint.visible = _place_mode
		_hint.text = "Place mode — [E] place/pick up rug, [F] exit"

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
		if GameData.remove_placed_furniture(LOCATION_ID, String(entry.get("item_id", "")), cell):
			GameData.add_item(RUG_ITEM_ID, 1)
			SignalBus.show_dialogue.emit("Farmer", "Picked up the rug.")
		return

	if not GameData.has_item(RUG_ITEM_ID, 1):
		SignalBus.show_dialogue.emit("Farmer", "You don't have a floor rug to place.")
		return

	GameData.remove_item(RUG_ITEM_ID, 1)
	GameData.add_placed_furniture(LOCATION_ID, RUG_ITEM_ID, cell)
	SignalBus.show_dialogue.emit("Farmer", "Placed a floor rug.")

func _on_furniture_changed(location_id: String, _item_id: String, cell: Vector2i, is_placed: bool) -> void:
	if location_id != LOCATION_ID:
		return
	var sprite_name: String = "Rug_%d_%d" % [cell.x, cell.y]
	if is_placed:
		if has_node(sprite_name):
			return
		var sprite := Sprite2D.new()
		sprite.name = sprite_name
		sprite.texture = load("res://assets/environment/mohom_cloth.png")
		sprite.position = Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE / 2.0)
		add_child(sprite)
	else:
		if has_node(sprite_name):
			get_node(sprite_name).queue_free()

func _refresh_rugs() -> void:
	# Re-materialize any rugs already placed (e.g. loaded from a save)
	# that don't have a live sprite yet.
	var list: Array = GameData.placed_furniture.get(LOCATION_ID, [])
	for entry: Dictionary in list:
		_on_furniture_changed(LOCATION_ID, String(entry.get("item_id", "")), entry.get("cell", Vector2i.ZERO), true)
