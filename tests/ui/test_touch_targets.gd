extends SceneTree
# TASK-035 touch-target gate — Apple 44x44pt minimum (CLAUDE.md constraint #3).
# Structural: every interactive Control in live UI scenes declares
# custom_minimum_size.y >= 44 (sliders/checks/buttons).

var _passed: int = 0
var _failed: int = 0
var _interactive: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  touch :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  touch :: %s" % label)

func _scan_scene(path: String) -> void:
	var scene: PackedScene = load(path)
	_check(scene != null, "%s loads" % path)
	if scene == null:
		return
	var root_node: Node = scene.instantiate()
	var bad: Array = []
	_interactive = 0
	_walk(root_node, bad)
	_check(bad.is_empty(), "%s: %d interactive controls, all >= 44pt %s" % [
		path.get_file(), _interactive, ("" if bad.is_empty() else str(bad))])
	root_node.free()

func _walk(node: Node, bad: Array) -> void:
	for c in node.get_children():
		if c is BaseButton or c is HSlider or c is CheckBox:
			_interactive += 1
			var ms: Vector2 = (c as Control).custom_minimum_size
			if ms.y < 44.0:
				bad.append("%s(y=%d)" % [c.name, int(ms.y)])
		_walk(c, bad)

func _initialize() -> void:
	_scan_scene("res://scenes/ui/Settings.tscn")
	_scan_scene("res://scenes/ui/TitleScreen.tscn")
	_scan_scene("res://scenes/ui/PauseMenu.tscn")
	_scan_scene("res://scenes/ui/HUD.tscn")
	_scan_scene("res://scenes/ui/MarketShop.tscn")
	print("\n=== TOUCH-TARGET TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("TOUCH GATE FAILED: %d failing checks" % _failed)
	await process_frame
	quit(1 if _failed > 0 else 0)
