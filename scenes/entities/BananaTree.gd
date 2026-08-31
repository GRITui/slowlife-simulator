extends StaticBody2D
## BananaTree — TASK-044 multi-part harvest (PO_INBOX r4 #1).
## Interact priority: leaves (non-destructive, once per day) -> stem felling
## (destructive, gated on holding a machete — no equip system, per spec).
## Fruit grows through the normal CropData path (banana.tres).

@export var leaf_yield: int = 1
var _last_leaf_day: int = -1
var _felled: bool = false
var _player_in_range: bool = false

@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null
@onready var _sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

func _ready() -> void:
	add_to_group("banana_tree")
	if _area != null:
		_area.body_entered.connect(_on_body_entered)
		_area.body_exited.connect(_on_body_exited)

func _current_day() -> int:
	var tm: Node = SignalBus.time_manager
	if tm != null and "day" in tm:
		return int(tm.day)
	return 1

## Non-destructive: banana leaves, once per calendar day.
func harvest_leaves() -> bool:
	if _felled:
		SignalBus.show_dialogue.emit("Banana Tree", "The felled trunk returns to the soil.")
		return false
	var day: int = _current_day()
	if _last_leaf_day == day:
		SignalBus.show_dialogue.emit("Banana Tree", "Already gathered leaves today — they grow back.")
		return false
	_last_leaf_day = day
	GameData.add_item("banana_leaf", leaf_yield)
	SignalBus.show_dialogue.emit("Banana Tree", "+%d banana leaf — wrapped with care." % leaf_yield)
	return true

## Destructive: ends this tree's cycle. Requires holding a machete (consumed
## use is NOT charged — tools persist, per cozy no-loss design).
func fell_tree() -> bool:
	if _felled:
		return false
	if not GameData.has_item("machete", 1):
		SignalBus.show_dialogue.emit("Banana Tree", "The stem is thick. A machete would do it.")
		return false
	_felled = true
	GameData.add_item("banana_stem", 1)
	if _sprite != null:
		_sprite.modulate = Color(0.55, 0.5, 0.45, 0.85)
	SignalBus.show_dialogue.emit("Banana Tree", "Stem cut — +1 banana stem. The plot rests now.")
	return true

func try_interact() -> bool:
	if _felled:
		SignalBus.show_dialogue.emit("Banana Tree", "Only a stump remains.")
		return false
	if _last_leaf_day != _current_day():
		return harvest_leaves()
	return fell_tree()

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		try_interact()
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = false
