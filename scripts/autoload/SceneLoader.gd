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
##
## TASK-354: fade-to-black overlay owned by SceneLoader itself so every
## current AND future transition source gets it for free (the issue's own
## stated intent — SceneLoader is the single chokepoint, so the visual
## treatment belongs at the same chokepoint). The overlay is built in
## _ready() as a CanvasLayer (high layer, renders above HUD/dialogue) +
## full-screen ColorRect (black, mouse_filter = IGNORE so it never
## blocks input), parented to the SceneLoader autoload node directly
## rather than to the current_scene tree — autoload children persist
## across scene swaps automatically. Total transition wall-time is
## ~200ms (100ms fade-out + 100ms fade-in, the issue's stated budget
## split roughly half/half).

## Timestamp (msec) of the last transition this loader actually processed.
## Used for the 400ms debounce in _on_transition_requested.
const _DEBOUNCE_MSEC: int = 400
## Half-budget each for fade-out and fade-in (issue: total ~200ms, split
## roughly half/half). Stored as a single const so the two halves stay
## in sync if the budget is ever retuned.
const _FADE_MSEC: float = 100.0
var _last_transition_msec: int = -1_000_000_000 # start "infinitely long ago" — first request always passes

## TASK-354 overlay: the CanvasLayer is parented to the SceneLoader
## autoload itself, NOT to the current_scene subtree, so it persists
## across change_scene_to_file() swaps. _overlay_color is the inner
## ColorRect — exposed (read-only accessor below) for tests that need
## to sample its alpha mid-transition.
var _overlay_layer: CanvasLayer = null
var _overlay_color: ColorRect = null

func _ready() -> void:
	SignalBus.scene_transition_requested.connect(_on_transition_requested)
	_build_overlay()

func _build_overlay() -> void:
	# Persistent fade overlay. Owned by SceneLoader so it outlives every
	# change_scene_to_file() swap (autoload children don't get freed
	# when current_scene is swapped). CanvasLayer with layer=100 sits
	# above HUD / dialogue / market panels so the fade is always
	# visible. ColorRect is full-screen anchored, black, fully
	# transparent at rest, and ignores mouse input so it never blocks
	# interaction during the fade.
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.name = "TransitionFadeLayer"
	_overlay_layer.layer = 100
	_overlay_color = ColorRect.new()
	_overlay_color.name = "FadeRect"
	_overlay_color.color = Color(0.0, 0.0, 0.0, 0.0)
	_overlay_color.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Anchor to full-screen so resizes / viewport changes still cover
	# the whole view (offset 0/0/0/0 + anchors at the four corners).
	_overlay_color.anchor_left = 0.0
	_overlay_color.anchor_top = 0.0
	_overlay_color.anchor_right = 1.0
	_overlay_color.anchor_bottom = 1.0
	_overlay_color.offset_left = 0.0
	_overlay_color.offset_top = 0.0
	_overlay_color.offset_right = 0.0
	_overlay_color.offset_bottom = 0.0
	_overlay_layer.add_child(_overlay_color)
	add_child(_overlay_layer)

## Read-only alpha accessor for the TASK-354 fade suite (and any future
## mid-transition overlay inspection). Returns 0.0 if the overlay hasn't
## been built yet (e.g. tests that fire transitions before _ready ran).
func get_overlay_alpha() -> float:
	if _overlay_color == null:
		return 0.0
	return _overlay_color.color.a

func _on_transition_requested(target_scene_path: String, target_warp_id: String) -> void:
	# Coroutine: GDScript signal handlers support await natively, so the
	# fade-out / scene-swap / fade-in sequence below is straight-line
	# without any extra wiring. The Debounce + Collision-strip sequence
	# is intentionally unchanged in order — the TASK-353 contract is
	# "debounce first, then strip, then transition" and adding the
	# fade between strip and transition preserves that exactly.
	#
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
	# Owner request (2026-09-05, water/tree impassability): the same
	# deferred-teardown race above isn't unique to the Player -- ANY
	# collision body left in the outgoing scene (e.g. WorldRender's new
	# WaterCollision/TreeCollision_* StaticBody2D nodes) can still be in
	# the shared 2D physics space during the incoming scene's first few
	# physics frames, since change_scene_to_file() only QUEUES the old
	# scene for deferred freeing. Concretely caught this session: a
	# FarmHouse door spawn point at (144, 192) sat exactly on the corner
	# of a still-alive World.tscn water-collision cell, pushing the
	# incoming FarmHouse Player off its intended spawn -- the identical
	# depenetration-recovery race the Player-specific strip above already
	# fixed once, just triggered by a different body this time. Strip
	# every CollisionObject2D under the outgoing scene, not just the
	# Player -- it's being torn down regardless, nothing needs its
	# collision during the deferred-free window.
	var outgoing_scene: Node = get_tree().current_scene
	if outgoing_scene != null:
		var stack: Array[Node] = [outgoing_scene]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			if n is CollisionObject2D:
				(n as CollisionObject2D).collision_layer = 0
				(n as CollisionObject2D).collision_mask = 0
			stack.append_array(n.get_children())
	# TASK-354 fade-out: opaque over ~100ms so the player sees a brief
	# black wash before the scene swap actually happens. Awaiting the
	# tween guarantees change_scene_to_file() is queued only AFTER the
	# fade is done — otherwise the new scene could start loading
	# mid-fade and the fade-in would visually fight the scene content.
	await _fade_to(1.0, _FADE_MSEC)
	SignalBus.pending_warp_id = target_warp_id
	get_tree().change_scene_to_file(target_scene_path)
	# Stamp AFTER we actually queued a transition so the debounce window
	# reflects real transition events, not just accepted requests. The
	# debounce intentionally does NOT wait for the fade-in — a second
	# transition request fired while we're still fading back in should
	# be rejected, otherwise the player could re-trigger a fade they
	# can no longer see (since the screen is already opaque again).
	_last_transition_msec = Time.get_ticks_msec()
	# Wait for the new scene to actually be attached and its _ready()
	# to have run before fading back in. change_scene_to_file() defers
	# the swap to the next idle frame, so a wall-clock-capped poll is
	# the right shape here (matches the _wait_for_current_scene helper
	# used by the test suite, but with a time budget rather than a
	# frame count so it tolerates the new ~200ms fade cost without
	# needing per-call-site budget tuning).
	await _wait_for_current_scene(target_scene_path)
	await _fade_to(0.0, _FADE_MSEC)

## Tween-driven overlay alpha tween. One-shot Tween (auto-killed on
## completion) bound to SceneLoader itself (not the ColorRect) so the
## fade keeps running even if the current_scene subtree is mid-swap.
func _fade_to(target_alpha: float, duration_msec: float) -> void:
	if _overlay_color == null:
		return
	var t: Tween = create_tween()
	t.tween_property(_overlay_color, "color:a", target_alpha, duration_msec / 1000.0)
	await t.finished

## Poll current_scene until its scene_file_path matches the expected
## target, with a wall-clock cap rather than a frame cap. The fade
## transition now takes ~200ms (two tweens), so a fixed-iteration
## process_frame poll could in theory come in too tight under load —
## a 2-second time budget is self-tuning for any future fade retune
## without needing per-call-site budget edits.
func _wait_for_current_scene(expected_path: String) -> void:
	var deadline_msec: int = Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline_msec:
		await get_tree().process_frame
		if get_tree().current_scene != null and get_tree().current_scene.scene_file_path == expected_path:
			return