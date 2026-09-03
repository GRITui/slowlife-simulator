extends SceneTree
# TASK-056 goat gate — daily-limited goat_milk, no-harm.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  goat :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  goat :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var goat: Node = main.get_node_or_null("Goat")
	_check(goat != null, "Goat instanced in pasture")
	_check(goat != null and goat.is_in_group("goat"), "goat tagged")
	if goat == null:
		await process_frame
		quit(1)
		return
	_check(goat.milk(), "milked day 1")
	_check(int(gd.inventory.get("goat_milk", 0)) == 1, "goat_milk granted")
	_check(goat.milk() == false, "same-day re-milk blocked")
	var tm: Node = root.get_node("SignalBus").time_manager
	if tm != null:
		tm.set_time(2, 6, 0)
	_check(goat.milk(), "milk regenerates next day")
	_check(int(gd.inventory.get("goat_milk", 0)) == 2, "second milk granted")
	main.queue_free()
	print("\n=== GOAT TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("GOAT GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
