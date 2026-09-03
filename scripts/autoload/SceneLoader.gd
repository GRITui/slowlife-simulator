extends Node
## SceneLoader — TASK-352. Single entry point for scene transitions.
## Doors emit SignalBus.scene_transition_requested; this autoload is
## the only thing that calls change_scene_to_file(), so every future
## transition source (save/load, debug teleport, festival cutscenes)
## goes through one code path.

func _ready() -> void:
	SignalBus.scene_transition_requested.connect(_on_transition_requested)

func _on_transition_requested(target_scene_path: String, target_warp_id: String) -> void:
	SignalBus.pending_warp_id = target_warp_id
	get_tree().change_scene_to_file(target_scene_path)