extends CharacterBody2D
# Buffalo — TASK-020 cozy care, no combat. Feed/pet via interact.
# TASK-311 (#159 BUG fix): daily-gated milk (Binthabat pattern), affinity
# accrual per interaction, hearts surfaced via SignalBus + HUD.

@export var buffalo_id: String = "buffalo_01"
var _player_in_range: bool = false
var _last_milk_day: int = -1

@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null

func _ready() -> void:
	add_to_group("buffalo")
	if _area != null:
		if not _area.body_entered.is_connected(_on_enter):
			_area.body_entered.connect(_on_enter)
		if not _area.body_exited.is_connected(_on_exit):
			_area.body_exited.connect(_on_exit)

func _current_day() -> int:
	var tm: Node = SignalBus.time_manager
	if tm != null and "day" in tm:
		return int(tm.day)
	return 1

func interact() -> bool:
	var day: int = _current_day()
	if _last_milk_day == day:
		SignalBus.show_dialogue.emit("Buffalo", "Already tended today — the buffalo grazes contentedly.")
		return false
	_last_milk_day = day
	GameData.add_item("buffalo_milk", 1)
	var hearts_before: int = GameData.buffalo_hearts()
	GameData.add_buffalo_affinity(5)
	SignalBus.buffalo_affinity_changed.emit(GameData.buffalo_affinity, GameData.buffalo_hearts())
	if GameData.buffalo_hearts() > hearts_before:
		SignalBus.show_dialogue.emit("Buffalo", "The buffalo trusts you more. +1 milk — hearts: %d!" % GameData.buffalo_hearts())
	else:
		SignalBus.show_dialogue.emit("Buffalo", "The buffalo nuzzles you. +1 milk (hearts %d)." % GameData.buffalo_hearts())
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		interact()
		get_viewport().set_input_as_handled()

func _on_enter(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = true

func _on_exit(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = false
