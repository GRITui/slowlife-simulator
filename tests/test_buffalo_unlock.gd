extends SceneTree
# TASK-038 buffalo unlock gate — dormant TASK-020 scene is live in World.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  buffalo-unlock :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  buffalo-unlock :: %s" % label)

func _initialize() -> void:
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var buffalo: Node = main.get_node_or_null("Buffalo")
	_check(buffalo != null, "Buffalo instanced in World")
	if buffalo != null:
		_check(buffalo.is_in_group("buffalo"), "Buffalo in 'buffalo' group")
		var pos: Vector2 = (buffalo as Node2D).position
		_check(pos.x > 0.0 and pos.y >= 10 * 48 and pos.y <= 16 * 48,
			"Buffalo positioned in pasture band (%v)" % pos)
		_check((buffalo as Node2D).get_parent() == main and main.y_sort_enabled,
			"Buffalo participates in Y-sort")
	main.queue_free()
	print("\n=== BUFFALO-UNLOCK TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("BUFFALO UNLOCK GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
