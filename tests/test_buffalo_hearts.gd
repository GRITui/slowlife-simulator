extends SceneTree
# ISSUE-129 buffalo hearts gate — affinity accrues, 10 heart tiers.
# TASK-348: scale unified with the 0-10 hearts system (TASK-346's
# level_for()) — 1 heart = 10 affinity, max 10 hearts at 100. The
# old 0-4 /25.0 scale is gone.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  hearts :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  hearts :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var buffalo: Node = main.get_node_or_null("Buffalo")
	_check(buffalo != null, "Buffalo present")
	_check(int(gd.buffalo_hearts()) == 0, "starts at 0 hearts")
	for i: int in 2:
		buffalo._unhandled_input_load() if buffalo.has_method("_unhandled_input_load") else null
		gd.add_buffalo_affinity(5)
	_check(int(gd.buffalo_hearts()) == 1, "10 affinity -> 1 heart (TASK-348: 10/heart, was 25/heart)")
	for i: int in 18:
		gd.add_buffalo_affinity(5)
	_check(int(gd.buffalo_hearts()) == 10, "max 10 hearts at 100 (TASK-348: was 4)")
	gd.add_buffalo_affinity(50)
	_check(int(gd.buffalo_hearts()) == 10, "affinity capped at level 10")
	main.queue_free()
	print("\n=== HEARTS TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("HEARTS GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
