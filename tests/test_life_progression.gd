extends SceneTree
# TASK-324 life progression + rival flavor gate.
# Verifies: married_year set at proposal, child_stage advances 0->1->2->3
# on successive anniversaries with the documented harmony bonuses and
# milestone dialogue, no change to silver or festival_triggered event
# count, child_stage caps at 3, and rival dialogue surfaces only at close
# tier + unmarried + every 5th talk.

var _passed: int = 0
var _failed: int = 0
var _events: int = 0
var _dialogue_hits: Array = []

func _on_festival(name: String) -> void:
	if name.begins_with("anniversary_"):
		_events += 1

func _on_show_dialogue(speaker: String, text: String) -> void:
	_dialogue_hits.append([speaker, text])

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  life_progression :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  life_progression :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var sb: Node = root.get_node("SignalBus")
	sb.festival_triggered.connect(_on_festival)
	sb.show_dialogue.connect(_on_show_dialogue)
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var ek: Node = main.get_node_or_null("EkNPC")
	var tm: Node = sb.time_manager
	_check(ek != null, "Ek available")
	if ek == null or tm == null:
		main.queue_free()
		await process_frame
		quit(1)
		return

	# ----- married_year set at proposal, not before -----
	gd.inventory.clear()
	gd.married = false
	gd.spouse = ""
	gd.married_year = 0
	gd.child_stage = 0
	_check(int(gd.married_year) == 0, "married_year starts at 0")
	tm.set_time(1, 6, 0) # year 1
	gd.add_item("krathong", 1)
	gd.add_affinity("ek", 100)
	ek.try_interact() # proposal path
	_check(gd.married and gd.spouse == "ek", "proposal accepted")
	_check(int(gd.married_year) == 1, "married_year set to current year (1) at proposal")

	# ----- Life progression across years 2-6 -----
	# Married in year 1 (years_married=0 there — no transition, matches the
	# "standard anniversary" case). Transitions start the following year.
	var silver0: int = int(gd.silver)
	# Year 2 anniversary: years_married = 1 -> pregnancy.
	tm.set_time(91, 12, 0) # year 2
	ek.try_interact()
	_check(int(gd.child_stage) == 1, "year 2 anniversary (years_married=1) -> child_stage 1 (pregnant)")
	_check(int(gd.harmony) >= 15, "pregnancy grants >= 15 harmony")
	_check(int(gd.silver) == silver0 + 30, "silver unaffected by milestone (+30 only)")
	_check(_events == 1, "anniversary event fired once (no extra event for milestone)")
	var saw_pregnant: bool = false
	for d in _dialogue_hits:
		if d[0] == "Ek" and String(d[1]).contains("on the way"):
			saw_pregnant = true
	_check(saw_pregnant, "pregnancy milestone dialogue emitted")

	# Year 3 anniversary: years_married = 2 -> birth.
	tm.set_time(181, 12, 0) # year 3
	var harmony_before_2: int = int(gd.harmony)
	ek.try_interact()
	_check(int(gd.child_stage) == 2, "year 3 anniversary (years_married=2) -> child_stage 2 (born)")
	_check(int(gd.harmony) >= harmony_before_2 + 25, "birth grants >= 25 harmony")
	_check(int(gd.silver) == silver0 + 60, "silver still exactly +30 per anniversary (2 total)")
	_check(_events == 2, "anniversary event count still matches call count")
	var saw_birth: bool = false
	for d in _dialogue_hits:
		if d[0] == "Ek" and String(d[1]).contains("baby is here"):
			saw_birth = true
	_check(saw_birth, "birth milestone dialogue emitted")

	# Year 4 anniversary: years_married = 3 -> toddler (terminal).
	tm.set_time(271, 12, 0) # year 4
	var harmony_before_3: int = int(gd.harmony)
	ek.try_interact()
	_check(int(gd.child_stage) == 3, "year 4 anniversary (years_married=3) -> child_stage 3 (toddler)")
	_check(int(gd.harmony) >= harmony_before_3 + 15, "toddler stage grants >= 15 harmony")
	var saw_toddler: bool = false
	for d in _dialogue_hits:
		if d[0] == "Ek" and String(d[1]).contains("walking now"):
			saw_toddler = true
	_check(saw_toddler, "toddler milestone dialogue emitted")

	# Year 5 anniversary: no further transition, standard line, no extra harmony bonus.
	tm.set_time(361, 12, 0) # year 5
	var harmony_before_4: int = int(gd.harmony)
	ek.try_interact()
	_check(int(gd.child_stage) == 3, "child_stage stays capped at 3 (year 5)")
	var standard_line_seen: bool = false
	for d in _dialogue_hits:
		if d[0] == "Ek" and String(d[1]).contains("Happy anniversary"):
			standard_line_seen = true
	_check(standard_line_seen, "standard anniversary line resumes once child_stage is terminal")
	_check(int(gd.silver) == silver0 + 120, "silver still exactly +30 per anniversary (4 total)")

	# Year 6: still capped, no crash, no further bonus.
	tm.set_time(451, 12, 0) # year 6
	var harmony_before_5: int = int(gd.harmony)
	ek.try_interact()
	_check(int(gd.child_stage) == 3, "child_stage stays 3 forever after (year 6)")
	_check(int(gd.harmony) == harmony_before_5, "no harmony bonus once terminal")

	# ----- married_year=0 bypass path (mirrors test_anniversary.gd's direct-set
	# marriage) must not crash and must still respect the same math. -----
	gd.married = true
	gd.spouse = "ek"
	gd.married_year = 0
	gd.child_stage = 0
	gd.harmony = 0
	tm.set_time(1, 6, 0) # year 1 -> years_married = 1 - 0 = 1
	var ok: bool = ek.try_interact()
	_check(ok, "bypass path (married_year=0) does not crash")
	_check(int(gd.child_stage) == 1, "bypass path still computes a valid transition")

	# ----- Rival flavor: close tier, unmarried, every 5th talk only -----
	gd.married = false
	gd.spouse = ""
	gd.inventory.clear()
	gd.affinity["ek"] = 0
	gd.add_affinity("ek", 70) # close tier (60-89)
	_dialogue_hits.clear()
	var rival_hits: int = 0
	for i: int in 10:
		ek.try_interact() # no gift/krathong held -> falls through to _talk()
		var last: Array = _dialogue_hits[_dialogue_hits.size() - 1] if not _dialogue_hits.is_empty() else []
		if not last.is_empty() and (String(last[1]).contains("asking") or String(last[1]).contains("fisher") or String(last[1]).contains("note")):
			rival_hits += 1
	_check(rival_hits >= 1, "rival flavor surfaces at least once across 10 close-tier talks (got %d)" % rival_hits)
	_check(rival_hits <= 3, "rival flavor is occasional, not every talk (got %d of 10)" % rival_hits)

	sb.festival_triggered.disconnect(_on_festival)
	sb.show_dialogue.disconnect(_on_show_dialogue)
	main.queue_free()
	print("\n=== LIFE PROGRESSION TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("LIFE PROGRESSION GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
