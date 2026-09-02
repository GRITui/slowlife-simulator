extends SceneTree
# TASK-339 songkran cooking contest scoring gate — extends the TASK-046
# trigger to track cooking recipes during the 12:00-18:00 window (each
# craft_completed contributes its harmony_reward from data/recipes/recipes.json
# to _cook_score), roll a rival score (4-14), and place the player in 1st /
# tie / participation tiers — every tier strictly positive (no-fail-state).
#
# Coverage approach (per spec): the placement helper _placement_for() is
# extracted as a pure function, so the tie tier is tested directly against
# the helper rather than depending on a randi_range rival roll. Win and
# participation tiers are forced by setting _cook_score high or 0 and
# letting the real end-of-window resolution run with a mocked rival — the
# rival roll itself isn't unit-deterministic so we exercise the full path
# only for the two tiers we can guarantee, plus pure helper coverage for tie.
#
# Cross-signal-reuse guard (the specific bug this task must avoid):
# SignalBus.craft_completed is shared with FishingSpot/MiningSpot, so a fish
# or ore item_id must NOT add to _cook_score — tested explicitly.

var _passed: int = 0
var _failed: int = 0
var _hits: int = 0
var _last_dialogue: String = ""

func _on_festival(name: String) -> void:
	if name == "songkran":
		_hits += 1

func _on_dialogue(_speaker: String, text: String) -> void:
	_last_dialogue = text

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  songkran-cook-contest :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  songkran-cook-contest :: %s" % label)

func _initialize() -> void:
	var sb: Node = root.get_node("SignalBus")
	sb.festival_triggered.connect(_on_festival)
	sb.show_dialogue.connect(_on_dialogue)
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var trig: Node = main.get_node_or_null("SongkranTrigger")
	_check(trig != null, "SongkranTrigger instanced under Main")
	if trig == null:
		await process_frame
		quit(1)
		return
	# Recipe data must be loaded from disk during _ready.
	_check(trig._recipe_harmony.size() > 0, "recipe_harmony loaded from data/recipes/recipes.json")
	_check(trig._recipe_harmony.has("nam_prik") and int(trig._recipe_harmony["nam_prik"]) == 9,
		"nam_prik harmony_reward = 9 (sanity-check against recipes.json)")
	_check(trig._recipe_harmony.has("thai_basil_stirfry") and int(trig._recipe_harmony["thai_basil_stirfry"]) == 5,
		"thai_basil_stirfry harmony_reward = 5 (sanity-check against recipes.json)")
	var tm: Node = sb.time_manager

	# --- Pure placement helper (covers tie tier deterministically) ---
	_check(trig._placement_for(7, 5) == "first", "helper first when player > rival")
	_check(trig._placement_for(5, 5) == "tie", "helper tie when player == rival")
	_check(trig._placement_for(3, 5) == "participation", "helper participation when player < rival")
	_check(trig._placement_for(0, 5) == "participation", "helper participation when player cooked nothing (score 0)")

	# --- Window opens on hot-season day 3, 12:00-18:00 ---
	var hits_before: int = _hits
	tm.set_season("hot")
	tm.set_time(3, 11, 0)
	_check(_hits == hits_before, "before 12:00 does not trigger festival")
	_check(not trig._cook_active, "before 12:00 does not start scoring state")
	_check(trig._cook_score == 0, "before 12:00 leaves _cook_score at 0")
	# Advance to 12:00 → festival fires, window opens.
	tm.set_time(3, 12, 0)
	_check(_hits == hits_before + 1, "12:00 triggers festival once")
	_check(trig._cook_active, "window start sets _cook_active = true")
	_check(trig._cook_score == 0, "window start resets _cook_score to 0")

	# --- 2 real recipes during the window → sum their harmony_reward ---
	# nam_prik = 9, thai_basil_stirfry = 5 → 9 + 5 = 14
	trig._on_craft_completed("nam_prik", 1)
	trig._on_craft_completed("thai_basil_stirfry", 1)
	_check(trig._cook_score == 14, "two recipe crafts (nam_prik + thai_basil_stirfry) sum to 14")
	# Quantity multiplier: 3 of the same recipe → 3 × harmony_reward.
	trig._cook_score = 0
	trig._on_craft_completed("nam_prik", 3)
	_check(trig._cook_score == 27, "craft with qty=3 multiplies harmony_reward (9 * 3 = 27)")

	# --- Cross-signal-reuse guard: FISH and ORE item_ids must NOT score ---
	trig._cook_score = 0
	trig._on_craft_completed("pla_nin_big", 1)
	_check(trig._cook_score == 0, "fish item_id (pla_nin_big) does NOT add to cook score")
	trig._on_craft_completed("copper_ore", 1)
	_check(trig._cook_score == 0, "ore item_id (copper_ore) does NOT add to cook score")
	# And a recipe id that doesn't exist (typo / not in recipes.json) must also not score.
	trig._on_craft_completed("nam_prk_typo", 1)
	_check(trig._cook_score == 0, "unknown item_id does NOT add to cook score")

	# --- Craft while inactive does NOT score ---
	var score_before: int = trig._cook_score
	trig._cook_active = false
	trig._on_craft_completed("nam_prik", 1)
	_check(trig._cook_score == score_before, "craft while inactive does not add to score")
	# Re-establish active + high score for window-close 1st-place test.
	trig._cook_active = true
	trig._cook_score = 99

	# --- Window close: forced 1st place ---
	# Force score >> any randi_range(4, 14) roll so player wins.
	var silver_before: int = gd.silver
	var harmony_before: int = gd.harmony
	tm.set_time(3, 18, 0)
	_check(not trig._cook_active, "window close sets _cook_active = false")
	_check(gd.silver - silver_before >= 1, "1st place grants silver > 0")
	_check(gd.harmony - harmony_before >= 1, "1st place grants harmony > 0")
	_check(_last_dialogue.contains("First place"), "1st place dialogue mentions First place")
	# Window close resolves exactly once — next minute at 18:30 must not re-pay.
	var silver_after_first: int = gd.silver
	var harmony_after_first: int = gd.harmony
	tm.set_time(3, 18, 30)
	_check(gd.silver == silver_after_first, "no double payout on later ticks at same hour")
	_check(gd.harmony == harmony_after_first, "no double payout (harmony) on later ticks")

	# --- Fresh window for participation tier ---
	# Advance year so the dedupe key resets.
	trig._triggered_keys.clear()
	tm.set_time(3, 12, 0)
	_check(trig._cook_active, "new window opens (_cook_active)")
	_check(trig._cook_score == 0, "new window resets _cook_score to 0")
	trig._cook_score = 0 # player cooks nothing — guaranteed participation.
	silver_before = gd.silver
	harmony_before = gd.harmony
	tm.set_time(3, 18, 0)
	_check(not trig._cook_active, "participation window close clears _cook_active")
	_check(gd.silver - silver_before >= 1, "participation grants silver > 0 (no-fail)")
	_check(gd.harmony - harmony_before >= 1, "participation grants harmony > 0 (no-fail)")
	_check(_last_dialogue.contains("Participation"), "participation dialogue uses warm label")

	sb.festival_triggered.disconnect(_on_festival)
	sb.show_dialogue.disconnect(_on_dialogue)
	main.queue_free()
	print("\n=== SONGKRAN-COOK-CONTEST TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("SONGKRAN-COOK-CONTEST GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
