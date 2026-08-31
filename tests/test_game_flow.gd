extends SceneTree
# TASK-039 game-flow gate — TitleScreen boot + PauseMenu toggle wiring.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  game-flow :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  game-flow :: %s" % label)

func _initialize() -> void:
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var title: CanvasLayer = main.get_node_or_null("TitleScreen") as CanvasLayer
	var pause: CanvasLayer = main.get_node_or_null("PauseMenu") as CanvasLayer
	_check(title != null, "TitleScreen instanced")
	_check(pause != null, "PauseMenu instanced")
	_check(title != null and title.visible, "game boots on title screen")
	_check(pause != null and not pause.visible, "pause starts hidden")
	if main.has_method("_on_new_game") and title != null:
		main._on_new_game() # dismiss title first (pause blocked on title by design)
	if main.has_method("_toggle_pause") and pause != null:
		main._toggle_pause()
		_check(pause.visible and paused, "toggle pauses and shows menu")
		main._toggle_pause()
		_check(not pause.visible and not paused, "toggle resumes and hides menu")
	if main.has_method("_on_new_game") and title != null:
		main._on_new_game()
		_check(not title.visible, "new game dismisses title")
		title.visible = true
	if main.has_method("_on_quit_to_title") and title != null and pause != null:
		main._on_quit_to_title()
		_check(title.visible and not pause.visible, "quit-to-title resets flow")
	# Buttons are wired (pressed signal has connections).
	if title != null:
		var ng: BaseButton = title.find_child("NewGame", true, false) as BaseButton
		_check(ng != null and ng.pressed.get_connections().size() > 0, "NewGame wired")
	if pause != null:
		var rs: BaseButton = pause.find_child("Resume", true, false) as BaseButton
		_check(rs != null and rs.pressed.get_connections().size() > 0, "Resume wired")
	main.queue_free()
	print("\n=== GAME-FLOW TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("GAME-FLOW GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
