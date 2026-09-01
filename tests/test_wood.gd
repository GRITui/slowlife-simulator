extends SceneTree
# ISSUE-133 wood gathering gate — chop, axe bonus, daily limit.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  wood :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  wood :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var tree: Node = main.get_node_or_null("ForestTree18_3")
	_check(tree != null, "forest trees instanced")
	_check(tree != null and tree.is_in_group("forest_tree"), "tree tagged")
	if tree == null:
		await process_frame
		quit(1)
		return
	# Without axe: 1 wood.
	gd.inventory.erase("axe")
	_check(tree.chop(), "chop without axe")
	_check(int(gd.inventory.get("wood", 0)) == 1, "+1 wood (no axe)")
	_check(tree.chop() == false, "same-day re-chop blocked")
	# With axe: +1 bonus.
	var tm: Node = root.get_node("SignalBus").time_manager
	if tm != null:
		tm.set_time(2, 6, 0)
	gd.add_item("axe", 1)
	_check(tree.chop(), "chop with axe next day")
	_check(int(gd.inventory.get("wood", 0)) == 3, "+2 wood with axe (3 total incl. day 1)")
	# Axe obtainable via barter.
	gd.inventory.erase("axe")
	gd.add_item("rice_grain", 2)
	_check(gd.barter("rice_grain", "axe"), "axe obtainable via barter")
	_check(gd.has_item("axe", 1), "axe in inventory after barter")
	main.queue_free()
	print("\n=== WOOD TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("WOOD GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
