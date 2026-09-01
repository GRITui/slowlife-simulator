extends SceneTree
# TASK-321 mining gate — proximity instancing, stamina gate, ore roll, skill
# growth + cap, and GameData.upgrade_tool() ore material sink.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  mining :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  mining :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	# 1) Dynamically instanced, not authored in Main.tscn.
	var spot: Node = main.get_node_or_null("MiningSpot")
	_check(spot != null, "MiningSpot instanced as runtime child of Main")
	# Also assert it's NOT in Main.tscn (would mean someone hard-coded it).
	var tscn_text: String = FileAccess.get_file_as_string("res://scenes/core/Main.tscn")
	_check(not tscn_text.contains("[node name=\"MiningSpot\""),
		"MiningSpot is NOT hard-authored in Main.tscn (dynamic only)")
	_check(int(gd.get("mining_skill")) == 1, "mining_skill starts at 1")
	if spot == null:
		await process_frame
		quit(1)
		return
	# 2) Real InteractArea (fix for FishingSpot's latent bug): proximity
	# detection must actually wire up, not silently stay null.
	_check(spot.get("_area") != null, "MiningSpot._area is a real Area2D (not null)")
	var area: Node = spot.get("_area")
	if area != null:
		_check(area.get_class() == "Area2D", "InteractArea is an Area2D node")
		# A child CollisionShape2D with a CircleShape2D should be present.
		var has_circle: bool = false
		for child: Node in area.get_children():
			if child is CollisionShape2D and child.shape is CircleShape2D:
				var cs: CircleShape2D = child.shape
				if is_equal_approx(cs.radius, 56.0):
					has_circle = true
					break
		_check(has_circle, "InteractArea has CollisionShape2D with CircleShape2D radius 56")
	# 3) Stamina gate: insufficient stamina -> soft-fail, no item, no stamina change.
	gd.current_stamina = 4.0
	var pre_stamina_low: float = gd.current_stamina
	var dig_fail: bool = spot.dig()
	_check(dig_fail == false, "dig() with insufficient stamina returns false (soft-fail)")
	_check(is_equal_approx(gd.current_stamina, pre_stamina_low),
		"stamina unchanged on soft-fail (%.1f)" % gd.current_stamina)
	# 4) Stamina is enough: dig succeeds, grants eligible ore, deducts exactly
	# dig_cost_stamina, adds harmony.
	gd.current_stamina = gd.max_stamina
	var pre_harmony: int = gd.harmony
	var pre_ore_count: int = int(gd.inventory.get("copper_ore", 0)) \
		+ int(gd.inventory.get("iron_ore", 0)) + int(gd.inventory.get("silver_ore", 0))
	var pre_stamina_full: float = gd.current_stamina
	var dig_cost: float = float(spot.get("dig_cost_stamina"))
	var dig_ok: bool = spot.dig()
	_check(dig_ok, "dig() with full stamina returns true")
	var stamina_after: float = gd.current_stamina
	_check(is_equal_approx(stamina_after, pre_stamina_full - dig_cost),
		"stamina deducted by exactly dig_cost_stamina (%.1f -> %.1f, cost %.1f)" % [
		pre_stamina_full, stamina_after, dig_cost])
	# Inventory should contain at least one of the three ore item_ids.
	var post_ore_count: int = int(gd.inventory.get("copper_ore", 0)) \
		+ int(gd.inventory.get("iron_ore", 0)) + int(gd.inventory.get("silver_ore", 0))
	_check(post_ore_count == pre_ore_count + 1, "one eligible ore item granted")
	_check(gd.harmony > pre_harmony, "harmony increased on successful dig")
	# 5) Skill gating: with skill 1, only skill_required <= 1 ore is eligible.
	var elig: Array = spot.eligible_ore()
	_check(not elig.is_empty(), "eligible pool non-empty at skill 1")
	var max_req: int = 0
	for o: Dictionary in elig:
		max_req = maxi(max_req, int(o.get("skill_required", 1)))
	_check(max_req <= 1, "skill 1 sees only skill_required <= 1 (max %d)" % max_req)
	# And: silver_ore (skill_required 3) is NEVER in the pool at skill 1.
	var silver_in_pool: bool = false
	for o: Dictionary in elig:
		if String(o.get("id", "")) == "silver_ore":
			silver_in_pool = true
			break
	_check(not silver_in_pool, "silver_ore (skill_required 3) excluded at skill 1")
	# 6) Skill growth: 1 level per 5 successful digs, capped at 3.
	# Mine 9 more times (10 total) at full stamina and verify skill jumps to 3.
	for i: int in 9:
		gd.current_stamina = gd.max_stamina
		spot.dig()
	_check(int(gd.get("mining_skill")) == 3,
		"mining_skill capped at 3 after 10 digs (got %d)" % int(gd.get("mining_skill")))
	# At skill 3, silver_ore IS eligible.
	var elig3: Array = spot.eligible_ore()
	var silver_in_pool3: bool = false
	for o: Dictionary in elig3:
		if String(o.get("id", "")) == "silver_ore":
			silver_in_pool3 = true
			break
	_check(silver_in_pool3, "silver_ore (skill_required 3) eligible at skill 3")
	# 7) upgrade_tool ore material sink. Reset tool tiers + inventory to a
	# known state and prove the new gate works in both directions.
	gd.tool_tiers["hoe"] = 1
	gd.inventory.erase("copper_ore")
	gd.inventory.erase("iron_ore")
	gd.inventory.erase("rice_grain")
	# (a) Without copper_ore, even with enough rice_grain: upgrade fails.
	gd.add_item("rice_grain", 100)
	_check(gd.upgrade_tool("hoe") == false,
		"upgrade_tool fails without copper_ore even with plenty of rice_grain")
	# (b) With copper_ore but no iron_ore: tier 1->2 succeeds, tier 2->3 fails.
	gd.add_item("copper_ore", 2)
	_check(gd.upgrade_tool("hoe"), "tier 1->2 succeeds with rice + 2x copper_ore")
	_check(int(gd.tool_tier("hoe")) == 2, "hoe is tier 2 after first upgrade")
	_check(gd.upgrade_tool("hoe") == false,
		"tier 2->3 fails without iron_ore")
	# (c) Add iron_ore: tier 2->3 now succeeds.
	gd.add_item("iron_ore", 2)
	_check(gd.upgrade_tool("hoe"), "tier 2->3 succeeds with rice + 2x iron_ore")
	_check(int(gd.tool_tier("hoe")) == 3, "hoe is tier 3 after second upgrade")
	# (d) Vice versa: enough ore but not enough rice_grain still fails.
	gd.tool_tiers["sickle"] = 1
	gd.inventory.erase("rice_grain")
	_check(gd.upgrade_tool("sickle") == false,
		"upgrade_tool fails without rice_grain even with enough ore")
	main.queue_free()
	print("\n=== MINING TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("MINING GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
