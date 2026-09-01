extends CharacterBody2D
## Goat — TASK-056 (#114) no-harm farm animal, Buffalo.gd mirror.
## Interact grants goat_milk once per calendar day (daily-limited, cozy).

@export var goat_id: String = "goat_01"
var _player_in_range: bool = false
var _last_milk_day: int = -1

@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null

func _ready() -> void:
	add_to_group("goat")
	if _area != null:
		_area.body_entered.connect(_on_body_entered)
		_area.body_exited.connect(_on_body_exited)

func _current_day() -> int:
	var tm: Node = SignalBus.time_manager
	if tm != null and "day" in tm:
		return int(tm.day)
	return 1

func milk() -> bool:
	var day: int = _current_day()
	if _last_milk_day == day:
		SignalBus.show_dialogue.emit("Goat", "Already milked today — come back tomorrow morning.")
		return false
	_last_milk_day = day
	GameData.add_item("goat_milk", 1)
	SignalBus.show_dialogue.emit("Goat", "+1 goat milk — rich and warm.")
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		milk()
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = false
