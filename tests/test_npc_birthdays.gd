extends SceneTree
# TASK-388 gate — NPC birthdays + birthday-gift affinity bonus for the 6
# romance candidates.
#
# Standalone --script invocation (wired into scripts/ci/run_gate.sh):
#   godot --headless --path . --script res://tests/test_npc_birthdays.gd
#
# Capture convention mirrors tests/test_family_gift_hints.gd: the handler
# stores [speaker, text] pairs and every check filters to the specific
# NPC's own display_name, so unrelated ambient dialogue from other
# systems in the real World.tscn can never corrupt an assertion (that
# exact `captured.size() == 1` flake was already hit and fixed once —
# do not reintroduce a raw size assertion here).

var _passed: int = 0
var _failed: int = 0
var _section: String = "npc-birthdays-data"

# Spec-locked (npc_id, season, day) triples — written verbatim, do not change.
const LOCKED: Array = [
	["ek", "hot", 12],
	["fah", "hot", 24],
	["ploy", "monsoon", 12],
	["chang", "monsoon", 20],
	["klong", "cool", 18],
	["yaa", "cool", 24],
]
const ALL_SEASONS: Array = ["hot", "monsoon", "cool"]

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  %s :: %s" % [_section, label])
	else:
		_failed += 1
		print("  FAIL  %s :: %s" % [_section, label])

# Returns the most recent captured line spoken by `speaker`, ignoring any
# unrelated ambient dialogue that may have landed in `captured` in the
# same frame. "" if none.
func _line_for(captured: Array, speaker: String) -> String:
	for i in range(captured.size() - 1, -1, -1):
		var entry: Array = captured[i]
		if String(entry[0]) == speaker:
			return String(entry[1])
	return ""

