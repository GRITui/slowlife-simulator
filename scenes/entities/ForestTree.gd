extends StaticBody2D
## ForestTree — ISSUE-133 wood-gathering resource system. Interact chops
## wood (1/day per tree); holding an axe grants +1 bonus log (tool-gated,
## no equip system). Trees regrow daily. Buffalo-mirror contract.

var _player_in_range: bool = false
var _last_chop_day: int = -1

@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null
@onready var _sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

func _ready() -> void:
	add_to_group("forest_tree")
	if _area != null:
		_area.body_entered.connect(_on_body_entered)
		_area.body_exited.connect(_on_body_exited)

func _current_day() -> int:
	var tm: Node = SignalBus.time_manager
	if tm != null and "day" in tm:
		return int(tm.day)
	return 1

func chop() -> bool:
	var day: int = _current_day()
	if _last_chop_day == day:
		SignalBus.show_dialogue.emit("Forest Tree", "Chopped today — the grove needs its rest.")
		return false
	_last_chop_day = day
	var wood: int = 1
	if GameData.has_item("axe", 1):
		wood += 1
	GameData.add_item("wood", wood)
	SignalBus.show_dialogue.emit("Forest Tree", "+%d wood — the axe sings." % wood)
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		chop()
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = false
