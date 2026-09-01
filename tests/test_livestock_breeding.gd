extends SceneTree
# TASK-323 split B — livestock breeding (herd-count sink). Yield scales
# with chicken_count/buffalo_count; breeding is an automatic side effect
# of the daily interact, gated on hearts >= 2, count < cap, and silver.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  breeding :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  breeding :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var coop: Node = main.get_node_or_null("ChickenCoop")
	var buffalo: Node = main.get_node_or_null("Buffalo")
	_check(coop != null, "ChickenCoop present")
	_check(buffalo != null, "Buffalo present")
	var tm: Node = root.get_node("SignalBus").time_manager
	var day: int = 1

	# --- Starting counts ---
	_check(int(gd.chicken_count) == 1, "chicken_count starts at 1")
	_check(int(gd.buffalo_count) == 1, "buffalo_count starts at 1")

	# --- Yield scales with count, quality tier is an independent axis ---
	gd.chicken_affinity = 0
	gd.inventory.erase("egg")
	gd.inventory.erase("egg_gold")
	gd.silver = 0
	if tm != null:
		day += 1; tm.set_time(day, 6, 0)
	coop.collect_egg()
	_check(int(gd.inventory.get("egg", 0)) == 1, "count 1 -> 1 egg granted")
	gd.chicken_count = 3
	gd.inventory.erase("egg")
	if tm != null:
		day += 1; tm.set_time(day, 6, 0)
	coop.collect_egg()
	_check(int(gd.inventory.get("egg", 0)) == 3, "count 3 -> 3 eggs granted")
	# Quality tier still gates on hearts, unaffected by count.
	gd.add_chicken_affinity(75) # -> 3 hearts
	gd.inventory.erase("egg")
	gd.inventory.erase("egg_gold")
	if tm != null:
		day += 1; tm.set_time(day, 6, 0)
	coop.collect_egg()
	_check(int(gd.inventory.get("egg_gold", 0)) == 3 and int(gd.inventory.get("egg", 0)) == 0,
		"at 3 hearts + count 3: 3 gold eggs, no base eggs (tier and count are independent)")

	gd.buffalo_affinity = 0
	gd.inventory.erase("buffalo_milk")
	gd.inventory.erase("buffalo_milk_high")
	gd.buffalo_count = 1
	if tm != null:
		day += 1; tm.set_time(day, 6, 0)
	buffalo.interact()
	_check(int(gd.inventory.get("buffalo_milk", 0)) == 1, "buffalo count 1 -> 1 milk granted")
	gd.buffalo_count = 3
	gd.inventory.erase("buffalo_milk")
	if tm != null:
		day += 1; tm.set_time(day, 6, 0)
	buffalo.interact()
	_check(int(gd.inventory.get("buffalo_milk", 0)) == 3, "buffalo count 3 -> 3 milk granted")

	# --- Breeding gating: hearts < 2 -> never breeds, even with silver ---
	gd.chicken_affinity = 0 # 0 hearts
	gd.chicken_count = 1
	gd.silver = 1000
	if tm != null:
		day += 1; tm.set_time(day, 6, 0)
	coop.collect_egg()
	_check(int(gd.chicken_count) == 1, "0 hearts -> no breeding even with silver")
	_check(int(gd.silver) == 1000, "silver untouched when hearts < 2 (no speculative spend)")

	# --- Breeding gating: hearts >= 2, count < cap, silver available -> breeds ---
	gd.add_chicken_affinity(50) # -> 2 hearts total (0 + 50 = 50 -> 2 hearts)
	gd.silver = 40
	if tm != null:
		day += 1; tm.set_time(day, 6, 0)
	coop.collect_egg()
	_check(int(gd.chicken_count) == 2, "hearts >= 2 + enough silver -> chicken_count grows to 2")
	_check(int(gd.silver) == 0, "silver deducted by exactly 40 on successful breed")

	# --- Insufficient silver: silent skip, egg still granted, count unchanged ---
	gd.silver = 5 # not enough for the next breed (40)
	var eggs_before: int = int(gd.inventory.get("egg", 0)) + int(gd.inventory.get("egg_gold", 0))
	if tm != null:
		day += 1; tm.set_time(day, 6, 0)
	var ok: bool = coop.collect_egg()
	_check(ok, "collection still succeeds when breeding silver is insufficient")
	_check(int(gd.chicken_count) == 2, "chicken_count unchanged on insufficient-silver skip")
	_check(int(gd.silver) == 5, "silver untouched on insufficient-silver skip (no speculative spend)")
	var eggs_after: int = int(gd.inventory.get("egg", 0)) + int(gd.inventory.get("egg_gold", 0))
	_check(eggs_after == eggs_before + gd.chicken_count, "normal egg yield unaffected by breeding skip")

	# --- Cap: never exceeds 3 regardless of hearts/silver ---
	gd.chicken_count = 3
	gd.silver = 1000
	if tm != null:
		day += 1; tm.set_time(day, 6, 0)
	coop.collect_egg()
	_check(int(gd.chicken_count) == 3, "chicken_count capped at 3")
	_check(int(gd.silver) == 1000, "silver untouched at cap (no speculative spend past cap)")

	# --- Same gating shape for buffalo (cheaper check, same logic path) ---
	gd.buffalo_affinity = 0
	gd.buffalo_count = 1
	gd.silver = 60
	if tm != null:
		day += 1; tm.set_time(day, 6, 0)
	buffalo.interact()
	_check(int(gd.buffalo_count) == 1, "buffalo: 0 hearts -> no breeding even with silver")
	gd.add_buffalo_affinity(50) # -> 2 hearts
	gd.silver = 60
	if tm != null:
		day += 1; tm.set_time(day, 6, 0)
	buffalo.interact()
	_check(int(gd.buffalo_count) == 2, "buffalo: hearts >= 2 + enough silver -> count grows to 2")
	_check(int(gd.silver) == 0, "buffalo: silver deducted by exactly 60 on successful breed")
	gd.buffalo_count = 3
	gd.silver = 1000
	if tm != null:
		day += 1; tm.set_time(day, 6, 0)
	buffalo.interact()
	_check(int(gd.buffalo_count) == 3, "buffalo_count capped at 3")

	main.queue_free()
	print("\n=== BREEDING TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("BREEDING GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
