extends SceneTree
# TASK-340 rival win/loss clock gate — pure mechanism test (RivalClock.PAIRS
# is empty in this task; sprints 2/3 wire real candidates). _check_candidate/
# _resolve_loss take the pair as an explicit parameter so this can be
# exercised end-to-end without needing PAIRS itself populated.

var _passed: int = 0
var _failed: int = 0
var _last_dialogue: String = ""

func _on_dialogue(_speaker: String, text: String) -> void:
	_last_dialogue = text

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  rival-clock :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  rival-clock :: %s" % label)

func _initialize() -> void:
	var sb: Node = root.get_node("SignalBus")
	var gd: Node = root.get_node("GameData")
	sb.show_dialogue.connect(_on_dialogue)
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var clock: Node = main.get_node_or_null("RivalClock")
	_check(clock != null, "RivalClock instanced under Main")
	if clock == null:
		await process_frame
		quit(1)
		return
	_check(clock.PAIRS.size() == 6, "PAIRS has all 6 real pairings (populated by TASK-342)")

	var pair: Dictionary = {"rival_id": "test_rival", "rival_name": "Test Rival", "candidate_name": "Test Candidate"}

	# --- haven't met yet: no-op regardless of day ---
	gd.npc_first_met_day.erase("test_candidate")
	gd.lost_to_rival.erase("test_candidate")
	gd.rival_warning_shown.erase("test_candidate")
	gd.affinity.erase("test_candidate")
	clock.call("_check_candidate", "test_candidate", 100, pair)
	_check(not gd.lost_to_rival.get("test_candidate", false), "hasn't met yet: no loss")
	_check(int(gd.rival_warning_shown.get("test_candidate", 0)) == 0, "hasn't met yet: no warning")

	# --- TASK-347: progress is tracked as an explicit float (rival_progress),
	# not recomputed from day-elapsed, so boundary checks set it directly
	# rather than simulating one _check_candidate call per calendar day (a
	# call-count-based simulation would drift from the day-elapsed math the
	# old test relied on, since _check_candidate now advances progress once
	# per CALL, not once per elapsed day). ---
	gd.npc_first_met_day["test_candidate"] = 1
	gd.rival_progress["test_candidate"] = 24.0 # just under the 25% warning threshold
	clock.call("_check_candidate", "test_candidate", 24, pair) # +1.111 -> 25.11%
	_check(int(gd.rival_warning_shown.get("test_candidate", 0)) == 1, "25%%+ progress sets warning tier 1")

	gd.rival_progress["test_candidate"] = 49.0
	clock.call("_check_candidate", "test_candidate", 46, pair) # +1.111 -> 50.11%
	_check(int(gd.rival_warning_shown.get("test_candidate", 0)) == 2, "50%%+ progress sets warning tier 2")

	gd.rival_progress["test_candidate"] = 74.0
	clock.call("_check_candidate", "test_candidate", 69, pair) # +1.111 -> 75.11%
	_check(int(gd.rival_warning_shown.get("test_candidate", 0)) == 3, "75%%+ progress sets warning tier 3")

	# --- progress reaching 100 resolves a loss ---
	_check(int(gd.get_affinity("test_candidate")) < 25, "affinity still below 25 at the deadline (test setup)")
	gd.rival_progress["test_candidate"] = 99.0
	clock.call("_check_candidate", "test_candidate", 91, pair) # +1.111 -> clamped to 100
	_check(bool(gd.lost_to_rival.get("test_candidate", false)), "progress reaching 100, affinity < 25 -> lost_to_rival")
	_check(is_equal_approx(float(gd.rival_progress.get("test_candidate", 0.0)), 100.0),
		"rival_progress clamps at 100, doesn't overshoot")
	_check(_last_dialogue.contains("Test Candidate") and _last_dialogue.contains("Test Rival"),
		"loss dialogue names both candidate and rival")

	# --- once lost, repeated checks are no-ops (idempotent) ---
	_last_dialogue = ""
	clock.call("_check_candidate", "test_candidate", 200, pair)
	_check(_last_dialogue == "", "no repeat loss dialogue on later ticks")

	# --- default pacing (nothing nudging it) still reaches 100 within
	# WINDOW_DAYS ticks, matching the original day-elapsed behavior. One
	# tick of slack allows for float-accumulation rounding across 90 adds
	# of a repeating decimal (100.0/90.0) without making this test brittle. ---
	gd.npc_first_met_day["paced_candidate"] = 1
	gd.rival_progress.erase("paced_candidate")
	gd.affinity["paced_candidate"] = 0
	for day: int in range(2, 3 + clock.WINDOW_DAYS):
		clock.call("_check_candidate", "paced_candidate", day, pair)
	_check(bool(gd.lost_to_rival.get("paced_candidate", false)),
		"default pacing (no nudges) still reaches loss within WINDOW_DAYS ticks")

	# --- nudge_progress() ---
	gd.npc_first_met_day["nudge_candidate"] = 1
	gd.rival_progress["nudge_candidate"] = 50.0
	gd.lost_to_rival.erase("nudge_candidate")
	gd.married = false
	clock.call("nudge_progress", "nudge_candidate", -5.0)
	_check(is_equal_approx(float(gd.rival_progress.get("nudge_candidate", 0.0)), 45.0),
		"nudge_progress(-5.0) subtracts from current progress")
	clock.call("nudge_progress", "nudge_candidate", 200.0)
	_check(is_equal_approx(float(gd.rival_progress.get("nudge_candidate", 0.0)), 100.0),
		"nudge_progress clamps to 100 on overshoot")
	clock.call("nudge_progress", "nudge_candidate", -500.0)
	_check(is_equal_approx(float(gd.rival_progress.get("nudge_candidate", 0.0)), 0.0),
		"nudge_progress clamps to 0 on undershoot")
	# no-op: candidate hasn't been met yet
	gd.rival_progress.erase("unmet_candidate")
	clock.call("nudge_progress", "unmet_candidate", 50.0)
	_check(not gd.rival_progress.has("unmet_candidate"), "nudge_progress no-ops on an unmet candidate")
	# no-op: candidate already lost
	gd.npc_first_met_day["lost_nudge_candidate"] = 1
	gd.rival_progress["lost_nudge_candidate"] = 50.0
	gd.lost_to_rival["lost_nudge_candidate"] = true
	clock.call("nudge_progress", "lost_nudge_candidate", -50.0)
	_check(is_equal_approx(float(gd.rival_progress.get("lost_nudge_candidate", 0.0)), 50.0),
		"nudge_progress no-ops on an already-lost candidate")

	# --- a nudge meaningfully delays the next warning tier / eventual loss,
	# proving the "slightly" framing isn't a token gesture. Tiers 1/2 have
	# already fired (shown=2); without a nudge the next tick would cross the
	# 75% tier-3 threshold — with a -10 nudge it doesn't. ---
	gd.npc_first_met_day["delayed_candidate"] = 1
	gd.rival_progress["delayed_candidate"] = 74.0
	gd.lost_to_rival.erase("delayed_candidate")
	gd.rival_warning_shown["delayed_candidate"] = 2
	gd.affinity["delayed_candidate"] = 0
	clock.call("nudge_progress", "delayed_candidate", -10.0) # 74 -> 64
	clock.call("_check_candidate", "delayed_candidate", 69, pair) # +1.111 -> 65.11%, below tier-3's 75%
	_check(int(gd.rival_warning_shown.get("delayed_candidate", 0)) == 2,
		"a -10 nudge keeps progress under the tier-3 threshold that a call without it would have crossed")
	# Prove the counterfactual: the SAME sequence without the nudge does cross it.
	gd.rival_progress["unnudged_candidate"] = 74.0
	gd.npc_first_met_day["unnudged_candidate"] = 1
	gd.rival_warning_shown["unnudged_candidate"] = 2
	gd.affinity["unnudged_candidate"] = 0
	clock.call("_check_candidate", "unnudged_candidate", 69, pair) # +1.111 -> 75.11%, crosses tier-3
	_check(int(gd.rival_warning_shown.get("unnudged_candidate", 0)) == 3,
		"without the nudge, the same starting progress does cross tier 3 at this tick")

	# --- a DIFFERENT candidate, actively courted, is never at risk ---
	gd.npc_first_met_day["safe_candidate"] = 1
	gd.affinity["safe_candidate"] = 60
	clock.call("_check_candidate", "safe_candidate", 200, pair)
	_check(not gd.lost_to_rival.get("safe_candidate", false), "actively-courted candidate is never lost")

	# --- reaching affinity >= 25 before the deadline clears the clock forever ---
	gd.npc_first_met_day["cleared_candidate"] = 1
	gd.affinity["cleared_candidate"] = 30
	clock.call("_check_candidate", "cleared_candidate", 500, pair) # well past 90 days
	_check(not gd.lost_to_rival.get("cleared_candidate", false),
		"affinity >= 25 before deadline permanently clears the clock, even long after day 90")

	# --- already married: never at risk regardless of affinity/day ---
	gd.married = true
	gd.spouse = "married_candidate"
	gd.npc_first_met_day["married_candidate"] = 1
	gd.affinity.erase("married_candidate")
	clock.call("_check_candidate", "married_candidate", 500, pair)
	_check(not gd.lost_to_rival.get("married_candidate", false), "married spouse is never lost regardless of affinity")

	main.queue_free()
	print("\n=== RIVAL-CLOCK TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("RIVAL-CLOCK GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
