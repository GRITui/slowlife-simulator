extends SceneTree
# TASK-281 fishing payoff gate — skill 4: big-bias + silver tip.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  fish-payoff :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  fish-payoff :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var spot: Node = main.get_node_or_null("FishingSpot")
	var tm: Node = root.get_node("SignalBus").time_manager
	if spot == null or tm == null:
		await process_frame
		quit(1)
		return
	gd.inventory.clear()
	gd.add_item("fishing_rod", 1)
	tm.set_season("cool")
	# Push to skill 4 directly (unit-level).
	gd.fishing_skill = 4
	var big: int = 0
	var silver_before: int = int(gd.silver)
	for i: int in 30:
		spot.cast_line()
		if spot._roll_catch().get("size", "") == "big" if spot._roll_catch().has("size") else false:
			pass
	# count big catches from inventory (any *_big item gained)
	for k: String in gd.inventory.keys():
		if k.ends_with("_big"):
			big += int(gd.inventory[k])
	_check(big >= 3, "skill-4 big bias: %d big fish in 30 casts" % big)
	_check(int(gd.silver) == silver_before + 5 * 30, "mastery tip: +5 silver x 30 casts (%d -> %d)" % [silver_before, int(gd.silver)])
	# Skill 1 control: no silver tip.
	gd.fishing_skill = 1
	var s1: int = int(gd.silver)
	spot.cast_line()
	_check(int(gd.silver) == s1, "skill 1 grants no silver tip")
	main.queue_free()
	print("\n=== FISH-PAYOFF TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("FISH-PAYOFF GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
