extends SceneTree
# TASK-049 chicken coop gate — daily-limited egg, no-harm.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  chicken :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  chicken :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var coop: Node = main.get_node_or_null("ChickenCoop")
	_check(coop != null, "ChickenCoop instanced in pasture")
	_check(coop != null and coop.is_in_group("chicken_coop"), "coop tagged")
	if coop == null:
		await process_frame
		quit(1)
		return
	_check(coop.collect_egg(), "egg collected day 1")
	_check(int(gd.inventory.get("egg", 0)) == 1, "egg in inventory")
	_check(coop.collect_egg() == false, "same-day re-collect blocked")
	var tm: Node = root.get_node("SignalBus").time_manager
	if tm != null:
		tm.set_time(2, 6, 0)
	_check(coop.collect_egg(), "egg regenerates next day")
	_check(int(gd.inventory.get("egg", 0)) == 2, "second egg granted")
	main.queue_free()
	print("\n=== CHICKEN TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("CHICKEN GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
