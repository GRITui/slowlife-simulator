extends Node2D
## Door — TASK-352. Placed as a real .tscn child (NOT script.new()-
## instanced like the unlockable-area spots) since doors are fixed,
## hand-placed level geometry, not dynamically-gated content — a real
## .tscn instance CAN safely use @onready $InteractArea here; this is
## the ForestTree.gd case, not the MountainCaveSpot.gd case.

@export var target_scene_path: String = ""
@export var target_warp_id: String = ""
## This door's OWN id — when a door elsewhere targets this warp id,
## the player spawns at this door's position (see spawn_offset).
@export var warp_id: String = ""
@export var spawn_offset: Vector2 = Vector2(0, 48)  # one tile south of the door

@onready var _area: Area2D = $InteractArea

var _player_in_range: bool = false

func _ready() -> void:
	add_to_group("door")
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		SignalBus.scene_transition_requested.emit(target_scene_path, target_warp_id)
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = false