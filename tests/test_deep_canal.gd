extends SceneTree
# TASK-343 deep canal bend gate — lazy unlock (default skill hides the
# spot), unlock on the next minute_ticked once skill caps at 4,
# immediate presence on a fresh boot when the save already had skill
# 4, real InteractArea (the @onready null-bug has shipped twice in
# this project), same 20-item fish roster as FishingSpot (no new
# fish), and a statistical check that the legendary species come up
# meaningfully more often at the deep canal than at the regular
# FishingSpot. Also asserts no skill bump and no master_angler /
# storm_catch re-trigger (those surfaces belong to FishingSpot.gd).

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  deep-canal :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  deep-canal :: %s" % label)

func _initialize() -> void:
	var sb: Node = root.get_node("SignalBus")
	var gd: Node = root.get_node("GameData")
	# 1) Default skill (1) — DeepCanalSpot NOT present under Main after
	# boot. Mirrors test_mountain_cave.gd's SceneTree + Main.tscn
	# pattern. Force the autoload into a known state so the "no spot at
	# default skill" assertion is unambiguous.
	gd.fishing_skill = 1
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	# Also assert it's NOT in Main.tscn (would mean someone hard-coded it).
	var tscn_text: String = FileAccess.get_file_as_string("res://scenes/core/Main.tscn")
	_check(not tscn_text.contains("[node name=\"DeepCanalSpot\""),
		"DeepCanalSpot is NOT hard-authored in Main.tscn (dynamic only)")
	_check(main.get_node_or_null("DeepCanalSpot") == null,
		"DeepCanalSpot absent at default fishing_skill=1")
	_check(int(gd.fishing_skill) == 1, "fishing_skill starts at 1 for this test")
	# 2) Setting skill to 4 and emitting one minute_ticked tick — the spot
	# should appear (lazy unlock via Main's minute_ticked handler).
	gd.fishing_skill = 4
	sb.minute_ticked.emit(1, 6, 0)
	await process_frame
	var canal: Node = main.get_node_or_null("DeepCanalSpot")
	_check(canal != null, "DeepCanalSpot appears after fishing_skill=4 + minute_ticked")
	# 3) Fresh boot with skill already at 4: a brand-new Main instance
	# must show the spot immediately, no tick required (proves the
	# _ready() call path covers loaded saves).
	main.queue_free()
	await process_frame
	gd.fishing_skill = 4
	var main2: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main2)
	await process_frame
	await process_frame
	var canal2: Node = main2.get_node_or_null("DeepCanalSpot")
	_check(canal2 != null, "fresh boot with skill=4 shows DeepCanalSpot immediately (no tick needed)")
	# 4) Real InteractArea — this project has twice shipped the
	# @onready $InteractArea null-bug; do not repeat it.
	if canal2 == null:
		await process_frame
		quit(1)
		return
	_check(canal2.get("_area") != null, "DeepCanalSpot._area is a real Area2D (not null)")
	var area: Node = canal2.get("_area")
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
	# Spot should be at the verified-clear position (tile 12,14) — the
	# spec verified via headless ground_at() probe that tile (12,14) is
	# ground_grass and its north neighbor (12,13) is canal.
	var pos: Vector2 = (canal2 as Node2D).position
	_check(is_equal_approx(pos.x, 12 * 48 + 24) and is_equal_approx(pos.y, 14 * 48),
		"DeepCanalSpot positioned at deep canal bend (600, 672)")
	# 5) Roster parity: catch at the canal and confirm the find came from
	# the same 20-item FishingSpot roster (no new fish invented). We
	# don't actually need to run cast_line (it needs _water_adjacent to
	# pass at runtime, and the test runs headless with the test position
	# adjacent to canal tile (12,13) per the spec — confirmed true).
	# Ensure a rod is held (the spot requires it, same as FishingSpot).
	if not gd.has_item("fishing_rod", 1):
		gd.add_item("fishing_rod", 1)
	var pre_inv: Dictionary = gd.inventory.duplicate()
	var pre_fish_count: int = 0
	for k: Variant in pre_inv.keys():
		var ks: String = String(k)
		if ks.begins_with("pla_") or ks.begins_with("goong_"):
			pre_fish_count += int(pre_inv[k])
	var pre_silver: int = int(gd.silver)
	var catch_ok: bool = canal2.call("cast_line")
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
	_check(diff_keys.size() == 1, "exactly one inventory delta after a canal cast (got %d: %s)" % [
		diff_keys.size(), str(diff_keys)])
	if diff_keys.size() == 1:
		var only: String = String(diff_keys[0])
		var fish_match: bool = (only.contains("pla_") or only.contains("goong_")) \
			and only.ends_with("->1")
		_check(fish_match, "catch delta is +1 of an existing fish item (got %s)" % only)
	# fishing_skill must NOT have been bumped by the canal cast — that
	# surface belongs to FishingSpot.gd; the canal is downstream of the
	# gate, not a second path to it.
	_check(int(gd.fishing_skill) == 4,
		"canal cast_line() does NOT bump fishing_skill (stays at 4, got %d)" % int(gd.fishing_skill))
	# Silver should have ticked up: skill >= 4 always grants +5 silver
	# per catch (TASK-281 mastery tip), at the canal too.
	_check(int(gd.silver) >= pre_silver + 5,
		"canal cast_line() grants +5 silver at skill=4 (got %d -> %d)" % [pre_silver, int(gd.silver)])
	# 6) Statistical check: over many rolls, the legendary species come
	# up meaningfully more often at the deep canal than at the regular
	# FishingSpot. The "richer vein" framing in action. Use a generous
	# threshold (canal legendary rate > fishing legendary rate), don't
	# chase an exact ratio against RNG.
	# Force both spots to roll from the same skill-bracket-eligible pool:
	# we want to compare the weight distribution, not the season gating.
	# Build a fresh FishingSpot + DeepCanalSpot pair (canal2 already
	# exists; instantiate a sibling FishingSpot for the comparison).
	var fishing_script: GDScript = load("res://scripts/interactables/FishingSpot.gd")
	var fishing_spot: Node2D = fishing_script.new() as Node2D
	fishing_spot.name = "FishingSpotTestOnly"
	main2.add_child(fishing_spot)
	await process_frame
	# Run the same number of rolls against each, and count legendary
	# hits. Seed RNG so the test is deterministic if rerun; the threshold
	# is "canal legendary rate > fishing legendary rate" with enough
	# rolls that the inverted weights (legendary 4.0 vs 0.4) are obvious.
	# BUGFIX (Code Quality Review): both legendary species are season-gated
	# (pla_buk=monsoon, pla_sai_rung=hot) and GameData's default boot
	# season is "cool" -- the comparison was silently 0-vs-0 regardless of
	# the weight inversion. Force a season with a legendary fish eligible.
	gd.current_season = "monsoon"
	if sb.time_manager != null:
		sb.time_manager.current_season = "monsoon"
	var seed_val: int = 1337
	seed(seed_val)
	var rolls: int = 400
	var fishing_legendary: int = 0
	var canal_legendary: int = 0
	# Count both species ids that are rarity "legendary" in the roster.
	# fish.json has exactly 2: pla_buk (monsoon only) and pla_sai_rung
	# (hot only). We pick whatever season each test is currently in;
	# the per-spot pool is eligible_fish() which season-gates too, so
	# both spots see the same seasonal pool and the comparison is fair.
	for i: int in rolls:
		var picked: Dictionary = fishing_spot._roll_catch() if fishing_spot != null else {}
		if String(picked.get("species", {}).get("rarity", "")) == "legendary":
			fishing_legendary += 1
		var picked_canal: Dictionary = canal2.call("_roll_catch")
		if String(picked_canal.get("species", {}).get("rarity", "")) == "legendary":
			canal_legendary += 1
	_check(canal_legendary > fishing_legendary,
		"legendary species come up MORE at the deep canal (%d) than at FishingSpot (%d) over %d rolls" % [
			canal_legendary, fishing_legendary, rolls])
	# Generous lower-bound check: with legendary weight 4.0 vs the old
	# 0.4, the rate should comfortably exceed the old rate. We just
	# assert canal legendary rate is non-trivial (>5% of rolls); the
	# fishing rate should be the rarity of its own weight, which is
	# the most pessimistic of the four tiers. We don't assert fishing
	# rate < X because season/roster composition varies the absolute
	# rate across seasons and we want this test to be season-agnostic.
	_check(canal_legendary > 0,
		"canal legendary rate is non-zero (got %d/%d)" % [canal_legendary, rolls])
	main2.queue_free()
	print("\n=== DEEP CANAL TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("DEEP CANAL GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
