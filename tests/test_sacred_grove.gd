extends SceneTree
# TASK-343 sacred grove gate — lazy unlock (default bond hides the spot),
# unlock on the next minute_ticked once companion_bond_tier caps at 4,
# immediate presence on a fresh boot when the save already had tier 4,
# same "wood" item as ForestTree (no new item), daily-gated per spot, and
# the rich-vein framing: yield is higher than ForestTree's (3 base + axe
# bonus, vs ForestTree's 1 base + axe bonus). Also asserts the "inseparable"
# milestone is NOT re-triggered (the companion system owns that).

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  sacred-grove :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  sacred-grove :: %s" % label)

func _initialize() -> void:
	var sb: Node = root.get_node("SignalBus")
	var gd: Node = root.get_node("GameData")
	# 1) Default bond (0, tier 0) — SacredGroveSpot NOT present under World
	# after boot. Mirrors test_mountain_cave.gd's SceneTree + World.tscn
	# pattern.
	gd.companion_bond = 0
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	# Also assert it's NOT in World.tscn (would mean someone hard-coded it).
	var tscn_text: String = FileAccess.get_file_as_string("res://scenes/core/World.tscn")
	_check(not tscn_text.contains("[node name=\"SacredGroveSpot\""),
		"SacredGroveSpot is NOT hard-authored in World.tscn (dynamic only)")
	_check(main.get_node_or_null("SacredGroveSpot") == null,
		"SacredGroveSpot absent at default companion_bond_tier=0")
	_check(int(gd.companion_bond_tier()) == 0, "companion_bond_tier starts at 0 for this test")
	# 2) Setting bond to cap (100, tier 4) and emitting one minute_ticked
	# tick — the spot should appear (lazy unlock via World's minute_ticked
	# handler).
	gd.companion_bond = 100
	sb.minute_ticked.emit(1, 6, 0)
	await process_frame
	var grove: Node = main.get_node_or_null("SacredGroveSpot")
	_check(grove != null, "SacredGroveSpot appears after companion_bond_tier=4 + minute_ticked")
	# 3) Fresh boot with tier already at 4: a brand-new World instance
	# must show the spot immediately, no tick required (proves the
	# _ready() call path covers loaded saves).
	main.queue_free()
	await process_frame
	gd.companion_bond = 100
	var main2: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main2)
	await process_frame
	await process_frame
	var grove2: Node = main2.get_node_or_null("SacredGroveSpot")
	_check(grove2 != null, "fresh boot with tier=4 shows SacredGroveSpot immediately (no tick needed)")
	if grove2 == null:
		await process_frame
		quit(1)
		return
	# 4) Spot should be at the verified-clear position (tile 19, 6) —
	# the spec verified via headless ground_at() probe that tile (19,6)
	# is ground_grass, near the existing ForestTree cluster
	# (18,3)/(18,5)/(19,4) for thematic proximity, one tile clear of
	# ForestTree19_4.
	var pos: Vector2 = (grove2 as Node2D).position
	_check(is_equal_approx(pos.x, 19 * 48 + 24) and is_equal_approx(pos.y, 6 * 48),
		"SacredGroveSpot positioned near ForestTree cluster (936, 288)")
	# 5) Chop: succeeds, grants 3 wood (no axe — the rich-vein yield,
	# higher than ForestTree's 1 base). Wood has no rarity tiers to
	# invert; the daily yield IS the "richer vein" framing.
	var pre_wood: int = int(gd.inventory.get("wood", 0))
	var chop_ok: bool = grove2.call("chop")
	_check(chop_ok, "grove chop() returns true on first chop of the day")
	_check(int(gd.inventory.get("wood", 0)) == pre_wood + 3,
		"grove chop() grants +3 wood with no axe (got %d -> %d, expected +3)" % [
			pre_wood, int(gd.inventory.get("wood", 0))])
	# 6) Daily-gated per spot: a second chop on the same day returns
	# false with no wood added. Mirrors ForestTree's once-per-day
	# logic.
	pre_wood = int(gd.inventory.get("wood", 0))
	var re_chop: bool = grove2.call("chop")
	_check(re_chop == false, "grove same-day re-chop is blocked (daily gate)")
	_check(int(gd.inventory.get("wood", 0)) == pre_wood,
		"same-day re-chop does not grant wood (still %d, expected %d)" % [
			int(gd.inventory.get("wood", 0)), pre_wood])
	# 7) Yield comparison: build a fresh ForestTree for the day and
	# confirm the grove strictly out-yields it. ForestTree's chop()
	# needs the same daily-gate logic and a separate day so we set
	# TimeManager to a new day first.
	var tm: Node = sb.time_manager
	if tm != null:
		tm.set_time(2, 6, 0)
	var forest_scene: PackedScene = load("res://scenes/entities/ForestTree.tscn")
	var tree: Node2D = forest_scene.instantiate() as Node2D
	tree.name = "ForestTreeTestOnly"
	main2.add_child(tree)
	await process_frame
	# Clear axe from the comparison so the bonus is identical for both.
	gd.inventory.erase("axe")
	gd.inventory.erase("wood")
	_check(tree.chop(), "ForestTree chop() succeeds on a new day, no axe")
	var forest_wood: int = int(gd.inventory.get("wood", 0))
	_check(forest_wood == 1,
		"ForestTree yields +1 wood with no axe (got %d, expected 1)" % forest_wood)
	# Advance one more day for the grove (the new day above already
	# cleared the grove's per-day gate).
	if tm != null:
		tm.set_time(3, 6, 0)
	var grove_wood: int = int(gd.inventory.get("wood", 0))
	var grove_chop2: bool = grove2.call("chop")
	_check(grove_chop2, "grove chop() succeeds on a new day, no axe")
	var post_grove_wood: int = int(gd.inventory.get("wood", 0))
	_check(post_grove_wood - grove_wood > forest_wood,
		"grove yield (%d) is strictly higher than ForestTree yield (%d) on a fresh day" % [
			post_grove_wood - grove_wood, forest_wood])
	# 8) Axe bonus: with axe held, the grove yields 4 (3 base + 1 bonus),
	# mirroring ForestTree's +1 bonus pattern.
	gd.add_item("axe", 1)
	if tm != null:
		tm.set_time(4, 6, 0)
	var axe_pre: int = int(gd.inventory.get("wood", 0))
	_check(grove2.call("chop"),
		"grove chop() with axe succeeds on a new day")
	var axe_post: int = int(gd.inventory.get("wood", 0))
	_check(axe_post - axe_pre == 4,
		"grove with axe yields +4 wood (got +%d, expected 4)" % (axe_post - axe_pre))
	# 9) No inseparable milestone trigger on the spot itself. The
	# companion system owns that — this spot's chop is independent of
	# the cat-bond milestone path.
	gd.milestones_earned = {} # reset
	if grove2.call("chop") == false and tm != null:
		# Daily gate will reject — push to a new day for the milestone
		# check to be meaningful.
		tm.set_time(5, 6, 0)
		grove2.call("chop")
	_check(not gd.milestones_earned.has("inseparable"),
		"grove chop() does NOT re-trigger the inseparable milestone (companion system owns it)")
	main2.queue_free()
	print("\n=== SACRED GROVE TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("SACRED GROVE GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