func _run_all() -> void:
	var sb: Node = root.get_node_or_null("SignalBus")
	var gd: Node = root.get_node_or_null("GameData")
	_check(sb != null, "SignalBus autoload present")
	_check(gd != null, "GameData autoload present")
	if sb == null or gd == null:
		return
	var db: GDScript = load("res://scripts/narrative/DialogueDB.gd") as GDScript
	_check(db != null, "DialogueDB.gd loads")
	if db == null:
		return

	# --- Data table: exact triples hit, everything else misses. ---
	_section = "npc-birthdays-data"
	_check(int((db.NPC_BIRTHDAYS as Dictionary).size()) == 6,
		"NPC_BIRTHDAYS holds exactly the 6 romance candidates")
	for triple: Array in LOCKED:
		var npc_id: String = String(triple[0])
		var season: String = String(triple[1])
		var day: int = int(triple[2])
		_check(db.is_birthday(npc_id, season, day),
			"is_birthday true for locked triple (%s, %s, %d)" % [npc_id, season, day])
		# Off-by-one days miss, same season.
		_check(not db.is_birthday(npc_id, season, day - 1),
			"is_birthday false for day-1 (%s, %s, %d)" % [npc_id, season, day - 1])
		_check(not db.is_birthday(npc_id, season, day + 1),
			"is_birthday false for day+1 (%s, %s, %d)" % [npc_id, season, day + 1])
		# Same day in the other two seasons misses.
		for other: String in ALL_SEASONS:
			if other == season:
				continue
			_check(not db.is_birthday(npc_id, other, day),
				"is_birthday false for wrong season (%s, %s, %d)" % [npc_id, other, day])
	# NPCs without an entry never have a birthday (family, rivals, unknown).
	for npc_id: String in ["elder", "somchai", "somsri", "yai", "ohm", "", "ekk"]:
		_check(not db.is_birthday(npc_id, "hot", 12),
			"is_birthday false for non-candidate '%s'" % npc_id)
	# Additive-only guard: the pre-existing gift table is untouched.
	_check(db.gift_tier("ek", "mango") == "loved", "gift_tier(ek, mango) still loved")
	_check(db.gift_affinity("loved") == 20, "gift_affinity(loved) still 20")
	_check(db.gift_affinity("liked") == 10, "gift_affinity(liked) still 10")
	_check(db.gift_affinity("neutral") == 5, "gift_affinity(neutral) still 5")

	# --- World-based gift + overlay tests. ---
	_section = "npc-birthdays-gift"
	var world: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	var tm: Node = sb.time_manager
	_check(tm != null, "SignalBus.time_manager present for day/season control")
	if tm == null:
		world.queue_free()
		return

	var captured: Array = []
	var handler := func(speaker: String, text: String) -> void:
		captured.append([speaker, text])
	sb.connect("show_dialogue", handler)

	var ek: Node = world.get_node_or_null("EkNPC")
	_check(ek != null, "EkNPC present in World")
	if ek == null:
		sb.disconnect("show_dialogue", handler)
		world.queue_free()
		return
	var ek_name: String = String(ek.get("display_name"))
	_check(String(ek.get("npc_id")) == "ek", "EkNPC npc_id is ek")

	# Drive the REAL _give_gift() (not try_interact(), whose weekly-
	# engagement bonus would pollute the delta comparison). Mango is
	# ek's loved gift and is in GameData.FOOD_ITEMS, so the picker
	# always finds exactly this one item when it is the only held food.
	var table_delta: int = db.gift_affinity(db.gift_tier("ek", "mango"))

	# Non-birthday baseline: hot, day 11 (off-by-one from ek's hot/12).
	tm.set("day", 11)
	tm.set("current_season", "hot")
	gd.set("current_season", "hot")
	(gd.get("affinity") as Dictionary)["ek"] = 0
	(gd.get("inventory") as Dictionary).clear()
	gd.call("add_item", "mango", 1)
	captured.clear()
	var gave_normal: bool = bool(ek.call("_give_gift"))
	var delta_normal: int = int((gd.get("affinity") as Dictionary).get("ek", -1))
	var line_normal: String = _line_for(captured, ek_name)
	_check(gave_normal, "non-birthday gift is accepted")
	_check(delta_normal == table_delta,
		"non-birthday gift grants the plain table delta (got %d)" % delta_normal)
	_check(not line_normal.contains("birthday"),
		"non-birthday gift line has no birthday mention (got '%s')" % line_normal)

	# Birthday: hot, day 12 — same gift, same NPC.
	tm.set("day", 12)
	tm.set("current_season", "hot")
	gd.set("current_season", "hot")
	(gd.get("affinity") as Dictionary)["ek"] = 0
	(gd.get("inventory") as Dictionary).clear()
	gd.call("add_item", "mango", 1)
	captured.clear()
	var gave_bday: bool = bool(ek.call("_give_gift"))
	var delta_bday: int = int((gd.get("affinity") as Dictionary).get("ek", -1))
	var line_bday: String = _line_for(captured, ek_name)
	_check(gave_bday, "birthday gift is accepted")
	_check(delta_normal > 0 and delta_bday == delta_normal * 2,
		"birthday gift doubles the same-gift delta (%d vs %d)" % [delta_bday, delta_normal])
	_check(line_bday.contains("birthday"),
		"birthday gift fires the birthday-specific line (got '%s')" % line_bday)

	# Right day, wrong season (cool, day 12) — no bonus, no line.
	tm.set("day", 12)
	tm.set("current_season", "cool")
	gd.set("current_season", "cool")
	(gd.get("affinity") as Dictionary)["ek"] = 0
	(gd.get("inventory") as Dictionary).clear()
	gd.call("add_item", "mango", 1)
	captured.clear()
	ek.call("_give_gift")
	var delta_wrong_season: int = int((gd.get("affinity") as Dictionary).get("ek", -1))
	var line_wrong_season: String = _line_for(captured, ek_name)
	_check(delta_wrong_season == delta_normal,
		"right day but wrong season grants the plain delta (got %d)" % delta_wrong_season)
	_check(not line_wrong_season.contains("birthday"),
		"right day but wrong season fires the normal tier line")

	sb.disconnect("show_dialogue", handler)

	# --- RelationshipStatus BirthdayLabel: the discovery path. ---
	_section = "npc-birthdays-status"
	var status: Node = world.get_node_or_null("RelationshipStatus")
	_check(status != null, "World.tscn has a real RelationshipStatus node")
	if status != null:
		var expected: Dictionary = {
			"ek": "Birthday: Hot, day 12",
			"fah": "Birthday: Hot, day 24",
			"ploy": "Birthday: Monsoon, day 12",
			"chang": "Birthday: Monsoon, day 20",
			"klong": "Birthday: Cool, day 18",
			"yaa": "Birthday: Cool, day 24",
		}
		for npc_id: String in expected.keys():
			status.call("open", npc_id, npc_id.capitalize())
			await process_frame
			var bday_label: Label = status.get_node_or_null("Panel/VBox/BirthdayLabel") as Label
			_check(bday_label != null,
				"BirthdayLabel node exists when opened for %s" % npc_id)
			if bday_label != null:
				_check(bday_label.visible and bday_label.text == String(expected[npc_id]),
					"BirthdayLabel shows '%s' for %s (got '%s')" % [String(expected[npc_id]), npc_id, bday_label.text])
		# An NPC without a birthday hides the label instead of a placeholder.
		status.call("open", "elder", "Elder")
		await process_frame
		var elder_label: Label = status.get_node_or_null("Panel/VBox/BirthdayLabel") as Label
		if elder_label == null:
			_check(true, "BirthdayLabel absent-safe for NPCs without a birthday")
		else:
			_check(elder_label.visible == false,
				"BirthdayLabel hidden for NPCs without a birthday")
		status.call("close")
		await process_frame

	(gd.get("affinity") as Dictionary).erase("ek")
	(gd.get("inventory") as Dictionary).clear()
	world.queue_free()
	await process_frame

func _initialize() -> void:
	await _run_all()
	print("\n=== NPC-BIRTHDAYS TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("NPC-BIRTHDAYS GATE FAILED: %d failing checks" % _failed)
	quit(1 if _failed > 0 else 0)
