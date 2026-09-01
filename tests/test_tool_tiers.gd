extends SceneTree
# TASK-060 tool tier gate — upgrade purchase + watering/hoe/sickle effects.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  tools :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  tools :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var gm: Node = main.get_node_or_null("GridManager")
	var crop: Resource = load("res://data/crops/jasmine_rice.tres")
	# Defaults.
	_check(int(gd.tool_tier("watering_can")) == 1, "can starts tier 1")
	_check(gd.upgrade_tool("watering_can") == false, "upgrade blocked without rice")
	gd.add_item("rice_grain", 40)
	_check(gd.upgrade_tool("watering_can"), "can upgrade to tier 2")
	_check(gd.upgrade_tool("watering_can"), "can upgrade to tier 3")
	_check(gd.upgrade_tool("watering_can") == false, "tier 3 is cap")
	# Watering effect: tier-3 can pre-advances growth 90 minutes.
	gd.current_stamina = gd.max_stamina
	var cell := Vector2i(4, 6)
	gm.plant(cell, crop)
	var ps: Variant = gm.plots[cell]
	var before: int = int(ps.minutes_in_stage)
	gm.water(cell)
	_check(int(gm.plots[cell].minutes_in_stage) >= before + 90,
		"tier-3 watering pre-advances >= 90 minutes")
	# Hoe discount: plant stamina cost reduced 40% at hoe tier 3.
	gd.add_item("rice_grain", 60) # fund tier-2/3 purchases (8 + 16 each)
	gd.upgrade_tool("hoe")
	gd.upgrade_tool("hoe")
	gd.current_stamina = gd.max_stamina
	var stamina_before: float = gd.current_stamina
	gm.plant(Vector2i(5, 6), crop)
	var cost: float = stamina_before - gd.current_stamina
	var full: float = float(crop.stamina_cost_plant)
	_check(cost <= full * 0.65, "hoe tier 3 discount >= 40%% (cost %.1f vs %.1f)" % [cost, full])
	# Sickle bonus: tier 3 -> +2 yield.
	gd.upgrade_tool("sickle")
	gd.upgrade_tool("sickle")
	ps.stage = crop.total_stages - 1
	gm.water(Vector2i(4, 6))
	var y: int = gm.harvest(Vector2i(4, 6))
	_check(y >= crop.get_yield("cool", "clear") + 2, "sickle tier 3 grants +2 yield (got %d)" % y)
	main.queue_free()
	print("\n=== TOOL-TIER TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("TOOL-TIER GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
