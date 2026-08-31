extends SceneTree
# TASK-044 banana harvest gate — leaves/day, machete-gated felling.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  banana :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  banana :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var tree: Node = main.get_node_or_null("BananaTree")
	_check(tree != null, "BananaTree instanced at banana prop (4,12)")
	_check(tree != null and tree.is_in_group("banana_tree"), "tree tagged")
	_check(int(gd.inventory.get("machete", 0)) >= 1, "machete in starting inventory")
	if tree == null:
		main.queue_free()
		await process_frame
		quit(1)
		return
	# Leaves: once per day.
	_check(tree.harvest_leaves(), "leaves harvest day 1")
	_check(int(gd.inventory.get("banana_leaf", 0)) >= 1, "banana_leaf granted")
	_check(tree.harvest_leaves() == false, "second same-day harvest blocked")
	# Next day: leaves regrow.
	gd.inventory.erase("banana_leaf")
	var tm: Node = root.get_node("SignalBus").time_manager
	if tm != null:
		tm.set_time(2, 6, 0)
	_check(tree.harvest_leaves(), "leaves regrow next day")
	# Felling: machete-gated, destructive.
	_check(tree.fell_tree(), "felling succeeds with machete")
	_check(int(gd.inventory.get("banana_stem", 0)) == 1, "banana_stem granted")
	_check(tree.fell_tree() == false, "double felling blocked")
	_check(tree.harvest_leaves() == false, "felled tree yields nothing")
	main.queue_free()
	print("\n=== BANANA TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("BANANA GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
