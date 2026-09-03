extends SceneTree
# TASK-336 fishing competition scoring gate — extends the TASK-319 trigger to
# track fish catches during the 10:00-16:00 window (1 small / 2 mid / 3 big
# points), roll a rival score (2-8), and place the player in 1st / tie /
# participation tiers — every tier strictly positive (no-fail-state).
#
# Coverage approach (per spec): the placement helper _placement_for() is
# extracted as a pure function, so the tie tier is tested directly against
# the helper rather than depending on a randi_range rival roll. Win and
# participation tiers are forced by setting _player_score high or 0 and
# letting the real end-of-window resolution run with a mocked rival — the
# rival roll itself isn't unit-deterministic so we exercise the full path
# only for the two tiers we can guarantee, plus pure helper coverage for tie.

var _passed: int = 0
var _failed: int = 0
var _hits: int = 0
var _last_dialogue: String = ""

func _on_festival(name: String) -> void:
	if name == "fishing_competition":
		_hits += 1

func _on_dialogue(_speaker: String, text: String) -> void:
	_last_dialogue = text

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  fishing-comp-score :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  fishing-comp-score :: %s" % label)

func _initialize() -> void:
	var sb: Node = root.get_node("SignalBus")
	sb.festival_triggered.connect(_on_festival)
	sb.show_dialogue.connect(_on_dialogue)
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var comp: Node = main.get_node_or_null("FishingCompetitionTrigger")
	_check(comp != null, "FishingCompetitionTrigger instanced under World")
	if comp == null:
		await process_frame
		quit(1)
		return
	var tm: Node = sb.time_manager
	# --- Pure placement helper (covers tie tier deterministically) ---
	_check(comp._placement_for(7, 5) == "first", "helper first when player > rival")
	_check(comp._placement_for(5, 5) == "tie", "helper tie when player == rival")
	_check(comp._placement_for(3, 5) == "participation", "helper participation when player < rival")
	_check(comp._placement_for(0, 5) == "participation", "helper participation when player never caught (score 0)")

	# --- Skill gate unchanged: skill 1 still blocks, no scoring state starts ---
	var hits_before: int = _hits
	gd.fishing_skill = 1
	tm.set_season("hot")
	tm.set_time(15, 12, 0)
	_check(_hits == hits_before, "skill < 2 does not trigger festival")
	_check(not comp._competition_active, "skill < 2 does not start scoring state")
	_check(comp._player_score == 0, "skill < 2 leaves player_score at 0")
	gd.fishing_skill = 2
	# Advance an hour so the trigger re-fires (skill gate now passes).
	tm.set_time(15, 13, 0)
	_check(_hits == hits_before + 1, "skill >= 2 triggers festival once")
	_check(comp._competition_active, "window start sets _competition_active = true")
	_check(comp._player_score == 0, "window start resets _player_score to 0")

	# --- 3 catches during the window → score 6 (3 + 2 + 1) ---
	comp._on_craft_completed("pla_nin_big", 1)
	comp._on_craft_completed("pla_nin_mid", 1)
	comp._on_craft_completed("pla_nin_small", 1)
	_check(comp._player_score == 6, "three catches (big+mid+small) sum to 6 points")

	# --- Catch outside window does NOT score ---
	var score_before: int = comp._player_score
	comp._competition_active = false
	comp._on_craft_completed("pla_nin_big", 1)
	_check(comp._player_score == score_before, "catch while inactive does not add to score")
	# Non-fish craft_completed does NOT score even while active.
	comp._competition_active = true
	comp._player_score = 0
	comp._on_craft_completed("rice_grain", 1)
	_check(comp._player_score == 0, "non-fish craft_completed does not score")
	# Re-establish active + low score for window-close test.
	comp._player_score = 4

	# --- Window close: forced 1st place ---
	# Force score >> any randi_range(2, 8) roll so player wins.
	comp._player_score = 99
	var silver_before: int = gd.silver
	var harmony_before: int = gd.harmony
	# TASK-347: a "first" placement nudges Fah's own rival clock back.
	gd.npc_first_met_day["fah"] = 1
	gd.rival_progress["fah"] = 50.0
	gd.lost_to_rival.erase("fah")
	gd.married = false
	tm.set_time(15, 16, 0)
	_check(is_equal_approx(float(gd.rival_progress.get("fah", 0.0)), 45.0),
		"first place nudges fah's rival_progress back by 5.0")
	_check(not comp._competition_active, "window close sets _competition_active = false")
	_check(gd.silver - silver_before >= 1, "1st place grants silver > 0")
	_check(gd.harmony - harmony_before >= 1, "1st place grants harmony > 0")
	_check(_last_dialogue.contains("First place"), "1st place dialogue mentions First place")
	# Window close resolves exactly once — next minute at 16:01 must not re-pay.
	var silver_after_first: int = gd.silver
	var harmony_after_first: int = gd.harmony
	tm.set_time(15, 16, 30)
	_check(gd.silver == silver_after_first, "no double payout on later ticks at same hour")
	_check(gd.harmony == harmony_after_first, "no double payout (harmony) on later ticks")

	# --- Fresh window for participation tier ---
	# Advance year so the dedupe key resets.
	comp._triggered_keys.clear()
	gd.fishing_skill = 2
	tm.set_time(15, 11, 0)
	_check(comp._competition_active, "new window opens (_competition_active)")
	_check(comp._player_score == 0, "new window resets _player_score to 0")
	comp._player_score = 0 # player catches nothing — guaranteed participation.
	silver_before = gd.silver
	harmony_before = gd.harmony
	# TASK-347: a "participation" placement nudges Fah's rival clock forward.
	gd.rival_progress["fah"] = 50.0
	tm.set_time(15, 16, 0)
	_check(is_equal_approx(float(gd.rival_progress.get("fah", 0.0)), 55.0),
		"participation nudges fah's rival_progress forward by 5.0")
	_check(not comp._competition_active, "participation window close clears _competition_active")
	_check(gd.silver - silver_before >= 1, "participation grants silver > 0 (no-fail)")
	_check(gd.harmony - harmony_before >= 1, "participation grants harmony > 0 (no-fail)")
	_check(_last_dialogue.contains("Participation"), "participation dialogue uses warm label")

	sb.festival_triggered.disconnect(_on_festival)
	sb.show_dialogue.disconnect(_on_dialogue)
	main.queue_free()
	print("\n=== FISHING-COMP-SCORING TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("FISHING-COMP-SCORING GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)