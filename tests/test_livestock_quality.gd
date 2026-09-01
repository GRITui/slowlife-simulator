extends SceneTree
# TASK-323 livestock quality tiers — high-tier items at 3+ hearts.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  quality :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  quality :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var buffalo: Node = main.get_node_or_null("Buffalo")
	var coop: Node = main.get_node_or_null("ChickenCoop")
	_check(buffalo != null, "Buffalo present")
	_check(coop != null, "ChickenCoop present")
	var tm: Node = root.get_node("SignalBus").time_manager

	# --- Buffalo quality tier ---
	gd.buffalo_affinity = 0
	gd.inventory.erase("buffalo_milk")
	gd.inventory.erase("buffalo_milk_high")
	if tm != null:
		tm.set_time(1, 6, 0)
	_check(buffalo.interact(), "buffalo interact day 1 (0 hearts)")
	_check(int(gd.inventory.get("buffalo_milk", 0)) == 1, "buffalo grants base milk at 0 hearts")
	_check(int(gd.inventory.get("buffalo_milk_high", 0)) == 0, "no high milk at 0 hearts")
	gd.add_buffalo_affinity(75)
	_check(int(gd.buffalo_hearts()) == 3, "buffalo at 3 hearts after +75")
	if tm != null:
		tm.set_time(2, 6, 0)
	_check(buffalo.interact(), "buffalo interact day 2 (3 hearts)")
	_check(int(gd.inventory.get("buffalo_milk_high", 0)) == 1, "buffalo grants high milk at 3 hearts")
	_check(int(gd.inventory.get("buffalo_milk", 0)) == 1, "base milk not re-granted")

	# --- Chicken quality tier ---
	gd.chicken_affinity = 0
	gd.inventory.erase("egg")
	gd.inventory.erase("egg_gold")
	if tm != null:
		tm.set_time(3, 6, 0)
	_check(coop.collect_egg(), "chicken collect day 3 (0 hearts)")
	_check(int(gd.inventory.get("egg", 0)) == 1, "chicken grants base egg at 0 hearts")
	_check(int(gd.inventory.get("egg_gold", 0)) == 0, "no gold egg at 0 hearts")
	gd.add_chicken_affinity(75)
	_check(int(gd.chicken_hearts()) == 3, "chicken at 3 hearts after +75")
	if tm != null:
		tm.set_time(4, 6, 0)
	_check(coop.collect_egg(), "chicken collect day 4 (3 hearts)")
	_check(int(gd.inventory.get("egg_gold", 0)) == 1, "chicken grants gold egg at 3 hearts")
	_check(int(gd.inventory.get("egg", 0)) == 1, "base egg not re-granted")

	main.queue_free()
	print("\n=== QUALITY TIER TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("QUALITY TIER GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)