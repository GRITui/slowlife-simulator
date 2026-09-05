extends SceneTree
# TASK-342 rival NPC gate — 6 rival NPCs instanced, scripted, gift->friendship
# flow, confession dilemma (one-time +25 silver / +15 harmony at level 6+),
# krathong concede path (matchmaker_<rival_id> milestone, lost_to_rival set),
# continue-rivalry path unaffected, and a RivalClock end-to-end regression
# with PAIRS now populated.
#
# Mirrors tests/test_rival_clock.gd's shape (a single SceneTree + ad-hoc
# `_check` + state-clear between phases) so the test is independent of the
# existing test_rival_clock.gd — that one tests the clock mechanism against
# a temporary pair (PAIRS was empty when it was written); this one exercises
# the populated PAIRS end-to-end.

var _passed: int = 0
var _failed: int = 0
var _last_speaker: String = ""
var _last_line: String = ""

func _on_dialogue(speaker: String, line: String) -> void:
	_last_speaker = speaker
	_last_line = line

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  rival-npcs :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  rival-npcs :: %s" % label)

func _initialize() -> void:
	var sb: Node = root.get_node("SignalBus")
	var gd: Node = root.get_node("GameData")
	sb.show_dialogue.connect(_on_dialogue)
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	# --- All 6 instanced, correct npc_id / candidate_id / display_name ---
	var rivals: Array = [
		{"name": "YaiNPC", "id": "yai", "candidate_id": "ek", "display": "Yai"},
		{"name": "OhmNPC", "id": "ohm", "candidate_id": "fah", "display": "Ohm"},
		{"name": "RungNPC", "id": "rung", "candidate_id": "ploy", "display": "Rung"},
		{"name": "NoteNPC", "id": "note", "candidate_id": "chang", "display": "Note"},
		{"name": "FonNPC", "id": "fon", "candidate_id": "klong", "display": "Fon"},
		{"name": "BoonNPC", "id": "boon", "candidate_id": "yaa", "display": "Boon"},
	]
	for r: Dictionary in rivals:
		var node_name: String = r["name"]
		var node: Node = main.get_node_or_null(node_name)
		_check(node != null, "%s instanced under World" % node_name)
		if node == null:
			continue
		_check(node.is_in_group("villager_npc"), "%s tagged villager_npc" % node_name)
		_check(node.is_in_group("rival_npc"), "%s tagged rival_npc" % node_name)
		_check(node.has_method("try_interact"), "%s has RivalNPC script attached" % node_name)
		_check(String(node.npc_id) == String(r["id"]), "%s npc_id = '%s'" % [node_name, r["id"]])
		_check(String(node.candidate_id) == String(r["candidate_id"]), "%s candidate_id = '%s'" % [node_name, r["candidate_id"]])
		_check(String(node.display_name) == String(r["display"]), "%s display_name = '%s'" % [node_name, r["display"]])

	# --- RivalClock PAIRS is populated end-to-end (regression on TASK-340) ---
	var clock: Node = main.get_node_or_null("RivalClock")
	_check(clock != null, "RivalClock instanced under World")
	if clock != null:
		_check(clock.PAIRS.size() == 6, "PAIRS has 6 entries (was empty pre-TASK-342)")
		_check(clock.PAIRS.has("ek") and String(clock.PAIRS["ek"]["rival_id"]) == "yai",
			"PAIRS.ek -> yai")
		_check(clock.PAIRS.has("fah") and String(clock.PAIRS["fah"]["rival_id"]) == "ohm",
			"PAIRS.fah -> ohm")
		_check(clock.PAIRS.has("ploy") and String(clock.PAIRS["ploy"]["rival_id"]) == "rung",
			"PAIRS.ploy -> rung")
		_check(clock.PAIRS.has("chang") and String(clock.PAIRS["chang"]["rival_id"]) == "note",
			"PAIRS.chang -> note")
		_check(clock.PAIRS.has("klong") and String(clock.PAIRS["klong"]["rival_id"]) == "fon",
			"PAIRS.klong -> fon")
		_check(clock.PAIRS.has("yaa") and String(clock.PAIRS["yaa"]["rival_id"]) == "boon",
			"PAIRS.yaa -> boon")

	# --- Tier-0 talk() reveals the competing interest (TASK-345 fix baked in) ---
	# DialogueDB.get_rival_line() at tier=0 with has_won=false returns a
	# pool where every entry names the candidate in the first 12 chars of
	# the line (e.g. "Mali's been talking about..." / "You're the one...").
	# We assert that the candidate's capitalized display name appears ANY-
	# WHERE in the line, which is the contract the spec's Tests section
	# calls out ("a simple .contains() check against the candidate's
	# display name is enough").
	var db: GDScript = load("res://scripts/narrative/DialogueDB.gd")
	for r: Dictionary in rivals:
		var node: Node = main.get_node_or_null(r["name"])
		if node == null:
			continue
		# Ensure clean state for each rival's tier-0 talk assertion.
		gd.rival_warning_shown[r["candidate_id"]] = 0
		gd.lost_to_rival.erase(r["candidate_id"])
		_last_speaker = ""
		_last_line = ""
		node.talk()
		# TASK-383 gender/name rewrite: candidate display names (Mali/Kwan/
		# Rin/etc.) no longer match String(candidate_id).capitalize() --
		# that mechanical derivation broke when Ek/Chang/Klong were renamed
		# to feminine names not derivable from their (unchanged) lowercase
		# npc_id. Read the real configured name from RivalClock.PAIRS
		# instead of assuming id-capitalization ever equals display name.
		var expected_name: String = String(clock.PAIRS[r["candidate_id"]]["candidate_name"]) if clock != null else String(r["candidate_id"]).capitalize()
		_check(_last_speaker == String(r["display"]),
			"%s tier-0 talk() emits display_name speaker" % r["name"])
		_check(_last_line.contains(expected_name),
			"%s tier-0 line contains candidate display name '%s' (TASK-345 fix)" % [r["name"], expected_name])

	# --- Gift-giving raises rival_friendship (mirrors test_gift_prefs.gd shape) ---
	# Use Rung (loved item mango_sticky_rice) as the probe — both loved AND
	# liked items on every rival's GIFT_PREFERENCES are in FOOD_ITEMS, so
	# any held food auto-picker lands on one of them and grants +20 (loved)
	# or +10 (liked). Just verify non-zero delta and the right-side read.
	for r: Dictionary in rivals:
		var node: Node = main.get_node_or_null(r["name"])
		if node == null:
			continue
		gd.rival_friendship.erase(r["id"])
		gd.inventory.clear()
		gd.add_item("rice_grain", 1) # generic fallback — guaranteed in FOOD_ITEMS
		var before: int = int(gd.rival_friendship.get(r["id"], 0))
		node.try_interact()
		var after: int = int(gd.rival_friendship.get(r["id"], 0))
		_check(after > before, "%s gift try_interact raises rival_friendship (%d -> %d)" % [r["name"], before, after])
		_check(int(gd.inventory.get("rice_grain", 0)) == 0, "%s gift item consumed from inventory" % r["name"])

	# --- Confession fires exactly once at level 6+, grants +25 silver /
	# +15 harmony exactly once (repeat gifts after don't re-trigger or
	# re-grant). Drive Ohm (loved lotus_soup) directly to friendship 60
	# so level_for() returns 6 on the very next gift. ---
	var ohm: Node = main.get_node_or_null("OhmNPC")
	if ohm != null:
		gd.rival_confessed.erase("ohm")
		gd.rival_friendship["ohm"] = 60 # level_for(60) == 6
		gd.inventory.clear()
		var silver_before: int = gd.silver
		var harmony_before: int = gd.harmony
		gd.add_item("rice_grain", 2)
		ohm.try_interact() # first gift -> confession fires, +25 silver +15 harmony
		_check(bool(gd.rival_confessed.get("ohm", false)),
			"Ohm confession fires at rival_friendship level 6+")
		_check(gd.silver == silver_before + 25,
			"Ohm confession grants +25 silver exactly once (was %d, now %d)" % [silver_before, gd.silver])
		_check(gd.harmony == harmony_before + 15,
			"Ohm confession grants +15 harmony exactly once (was %d, now %d)" % [harmony_before, gd.harmony])
		# Repeat gifts after confession don't re-trigger or re-grant.
		var silver2: int = gd.silver
		var harmony2: int = gd.harmony
		gd.add_item("rice_grain", 1)
		ohm.try_interact()
		_check(gd.silver == silver2,
			"Ohm repeat gift after confession does NOT re-grant silver")
		_check(gd.harmony == harmony2,
			"Ohm repeat gift after confession does NOT re-grant harmony")
		_check(bool(gd.rival_confessed.get("ohm", false)),
			"Ohm rival_confessed stays true (no toggle back)")

	# --- Concede path: after confession, giving a krathong sets
	# lost_to_rival[candidate_id] = true, grants matchmaker_<rival_id>
	# milestone, and a second krathong attempt is a no-op. ---
	if ohm != null:
		gd.rival_confessed["ohm"] = true
		gd.lost_to_rival.erase("fah")
		gd.add_item("krathong", 2)
		var silver3: int = gd.silver
		var harmony3: int = gd.harmony
		ohm.try_interact() # concede: consumes krathong, sets lost_to_rival, grants milestone
		_check(bool(gd.lost_to_rival.get("fah", false)),
			"Ohm krathong concede sets lost_to_rival[fah] = true")
		_check(bool(gd.milestones_earned.get("matchmaker_ohm", false)),
			"Ohm krathong concede grants matchmaker_ohm milestone")
		_check(gd.harmony == harmony3 + 20,
			"Ohm krathong concede grants +20 harmony via matchmaker milestone")
		_check(gd.has_item("krathong", 1) and int(gd.inventory.get("krathong", 0)) == 1,
			"Ohm krathong concede consumed exactly 1 of 2 krathongs")
		# Second krathong attempt is a no-op.
		var silver4: int = gd.silver
		var harmony4: int = gd.harmony
		var lost_before: bool = bool(gd.lost_to_rival.get("fah", false))
		ohm.try_interact()
		_check(int(gd.inventory.get("krathong", 0)) == 1,
			"Ohm second krathong concede attempt is a no-op (krathong untouched)")
		_check(gd.silver == silver4, "Ohm no-op concede doesn't grant silver")
		_check(gd.harmony == harmony4, "Ohm no-op concede doesn't grant harmony")
		_check(bool(gd.lost_to_rival.get("fah", false)) == lost_before,
			"Ohm no-op concede leaves lost_to_rival unchanged")

	# --- Continue-rivalry path: after confession, normal courting (gifts/
	# talk on the ROMANCE candidate, not the rival) is completely unaffected.
	# Use Boon<->Yaa as the probe: Boon is confessed, then verify gifting
	# Yaa (the romance candidate) still grants +20 affinity exactly as it
	# did pre-TASK-342. ---
	var boon: Node = main.get_node_or_null("BoonNPC")
	var yaa: Node = main.get_node_or_null("YaaNPC")
	if boon != null and yaa != null:
		gd.rival_confessed["boon"] = true
		gd.lost_to_rival.erase("yaa")
		gd.married = false
		gd.spouse = ""
		gd.affinity.erase("yaa")
		# Snapshot Boon's rival_friendship before the Yaa gift to prove the
		# rival-side flow is independent of the candidate-side flow (the prior
		# gift loop may have bumped rival_friendship[boon] above 0; that's
		# fine — what we care about is that the Yaa gift doesn't move it).
		var boon_before: int = int(gd.rival_friendship.get("boon", 0))
		gd.inventory.clear()
		gd.add_item("thai_basil", 1) # Yaa's loved item
		yaa.try_interact()
		_check(int(gd.affinity.get("yaa", 0)) == 20,
			"Yaa still grants +20 from loved gift even when Boon has confessed (continue-rivalry path unaffected)")
		_check(int(gd.rival_friendship.get("boon", 0)) == boon_before,
			"Boon's rival_friendship NOT touched by Yaa gift (rival and candidate flows are independent)")

	# --- End-to-end regression on RivalClock 90-day neglect-loss: run the
	# existing flow with PAIRS now populated — it must still work end-to-end.
	# Uses a temporary pair (NOT in PAIRS, doesn't touch any real rival) so
	# this test doesn't interfere with the rival-confession phase above. ---
	if clock != null:
		var temp_pair: Dictionary = {"rival_id": "reg_rival", "rival_name": "Reg Rival", "candidate_name": "Reg Candidate"}
		gd.npc_first_met_day["reg_candidate"] = 1
		gd.rival_progress.erase("reg_candidate")
		gd.lost_to_rival.erase("reg_candidate")
		gd.affinity["reg_candidate"] = 0
		for day: int in range(2, 3 + clock.WINDOW_DAYS):
			clock.call("_check_candidate", "reg_candidate", day, temp_pair)
		_check(bool(gd.lost_to_rival.get("reg_candidate", false)),
			"RivalClock 90-day neglect-loss still works with PAIRS populated (regression)")

	main.queue_free()
	print("\n=== RIVAL-NPC TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("RIVAL-NPC GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)