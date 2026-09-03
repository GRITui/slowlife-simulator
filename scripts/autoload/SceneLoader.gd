extends Node
## SceneLoader — TASK-352. Single entry point for scene transitions.
## Doors emit SignalBus.scene_transition_requested; this autoload is
## the only thing that calls change_scene_to_file(), so every future
## transition source (save/load, debug teleport, festival cutscenes)
## goes through one code path.
##
## TASK-353: two additional responsibilities bolted on at this single
## choke point so every future transition source benefits automatically:
##   1. Strip the outgoing Player's collision_layer/mask to 0 before the
##      scene swap. change_scene_to_file() defers teardown of the old
##      scene, so for ~1-2 frames the outgoing and incoming Player both
##      exist at the same fallback spawn point; as CharacterBody2Ds they
##      depenetrate via move_and_slide collision recovery even with zero
##      explicit velocity, drifting the new Player up to ~60px. Zeroing
##      the outgoing Player's collision (it's about to be freed anyway)
##      eliminates this depenetration-drift class at the source rather
##      than tolerating it with a widened spawn-distance check.
##   2. Debounce repeat requests within 400ms via Time.get_ticks_msec().
##      Prevents instant re-trigger loops regardless of cause — mashed
##      interact button, a future walk-through EdgeTransition (TASK-357)
##      re-firing on the same physics frame, etc.

## Timestamp (msec) of the last transition this loader actually processed.
## Used for the 400ms debounce in _on_transition_requested.
const _DEBOUNCE_MSEC: int = 400
var _last_transition_msec: int = -1_000_000_000 # start "infinitely long ago" — first request always passes

func _ready() -> void:
	SignalBus.scene_transition_requested.connect(_on_transition_requested)

func _on_transition_requested(target_scene_path: String, target_warp_id: String) -> void:
	# Debounce: a transition fired within 400ms of the previous one is
	# treated as a re-trigger of the same event and ignored entirely.
	# We neither call change_scene_to_file again nor update
	# pending_warp_id — the previous in-flight transition owns the slot.
	if Time.get_ticks_msec() - _last_transition_msec < _DEBOUNCE_MSEC:
		return
	# Strip the outgoing Player's collision so the depenetration-recovery
	# race between outgoing + incoming Player across the deferred scene
	# swap cannot push the new Player off its intended spawn. The outgoing
	# Player is freed shortly by the scene swap; no need to restore. Skip
	# silently when no Player is in the tree (some test setups).
	var outgoing_player: Node = get_tree().get_first_node_in_group("player")
	if outgoing_player != null and outgoing_player is CollisionObject2D:
		(outgoing_player as CollisionObject2D).collision_layer = 0
		(outgoing_player as CollisionObject2D).collision_mask = 0
	SignalBus.pending_warp_id = target_warp_id
	get_tree().change_scene_to_file(target_scene_path)
	# Stamp AFTER we actually queued a transition so the debounce window
	# reflects real transition events, not just accepted requests.
	_last_transition_msec = Time.get_ticks_msec()