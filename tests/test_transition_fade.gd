extends SceneTree
# TASK-354 transition-fade gate. Covers SceneLoader's new fade-to-black
# overlay and confirms it doesn't disturb the TASK-353 debounce contract.
# Three groups of checks:
#
#   A. Overlay infrastructure: a CanvasLayer with layer=100 + a full-screen
#      ColorRect (black, transparent at rest) exists as a child of the
#      SceneLoader autoload node, and starts at alpha ~0.0.
#   B. Mid-transition fade: firing scene_transition_requested raises the
#      overlay's alpha during the fade-out (sampled a frame or two after
#      emit, BEFORE awaiting full completion), and returns it to ~0.0
#      after the transition fully completes.
#   C. TASK-353 regression smoke: the 400ms debounce still drops a
#      second emit fired back-to-back with the first.
#
# Follows the existing tests' `_check(cond, label)` convention (see
# tests/test_scene_transitions.gd, tests/test_audio.gd). The test runs
# directly against the autoload SceneLoader + SignalBus.

const WORLD_PATH: String = "res://scenes/core/World.tscn"
const FARMHOUSE_PATH: String = "res://scenes/interiors/FarmHouse.tscn"

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  transition-fade :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  transition-fade :: %s" % label)

func _initialize() -> void:
	await _run_all()
	print("\n=== TRANSITION-FADE TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("TRANSITION-FADE GATE FAILED: %d failing checks" % _failed)
	quit(1 if _failed > 0 else 0)

func _run_all() -> void:
	var sb: Node = root.get_node("SignalBus")
	var sl: Node = root.get_node("SceneLoader")
	# Wait one frame so SceneLoader._ready() has run (it both connects
	# the signal AND builds the overlay in _ready, in that order).
	await process_frame

	# --- A. Overlay infrastructure.
	_check(sl != null, "SceneLoader autoload present at /root/SceneLoader")
	_check(sl.get_overlay_alpha() < 0.01,
		"overlay alpha starts at ~0.0 (got %.4f)" % sl.get_overlay_alpha())
	var layer: CanvasLayer = sl.get_node_or_null("TransitionFadeLayer") as CanvasLayer
	_check(layer != null,
		"SceneLoader owns a CanvasLayer named 'TransitionFadeLayer'")
	_check(layer != null and layer.layer >= 100,
		"CanvasLayer.layer is >= 100 (renders above HUD/dialogue), got %d"
			% (layer.layer if layer != null else -1))
	var rect: ColorRect = null
	if layer != null:
		rect = layer.get_node_or_null("FadeRect") as ColorRect
	_check(rect != null,
		"CanvasLayer contains a ColorRect named 'FadeRect'")
	_check(rect != null and rect.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"ColorRect.mouse_filter is IGNORE (never blocks input)")
	_check(rect != null and rect.color == Color(0.0, 0.0, 0.0, 0.0),
		"ColorRect.color is opaque-black at rest (got %s)" % str(rect.color if rect != null else Color()))
	# Confirm overlay is parented to SceneLoader itself, NOT to current_scene
	# (so it survives change_scene_to_file).
	_check(layer != null and layer.get_parent() == sl,
		"TransitionFadeLayer is parented to SceneLoader (persists across swaps), got parent=%s"
			% str(layer.get_parent() if layer != null else null))

	# --- B. Mid-transition fade. Set up a clean baseline (in World), wait
	# past the debounce window so the upcoming emit is treated as fresh,
	# fire the transition signal, and sample the overlay alpha BEFORE the
	# coroutine has had time to complete (SceneLoader._on_transition_requested
	# is now a coroutine, so the signal emit returns immediately but the
	# fade-out is already in flight on a Tween).
	sb.pending_warp_id = ""
	change_scene_to_file(WORLD_PATH)
	await _wait_for_current_scene(WORLD_PATH)
	# Let any prior debounce window expire before we kick off our own
	# transition — otherwise the very first emit gets eaten.
	await create_timer(0.5).timeout
	# Fire the transition. We do NOT await the full transition here —
	# we want to sample alpha mid-fade, then yield to let it complete,
	# then sample alpha post-fade.
	sb.scene_transition_requested.emit(FARMHOUSE_PATH, "farmhouse_entry")
	# Sample at ~50% through the 100ms fade-out. create_timer advances on
	# real wall-clock (not on frame count) so the timing is deterministic
	# regardless of headless frame rate. A bare process_frame yield in
	# headless can be 0ms apart, leaving the tween with virtually no
	# accumulated delta — that's why the original `await process_frame`
	# approach sampled at alpha ~0.13 instead of the expected ~0.5.
	await create_timer(0.05).timeout
	var alpha_mid: float = sl.get_overlay_alpha()
	_check(alpha_mid > 0.1,
		"overlay alpha rises during transition (got %.4f, expected > 0.1 mid-fade-out)" % alpha_mid)
	# Now actually let the transition complete (await the rest).
	await _wait_for_current_scene(FARMHOUSE_PATH)
	# The fade-in is also a 100ms Tween; 200ms is enough to catch the
	# overlay back near zero (the fade-in is the LAST step of the
	# coroutine).
	await create_timer(0.2).timeout
	var alpha_after: float = sl.get_overlay_alpha()
	_check(alpha_after < 0.01,
		"overlay alpha returns to ~0.0 after transition completes (got %.4f)" % alpha_after)

	# --- C. TASK-353 regression smoke. The 400ms debounce should still
	# collapse two back-to-back emits into ONE actual transition. Same
	# shape as test_scene_transitions.gd lines ~301-319: first emit
	# targets a real scene, second emit targets a deliberately
	# nonexistent path so a regression would be immediately visible
	# (current_scene stuck on bogus path, or Godot error).
	await create_timer(0.5).timeout
	sb.pending_warp_id = ""
	change_scene_to_file(WORLD_PATH)
	await _wait_for_current_scene(WORLD_PATH)
	await create_timer(0.5).timeout
	sb.scene_transition_requested.emit(FARMHOUSE_PATH, "")
	sb.scene_transition_requested.emit("res://DOES_NOT_EXIST.tscn", "")
	await _wait_for_current_scene(FARMHOUSE_PATH)
	_check(current_scene.scene_file_path == FARMHOUSE_PATH,
		"debounce regression: first of two back-to-back emits still wins (current_scene=%s)"
			% str(current_scene.scene_file_path))
	_check(current_scene.scene_file_path != "res://DOES_NOT_EXIST.tscn",
		"debounce regression: second emit (res://DOES_NOT_EXIST.tscn) still DROPPED")

## Same shape as test_scene_transitions.gd / test_area_edges.gd /
## test_save_scene_restore.gd's helper — wall-clock budget so it
## tolerates the TASK-354 ~200ms fade, plus a few extra frames after
## the swap to let the new scene's _ready() chain settle.
func _wait_for_current_scene(expected_path: String) -> void:
	var deadline_msec: int = Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline_msec:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == expected_path:
			await process_frame
			await process_frame
			await process_frame
			return