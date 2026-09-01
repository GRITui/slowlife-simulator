extends StaticBody2D
## RaceStarter — TASK-303 (#155 BUG fix). Gives BuffaloRace.start_race() a
## real entry point: interact here (Wing Kwai official's stand, next to
## checkpoint 1) to begin the race. Mount required (R), per race rules.

@export var stall_name: String = "Race Official"
var _player_in_range: bool = false

@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null

func _ready() -> void:
	add_to_group("race_starter")
	if _area != null:
		_area.body_entered.connect(_on_body_entered)
		_area.body_exited.connect(_on_body_exited)

func try_start() -> bool:
	var main: Node = get_parent()
	var race: Node = main.get_node_or_null("BuffaloRace") if main != null else null
	if race == null or not race.has_method("start_race"):
		SignalBus.show_dialogue.emit(stall_name, "The track is being prepared. Come back soon.")
		return false
	var players: Array = get_tree().get_nodes_in_group("player")
	var player: Node2D = players[0] as Node2D if not players.is_empty() else null
	if race.start_race(player):
		return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		try_start()
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = false
