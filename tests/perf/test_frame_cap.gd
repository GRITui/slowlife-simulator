extends SceneTree
# TASK-042 frame-cap gate — structural + state simulation (headless-safe:
# FrameCap is desktop-inert by design, so this asserts the contract pieces).

var _passed: int = 0
var _failed: int = 0
var _hits: int = 0

func _on_paused(_p: bool) -> void:
	_hits += 1

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  frame-cap :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  frame-cap :: %s" % label)

func _initialize() -> void:
	var sb: Node = root.get_node("SignalBus")
	_check(sb.has_signal("game_paused_changed"), "SignalBus.game_paused_changed exists")
	var fc: Node = root.get_node_or_null("FrameCap")
	_check(fc != null, "FrameCap autoload registered")
	_check(fc != null and fc.has_method("_apply"), "FrameCap._apply exists")
	# Desktop-inert contract: applying must not change desktop Engine.max_fps.
	var before: int = Engine.max_fps
	if fc != null:
		fc._apply(true)
		_check(Engine.max_fps == before, "desktop passthrough: max_fps unchanged on apply(true)")
	# Signal round-trip: emitting does not crash and reaches consumers.
	sb.game_paused_changed.connect(_on_paused)
	sb.game_paused_changed.emit(true)
	sb.game_paused_changed.emit(false)
	sb.game_paused_changed.disconnect(_on_paused)
	_check(_hits == 2, "game_paused_changed round-trip (2 hits)")
	# World emits exist (static-ish check via method source presence).
	var main_src: String = FileAccess.open("res://scenes/core/World.gd", FileAccess.READ).get_as_text()
	var emit_count: int = main_src.count("game_paused_changed.emit")
	_check(emit_count == 3, "World.gd emits pause state 3x (got %d)" % emit_count)
	print("\n=== FRAME-CAP TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("FRAME-CAP GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
