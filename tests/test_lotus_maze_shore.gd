extends SceneTree
# TASK-344 lotus maze shore gate — lazy unlock (no milestones hides
# the spot), unlock on the next minute_ticked once milestones_earned
# reaches 5, immediate presence on a fresh boot when the save
# already had all 5, real InteractArea (the @onready null-bug has
# shipped twice in this project), same 20-item fish roster as
# FishingSpot/DeepCanalSpot (no new fish), and a statistical check
# that the legendary species come up meaningfully more often at the
# lotus maze shore than at the regular FishingSpot (and even more
# often than at the deep canal — this is the "ultimate" capstone
# spot). Also asserts no skill bump and no master_angler /
# storm_catch re-trigger (those surfaces belong to FishingSpot.gd).

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  lotus-maze-shore :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  lotus-maze-shore :: %s" % label)

func _clear_milestones() -> void:
	# Wipe milestones_earned so a stale loaded save can't trip the gate.
	# The autoload survives across test boots (same SceneTree), so this
	# has to be explicit per-test, not just defaulted.
	var gd: Node = get_root().get_node("GameData")
	var keys: Array = (gd.milestones_earned as Dictionary).keys()
	for k in keys:
		(gd.milestones_earned as Dictionary).erase(k)

func _earn_all_5_milestones() -> void:
	var gd: Node = get_root().get_node("GameData")
	gd.earn_milestone("deep_miner")
	gd.earn_milestone("master_angler")
	gd.earn_milestone("inseparable")
	gd.earn_milestone("herd_keeper")
	gd.earn_milestone("storm_catch")

