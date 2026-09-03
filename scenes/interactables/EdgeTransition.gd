extends Area2D
## EdgeTransition — TASK-357. Walk-through area-to-area transition (map
## edges), distinct from Door.gd's interact-required building entry.
## Fires once per crossing, not once per frame while overlapping — see
## _player_inside guard. Maps cleanly to the HM:BTN screen-walk model.
##
## Coordinate carry-over (the one real design problem a Door doesn't
## have): a Door warp always lands the player at a fixed point (the
## matching door's position + spawn_offset) — correct for building
## entry. An edge crossing must NOT snap to a fixed point: walking off
## the east edge of World.tscn at y=288 should land you on
## CoastalArea.tscn's west edge at the *same* y=288, not at some
## arbitrary door-anchor point. The outgoing edge sets
## `SignalBus.edge_carry_value` to the player's current position on
## `carry_axis` BEFORE emitting the transition signal; the incoming
## matching edge's host scene reads it (via InteriorBase._spawn_player)
## and positions the player along its own edge on `carry_axis`. Building
## Door warps are unaffected — they keep using the fixed `spawn_offset`
## convention untouched.
##
## Re-trigger guard: TASK-353's 400ms SceneLoader debounce also covers
## this case (an EdgeTransition's _on_body_entered can only fire once
## per overlap thanks to the _player_inside flag, and any re-fire within
## 400ms is dropped at the SceneLoader level). Both layers matter: the
## per-edge flag prevents same-overlap repeats; the debounce catches
## the multi-edge ping-pong case (player crosses A->B and B->A on
## adjacent physics frames).

@export var target_scene_path: String = ""
@export var target_warp_id: String = ""
@export var warp_id: String = ""
## The axis that carries across unchanged (see "Coordinate carry-over"
## above). "x" for a north/south edge, "y" for an east/west edge.
@export var carry_axis: String = "y"

var _player_inside: bool = false

func _ready() -> void:
	add_to_group("edge_transition")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player") or _player_inside:
		return
	_player_inside = true
	SignalBus.edge_carry_value = body.global_position[carry_axis]
	SignalBus.scene_transition_requested.emit(target_scene_path, target_warp_id)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false