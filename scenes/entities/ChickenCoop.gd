extends StaticBody2D
## ChickenCoop — TASK-049 (PO_INBOX r5 #5). No-harm protein: interact grants
## one egg per calendar day (daily-limited resource, unlike Buffalo's
## unlimited milk). Mirror of Buffalo.gd's interaction contract.

@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null

var _player_in_range: bool = false
var _last_egg_day: int = -1

func _ready() -> void:
	add_to_group("chicken_coop")
	if _area != null:
		_area.body_entered.connect(_on_body_entered)
		_area.body_exited.connect(_on_body_exited)

func _current_day() -> int:
	var tm: Node = SignalBus.time_manager
	if tm != null and "day" in tm:
		return int(tm.day)
	return 1

func collect_egg() -> bool:
	var day: int = _current_day()
	if _last_egg_day == day:
		SignalBus.show_dialogue.emit("Chickens", "Hens are resting — eggs come tomorrow.")
		return false
	_last_egg_day = day
	GameData.add_item("egg", 1)
	SignalBus.show_dialogue.emit("Chickens", "+1 egg — warm from the nest.")
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		collect_egg()
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = false