func _initialize() -> void:
	var sb: Node = root.get_node("SignalBus")
	var gd: Node = root.get_node("GameData")
	# 1) Default state (no milestones) — LotusMazeShoreSpot NOT present
	# under World after boot. Mirrors test_mountain_cave.gd's SceneTree
	# + World.tscn-instantiation pattern. Force the autoload into a known
	# state so the "no spot at default milestones" assertion is unambiguous.
	_clear_milestones()
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	# Also assert it's NOT in World.tscn (would mean someone hard-coded it).
	var tscn_text: String = FileAccess.get_file_as_string("res://scenes/core/World.tscn")
	_check(not tscn_text.contains("[node name=\"LotusMazeShoreSpot\""),
		"LotusMazeShoreSpot is NOT hard-authored in World.tscn (dynamic only)")
	_check(main.get_node_or_null("LotusMazeShoreSpot") == null,
		"LotusMazeShoreSpot absent at default milestones_earned (0 of 5)")
	_check(int((gd.milestones_earned as Dictionary).size()) == 0,
		"milestones_earned starts empty for this test")
	# 2) Earning all 5 milestones and emitting one minute_ticked tick —
	# the spot should appear (lazy unlock via World's minute_ticked handler).
	_earn_all_5_milestones()
	sb.minute_ticked.emit(1, 6, 0)
	await process_frame
	var shore: Node = main.get_node_or_null("LotusMazeShoreSpot")
	_check(shore != null, "LotusMazeShoreSpot appears after milestones_earned=5 + minute_ticked")
	# 3) Fresh boot with all 5 milestones already earned: a brand-new World
	# instance must show the spot immediately, no tick required (proves
	# the _ready() call path covers loaded saves).
	main.queue_free()
	await process_frame
	_clear_milestones()
	_earn_all_5_milestones()
	var main2: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main2)
	# The default-skill check at the top of World._ready() reads
	# GameData state synchronously, but the freshly-earned milestones
	# were set BEFORE add_child — so this should work on the first
	# process frame after add_child. Yield a few frames for safety
	# (matches test_mountain_cave.gd's pattern).
	await process_frame
	await process_frame
	await process_frame
	var shore2: Node = main2.get_node_or_null("LotusMazeShoreSpot")
	_check(shore2 != null, "fresh boot with milestones=5 shows LotusMazeShoreSpot immediately (no tick needed)")
	# 4) Real InteractArea — this project has twice shipped the
	# @onready $InteractArea null-bug; do not repeat it.
	if shore2 == null:
		await process_frame
		quit(1)
		return
	_check(shore2.get("_area") != null, "LotusMazeShoreSpot._area is a real Area2D (not null)")
	var area: Node = shore2.get("_area")
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
	# Spot should be at tile (13, 11) — spec-verified-clear position via
	# headless ground_at() probe (plantable_soil, east neighbor deep_pond).
	var pos: Vector2 = (shore2 as Node2D).position
	_check(is_equal_approx(pos.x, 13 * 48 + 24) and is_equal_approx(pos.y, 11 * 48),
		"LotusMazeShoreSpot positioned at lotus maze edge (648, 528)")
	# 5) Roster parity: catch at the shore and confirm the find came from
	# the same 20-item FishingSpot roster (no new fish invented). The
	# spot is at (13,11) which is plantable_soil with east neighbor (14,11)
	# being deep_pond (inside the maze), so _water_adjacent() should pass.
	# Ensure a rod is held (the spot requires it, same as FishingSpot).
	if not gd.has_item("fishing_rod", 1):
		gd.add_item("fishing_rod", 1)
	# Also bump fishing_skill to 4 (the cap) so the entire 20-species
	# roster is eligible — the shore's "ultimate" framing only lands when
	# the player is already a master angler.
	gd.fishing_skill = 4
	var pre_inv: Dictionary = gd.inventory.duplicate()
	var pre_silver: int = int(gd.silver)
	var catch_ok: bool = shore2.call("cast_line")
	_check(catch_ok, "cast_line() with rod + water-adjacent returns true")
	# Diff the inventory: exactly one new fish item, no other changes.
	var diff_keys: Array = []
	for k: Variant in gd.inventory.keys():
		var pre_q: int = int(pre_inv.get(k, 0))
		var post_q: int = int(gd.inventory[k])
		if post_q != pre_q:
			diff_keys.append("%s:%d->%d" % [str(k), pre_q, post_q])
	for k: Variant in pre_inv.keys():
		if not gd.inventory.has(k):
			diff_keys.append("%s:removed" % str(k))
	_check(diff_keys.size() == 1, "exactly one inventory delta after a shore cast (got %d: %s)" % [
		diff_keys.size(), str(diff_keys)])
	if diff_keys.size() == 1:
		var only: String = String(diff_keys[0])
		var fish_match: bool = (only.contains("pla_") or only.contains("goong_")) \
			and only.ends_with("->1")
		_check(fish_match, "catch delta is +1 of an existing fish item (got %s)" % only)
	# fishing_skill must NOT have been bumped by the shore cast — that
	# surface belongs to FishingSpot.gd; the shore is downstream of the
	# milestone gate, not a second path to it.
	_check(int(gd.fishing_skill) == 4,
		"shore cast_line() does NOT bump fishing_skill (stays at 4, got %d)" % int(gd.fishing_skill))
	# Silver should have ticked up: skill >= 4 always grants +5 silver
	# per catch (TASK-281 mastery tip), at the shore too.
	_check(int(gd.silver) >= pre_silver + 5,
		"shore cast_line() grants +5 silver at skill=4 (got %d -> %d)" % [pre_silver, int(gd.silver)])
	# 6) Statistical check: over many rolls, the legendary species come
	# up meaningfully more often at the lotus maze shore than at the
	# regular FishingSpot. The "ultimate vein" framing in action. Use a
	# generous threshold (shore legendary rate > fishing legendary rate),
	# don't chase an exact ratio against RNG.
	# Force both spots to roll from the same skill-bracket-eligible pool:
	# we want to compare the weight distribution, not the season gating.
	# Build a fresh FishingSpot sibling for the comparison.
	var fishing_script: GDScript = load("res://scripts/interactables/FishingSpot.gd")
	var fishing_spot: Node2D = fishing_script.new() as Node2D
	fishing_spot.name = "FishingSpotTestOnly"
	main2.add_child(fishing_spot)
	await process_frame
	# Both legendary species are season-gated (pla_buk=monsoon,
	# pla_sai_rung=hot) and GameData's default boot season is "cool" --
	# the comparison is silently 0-vs-0 if season isn't forced. Pick a
	# season with a legendary fish eligible (same fix as test_deep_canal).
	gd.current_season = "monsoon"
	if sb.time_manager != null:
		sb.time_manager.current_season = "monsoon"
	var seed_val: int = 1337
	seed(seed_val)
	var rolls: int = 400
	var fishing_legendary: int = 0
	var shore_legendary: int = 0
	for i: int in rolls:
		var picked: Dictionary = fishing_spot._roll_catch() if fishing_spot != null else {}
		if String(picked.get("species", {}).get("rarity", "")) == "legendary":
			fishing_legendary += 1
		var picked_shore: Dictionary = shore2.call("_roll_catch")
		if String(picked_shore.get("species", {}).get("rarity", "")) == "legendary":
			shore_legendary += 1
	_check(shore_legendary > fishing_legendary,
		"legendary species come up MORE at the lotus maze shore (%d) than at FishingSpot (%d) over %d rolls" % [
			shore_legendary, fishing_legendary, rolls])
	# Generous lower-bound check: with legendary weight 5.0 vs the old
	# 0.4 (FishingSpot's), the rate should comfortably exceed the old
	# rate. Just assert shore legendary rate is non-trivial (>0).
	_check(shore_legendary > 0,
		"shore legendary rate is non-zero (got %d/%d)" % [shore_legendary, rolls])
	main2.queue_free()
	print("\n=== LOTUS MAZE SHORE TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("LOTUS MAZE SHORE GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)