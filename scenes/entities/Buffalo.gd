extends CharacterBody2D
# Buffalo — TASK-020 cozy care, no combat. Feed/pet via interact.
@export var buffalo_id: String = "buffalo_01"
var _player_in_range: bool = false
@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null
func _ready() -> void:
  add_to_group("buffalo")
  if _area:
    _area.body_entered.connect(_on_enter)
    _area.body_exited.connect(_on_exit)
func _unhandled_input(event: InputEvent) -> void:
  if not _player_in_range: return
  if event.is_action_pressed("interact"):
    GameData.add_item("buffalo_milk", 1)
    SignalBus.show_dialogue.emit("Buffalo", "The buffalo nuzzles you. +1 milk (cozy).")
    get_viewport().set_input_as_handled()
func _on_enter(body: Node) -> void:
  if body.is_in_group("player"): _player_in_range = true
func _on_exit(body: Node) -> void:
  if body.is_in_group("player"): _player_in_range = false
