extends SceneTree
# TASK-036 joystick gate — structural + input-state simulation (headless-safe).

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  joystick :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  joystick :: %s" % label)

func _initialize() -> void:
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var hud: Node = main.get_node_or_null("HUD")
	var joy: Control = hud.get_node_or_null("VirtualJoystick") if hud else null
	var tap: Control = hud.get_node_or_null("InteractTap") if hud else null
	_check(joy != null, "HUD has VirtualJoystick")
	_check(tap != null, "HUD has InteractTap")
	_check(joy != null and joy.custom_minimum_size.y >= 44.0, "joystick >= 44pt")
	_check(tap != null and tap.custom_minimum_size.y >= 44.0, "tap >= 44pt")
	# Simulate drag left: strength feeding must press move_left only.
	if joy != null and joy.has_method("_apply"):
		joy._apply(Vector2(-50, 0))
		_check(Input.get_action_strength("move_left") > 0.0, "drag left feeds move_left")
		_check(is_equal_approx(Input.get_action_strength("move_right"), 0.0), "drag left releases move_right")
		joy._apply(Vector2(0, -60))
		_check(Input.get_action_strength("move_up") > 0.0, "drag up feeds move_up")
		if joy.has_method("_release"):
			joy._release()
		_check(is_equal_approx(Input.get_action_strength("move_up"), 0.0), "release clears move_up")
		_check(is_equal_approx(Input.get_action_strength("move_left"), 0.0), "release clears move_left")
	# Tap-to-interact: emitted action event must set interact state.
	if tap != null and tap.has_method("_emit_interact"):
		tap._emit_interact()
		await process_frame
		_check(Input.is_action_pressed("interact"), "tap emits interact action")
		var rel: InputEventAction = InputEventAction.new()
		rel.action = "interact"
		rel.pressed = false
		Input.parse_input_event(rel)
		await process_frame
	main.queue_free()
	print("\n=== JOYSTICK TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("JOYSTICK GATE FAILED: %d failing checks" % _failed)
	await process_frame
	quit(1 if _failed > 0 else 0)
