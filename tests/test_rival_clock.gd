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
	_check(clock.PAIRS.is_empty(), "PAIRS is empty in this task (content added in TASK-342)")

	var pair: Dictionary = {"rival_id": "test_rival", "rival_name": "Test Rival", "candidate_name": "Test Candidate"}

	# --- haven't met yet: no-op regardless of day ---
	gd.npc_first_met_day.erase("test_candidate")
	gd.lost_to_rival.erase("test_candidate")
	gd.rival_warning_shown.erase("test_candidate")
	gd.affinity.erase("test_candidate")
	clock.call("_check_candidate", "test_candidate", 100, pair)
	_check(not gd.lost_to_rival.get("test_candidate", false), "hasn't met yet: no loss")
	_check(int(gd.rival_warning_shown.get("test_candidate", 0)) == 0, "hasn't met yet: no warning")

	# --- met on day 1. Simulate one check per day, matching how the real
	# _on_minute_ticked driver calls this exactly once per calendar day as
	# the game clock advances linearly (the loop only advances one warning
	# tier per call by design, so skipping days in a test would jump past
	# intermediate tiers — this mirrors real continuous play instead). ---
	gd.npc_first_met_day["test_candidate"] = 1
	for day: int in range(2, 24): # through day 23: elapsed 22, frac 0.244 (just under 25%)
		clock.call("_check_candidate", "test_candidate", day, pair)
	_check(int(gd.rival_warning_shown.get("test_candidate", 0)) == 0, "24%% elapsed: no warning yet")
	clock.call("_check_candidate", "test_candidate", 24, pair) # elapsed 23, frac 0.256
	_check(int(gd.rival_warning_shown.get("test_candidate", 0)) == 1, "25%%+ elapsed sets warning tier 1")

	for day: int in range(25, 46):
		clock.call("_check_candidate", "test_candidate", day, pair)
	_check(int(gd.rival_warning_shown.get("test_candidate", 0)) == 1, "49%% elapsed: still tier 1")
	clock.call("_check_candidate", "test_candidate", 46, pair) # elapsed 45, frac 0.5
	_check(int(gd.rival_warning_shown.get("test_candidate", 0)) == 2, "50%%+ elapsed sets warning tier 2")

	for day: int in range(47, 68):
		clock.call("_check_candidate", "test_candidate", day, pair)
	_check(int(gd.rival_warning_shown.get("test_candidate", 0)) == 2, "74%% elapsed does not advance to tier 3 yet")
	clock.call("_check_candidate", "test_candidate", 69, pair) # elapsed 68, frac 0.756
	_check(int(gd.rival_warning_shown.get("test_candidate", 0)) == 3, "75%%+ elapsed sets warning tier 3")

	for day: int in range(70, 91):
		clock.call("_check_candidate", "test_candidate", day, pair)
	# --- day 91 (elapsed 90, >= WINDOW_DAYS): still below affinity 25 -> loss resolves ---
	_check(int(gd.get_affinity("test_candidate")) < 25, "affinity still below 25 at the deadline (test setup)")
	clock.call("_check_candidate", "test_candidate", 91, pair)
	_check(bool(gd.lost_to_rival.get("test_candidate", false)), "90+ days elapsed, affinity < 25 -> lost_to_rival")
	_check(_last_dialogue.contains("Test Candidate") and _last_dialogue.contains("Test Rival"),
		"loss dialogue names both candidate and rival")

	# --- once lost, repeated checks are no-ops (idempotent) ---
	_last_dialogue = ""
	clock.call("_check_candidate", "test_candidate", 200, pair)
	_check(_last_dialogue == "", "no repeat loss dialogue on later ticks")

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
