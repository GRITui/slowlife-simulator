extends SceneTree
# TASK-337 mountain cave gate — lazy unlock (default skill hides the spot),
# unlock on the next minute_ticked once skill caps at 3, immediate presence
# on a fresh boot when the save already had skill 3, real InteractArea
# (the @onready null-bug has shipped twice in this project), same 3-item
# ore roster as MiningSpot (no new items), and a statistical check that the
# rare ore comes up meaningfully more often at the cave than at the
# regular MiningSpot.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  mountain-cave :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  mountain-cave :: %s" % label)

func _initialize() -> void:
	var sb: Node = root.get_node("SignalBus")
	var gd: Node = root.get_node("GameData")
	# 1) Default skill (1) — MountainCaveSpot NOT present under World after
	# boot. Mirrors test_mining.gd's SceneTree + World.tscn-instantiation
	# pattern. Make sure the autoload starts in a known state for this
	# test so the "no spot at default skill" assertion is unambiguous.
	gd.mining_skill = 1
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	# Also assert it's NOT in World.tscn (would mean someone hard-coded it).
	var tscn_text: String = FileAccess.get_file_as_string("res://scenes/core/World.tscn")
	_check(not tscn_text.contains("[node name=\"MountainCaveSpot\""),
		"MountainCaveSpot is NOT hard-authored in World.tscn (dynamic only)")
	_check(main.get_node_or_null("MountainCaveSpot") == null,
		"MountainCaveSpot absent at default mining_skill=1")
	_check(int(gd.mining_skill) == 1, "mining_skill starts at 1 for this test")
	# 2) Setting skill to 3 and emitting one minute_ticked tick — the spot
	# should appear (lazy unlock via World's minute_ticked handler).
	gd.mining_skill = 3
	sb.minute_ticked.emit(1, 6, 0)
	await process_frame
	var cave: Node = main.get_node_or_null("MountainCaveSpot")
	_check(cave != null, "MountainCaveSpot appears after mining_skill=3 + minute_ticked")
	# 3) Fresh boot with skill already at 3: a brand-new World instance must
	# show the spot immediately, no tick required (proves the _ready() call
	# path covers loaded saves).
	main.queue_free()
	await process_frame
	gd.mining_skill = 3
	var main2: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main2)
	await process_frame
	await process_frame
	var cave2: Node = main2.get_node_or_null("MountainCaveSpot")
	_check(cave2 != null, "fresh boot with skill=3 shows MountainCaveSpot immediately (no tick needed)")
	# 4) Real InteractArea — this project has twice shipped the
	# @onready $InteractArea null-bug; do not repeat it.
	if cave2 == null:
		await process_frame
		quit(1)
		return
	_check(cave2.get("_area") != null, "MountainCaveSpot._area is a real Area2D (not null)")
	var area: Node = cave2.get("_area")
	if area != null:
		_check(area.get_class() == "Area2D", "InteractArea is an Area2D node")
		var has_circle: bool = false
		for child: Node in area.get_children():
			if child is CollisionShape2D and child.shape is CircleShape2D:
				var cs: CircleShape2D = child.shape
				if is_equal_approx(cs.radius, 56.0):
					has_circle = true
					break
		_check(has_circle, "InteractArea has CollisionShape2D with CircleShape2D radius 56")
	# Spot should be at the SE corner (tile 19,14) — verified-clear position.
	var pos: Vector2 = (cave2 as Node2D).position
	_check(is_equal_approx(pos.x, 19 * 48 + 24) and is_equal_approx(pos.y, 14 * 48 + 24),
		"MountainCaveSpot positioned at SE corner (936, 696)")
	# 5) Roster parity: dig at the cave and confirm the find came from the
	# same 3-item MiningSpot roster (no new items invented).
	gd.current_stamina = gd.max_stamina
	var pre_inv: Dictionary = gd.inventory.duplicate()
	var dig_ok: bool = cave2.call("dig")
	_check(dig_ok, "cave dig() with full stamina returns true")
	# Diff the inventory: exactly one of {copper_ore, iron_ore, silver_ore}
	# should have gone up by exactly 1, and nothing else changed.
	var diff_keys: Array = []
	for k: Variant in gd.inventory.keys():
		var pre_q: int = int(pre_inv.get(k, 0))
		var post_q: int = int(gd.inventory[k])
		if post_q != pre_q:
			diff_keys.append("%s:%d->%d" % [str(k), pre_q, post_q])
	# Also check keys that were removed entirely (shouldn't happen on a
	# successful dig, but guard against a phantom remove).
	for k: Variant in pre_inv.keys():
		if not gd.inventory.has(k):
			diff_keys.append("%s:removed" % str(k))
	_check(diff_keys.size() == 1, "exactly one inventory delta after a cave dig (got %d: %s)" % [
		diff_keys.size(), str(diff_keys)])
	if diff_keys.size() == 1:
		var only: String = String(diff_keys[0])
		var ore_match: bool = only.contains("copper_ore:") \
			or only.contains("iron_ore:") \
			or only.contains("silver_ore:")
		var qty_match: bool = only.ends_with("->1")
		_check(ore_match and qty_match,
			"dig delta is +1 of an existing ore item (got %s)" % only)
	# mining_skill must NOT have been bumped by the cave dig — that surface
	# belongs to MiningSpot.gd; the cave is downstream of the gate, not a
	# second path to it.
	_check(int(gd.mining_skill) == 3,
		"cave dig() does NOT bump mining_skill (stays at 3, got %d)" % int(gd.mining_skill))
	# 6) Statistical check: over many rolls, silver_ore comes up meaningfully
	# more often at the cave than at the regular MiningSpot. This is the
	# "richer vein" framing in action. Use a generous threshold (cave rate
	# > mining rate), don't chase an exact ratio against RNG.
	# Reset skill so the test owns the RNG: a long mining_spot session
	# would just hit the cap and start biasing the result anyway. Mine
	# just enough to keep both spots in the same skill bracket.
	gd.mining_skill = 3
	# Force both spots to dig_count so we can compare rates at the same
	# rarity-weighted point. Build a fresh MiningSpot + MountainCaveSpot
	# pair (cave2 already exists; instantiate a sibling MiningSpot for
	# the comparison).
	var mining_script: GDScript = load("res://scripts/interactables/MiningSpot.gd")
	var mining_spot: Node2D = mining_script.new() as Node2D
	mining_spot.name = "MiningSpotTestOnly"
	main2.add_child(mining_spot)
	await process_frame
	# Run the same number of rolls against each, and count silver_ore hits.
	# We seed RNG so the test is deterministic if rerun; the threshold is
	# "cave silver rate > mining silver rate" with enough rolls that the
	# inverted weights (rare 4.0 vs 1.2) are obvious.
	var seed_val: int = 1337
	seed(seed_val)
	var rolls: int = 200
	var mining_silver: int = 0
	var cave_silver: int = 0
	# Reset stamina at the top so soft-fail can't hide a hit.
	for i: int in rolls:
		gd.current_stamina = gd.max_stamina
		var picked: Dictionary = mining_spot._roll_ore() if mining_spot != null else {}
		if String(picked.get("id", "")) == "silver_ore":
			mining_silver += 1
		gd.current_stamina = gd.max_stamina
		var picked_cave: Dictionary = cave2.call("_roll_ore")
		if String(picked_cave.get("id", "")) == "silver_ore":
			cave_silver += 1
	_check(cave_silver > mining_silver,
		"rare ore (silver) comes up MORE at the cave (%d) than at MiningSpot (%d) over %d rolls" % [
			cave_silver, mining_silver, rolls])
	# And: cave silver rate should be a clear majority (rare weight 4.0
	# over total ~7.7 = ~52%, vs MiningSpot's 1.2/7.7 ~= 16%). Generous
	# check: cave silver rate > 30% of all rolls.
	_check(float(cave_silver) / float(rolls) > 0.30,
		"cave silver rate > 30%% of rolls (got %.1f%% = %d/%d)" % [
			100.0 * float(cave_silver) / float(rolls), cave_silver, rolls])
	# And for symmetry: mining silver rate should be the minority (< 30%).
	_check(float(mining_silver) / float(rolls) < 0.30,
		"MiningSpot silver rate < 30%% of rolls (got %.1f%% = %d/%d)" % [
			100.0 * float(mining_silver) / float(rolls), mining_silver, rolls])
	main2.queue_free()
	print("\n=== MOUNTAIN CAVE TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("MOUNTAIN CAVE GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
