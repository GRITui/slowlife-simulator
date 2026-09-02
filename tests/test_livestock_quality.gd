extends SceneTree
# TASK-323 livestock quality tiers — high-tier items at 8+ hearts.
# TASK-348: scale unified with the 0-10 hearts system. Gold-egg /
# high-milk tier moved from hearts >= 3 (old 0-4 scale, 75%) to
# hearts >= 8 (new 0-10 scale, 80%) — see Buffalo.gd / ChickenCoop.gd
# and the TASK-348 spec.

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
	# TASK-348: cross the new 0-10 threshold exactly. +80 -> 80 affinity
	# -> int(80/10) = 8 (was +75 -> int(75/25) = 3 in the old 0-4 era).
	gd.add_buffalo_affinity(80)
	_check(int(gd.buffalo_hearts()) == 8, "buffalo at 8 hearts after +80 (TASK-348 threshold)")
	# Sanity-check the new boundary is exact: 7 does NOT cross the gate.
	gd.buffalo_affinity = 79
	_check(int(gd.buffalo_hearts()) == 7, "buffalo at 7 hearts (just below gold-milk threshold)")
	if tm != null:
		tm.set_time(2, 6, 0)
	_check(buffalo.interact(), "buffalo interact day 2 (8 hearts)")
	_check(int(gd.inventory.get("buffalo_milk_high", 0)) == 1, "buffalo grants high milk at 8 hearts")
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
	# Same TASK-348 rescale as buffalo: +80 -> 8 hearts (the new
	# gold-egg threshold), was +75 -> 3 in the old 0-4 era.
	gd.add_chicken_affinity(80)
	_check(int(gd.chicken_hearts()) == 8, "chicken at 8 hearts after +80 (TASK-348 threshold)")
	# Just-below sanity check, mirroring the buffalo one above.
	gd.chicken_affinity = 79
	_check(int(gd.chicken_hearts()) == 7, "chicken at 7 hearts (just below gold-egg threshold)")
	if tm != null:
		tm.set_time(4, 6, 0)
	_check(coop.collect_egg(), "chicken collect day 4 (8 hearts)")
	_check(int(gd.inventory.get("egg_gold", 0)) == 1, "chicken grants gold egg at 8 hearts")
	_check(int(gd.inventory.get("egg", 0)) == 1, "base egg not re-granted")

	main.queue_free()
	print("\n=== QUALITY TIER TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("QUALITY TIER GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)