extends SceneTree
# TASK-385 gate — family NPCs surface a once-per-day gift hint for their
# linked candidate (first talk of the day only, no mechanical reward).
# Kwan/chang is deliberately excluded (Somchai is a shared mentor, not her
# family NPC) — covered here as a never-hints regression guard.
#
# Standalone --script invocation (wired into scripts/ci/run_gate.sh):
#   godot --headless --path . --script res://tests/test_family_gift_hints.gd
#
# Code Quality Review fix (2026-09-05): the original capture handler
# stored raw dialogue TEXT only, and asserted `captured.size() == 1`.
# This was genuinely flaky (~1/3 of runs, reproduced both standalone and
# in the full gate chain): some other ambient system in the real
# World.tscn (a scheduled festival trigger, e.g. WanSartTrigger.gd, was
# observed firing "Wan Sart — prepare kra yasat...") can emit an
# unrelated SignalBus.show_dialogue in the exact same frame as the
# NPC interaction under test, since World's own TimeManager keeps
# ticking in the background across every awaited frame. The handler
# now captures [speaker, text] pairs and every check filters to the
# specific NPC's own display_name, so ambient noise from unrelated
# systems can no longer corrupt an assertion.

var _passed: int = 0
var _failed: int = 0
var _section: String = "family-gift-hints"

# Spec-locked family NPC -> candidate links (mirrors FlavorNPC.gd's
# FAMILY_GIFT_CANDIDATE; Kwan/chang deliberately absent).
const FAMILY_LINKS: Dictionary = {
	"somsri": "ploy",
	"charoen": "fah",
	"gaew": "ek",
	"boonchu": "klong",
	"ampai": "yaa",
}
const NODE_NAMES: Dictionary = {
	"somsri": "SomsriNPC",
	"charoen": "CharoenNPC",
	"gaew": "GaewNPC",
	"boonchu": "BoonchuNPC",
	"ampai": "AmpaiNPC",
}

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  %s :: %s" % [_section, label])
	else:
		_failed += 1
		print("  FAIL  %s :: %s" % [_section, label])

# Expected hint line, read from the REAL GIFT_PREFERENCES at test time so
# this doesn't silently drift if the data changes later (loved[0] preferred,
# liked[0] fallback — same rule as the implementation).
func _expected_hint(db: GDScript, candidate_id: String) -> String:
	var prefs: Dictionary = db.GIFT_PREFERENCES.get(candidate_id, {})
	var loved: Array = prefs.get("loved", [])
	var item_id: String = ""
	if not loved.is_empty():
		item_id = String(loved[0])
	else:
		var liked: Array = prefs.get("liked", [])
		if not liked.is_empty():
			item_id = String(liked[0])
	return "She's always going on about %s." % String(item_id).replace("_", " ")

# Drive the REAL input path (same InputEventAction pattern
# test_npc_roster_wiring.gd uses) — _player_in_range flipped on directly
# so the test isn't blocked on Area2D collision in headless mode.
func _press(npc: Node) -> void:
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	npc.call("_unhandled_input", ev)
	await process_frame

# Returns the most recent captured line spoken by `speaker`, ignoring any
# unrelated ambient dialogue (see the module comment above) that may have
# landed in `captured` in the same frame. "" if none.
func _line_for(captured: Array, speaker: String) -> String:
	for i in range(captured.size() - 1, -1, -1):
		var entry: Array = captured[i]
		if String(entry[0]) == speaker:
			return String(entry[1])
	return ""

# Count of captured lines actually spoken by `speaker` (ignores noise).
func _count_for(captured: Array, speaker: String) -> int:
	var n: int = 0
	for entry: Array in captured:
		if String(entry[0]) == speaker:
			n += 1
	return n

func _run_all() -> void:
	var sb: Node = root.get_node_or_null("SignalBus")
	var gd: Node = root.get_node_or_null("GameData")
	_check(sb != null, "SignalBus autoload present")
	_check(gd != null, "GameData autoload present")
	if sb == null or gd == null:
		return
	var db: GDScript = load("res://scripts/narrative/DialogueDB.gd") as GDScript
	_check(db != null, "DialogueDB.gd loads")
	var flavor: GDScript = load("res://scripts/narrative/FlavorDialogue.gd") as GDScript
	_check(flavor != null, "FlavorDialogue.gd loads")
	if db == null or flavor == null:
		return

	# --- Case 5 first (no world needed): save/load round-trip. ---
	_section = "family-gift-hints-save"
	var sm: Node = load("res://scripts/persistence/SaveManager.gd").new()
	gd.family_gift_hint_last_day = {"somsri": 7, "ampai": 6}
	_check(sm.save_game(), "save_game succeeds with hint state present")
	gd.family_gift_hint_last_day.clear()
	_check(sm.load_game(), "load_game succeeds")
	_check(int((gd.family_gift_hint_last_day as Dictionary).get("somsri", -1)) == 7,
		"somsri hint day round-trips through save/load")
	_check(int((gd.family_gift_hint_last_day as Dictionary).get("ampai", -1)) == 6,
		"ampai hint day round-trips through save/load")
	gd.family_gift_hint_last_day.clear()

	# --- World-based talk tests. ---
	_section = "family-gift-hints"
	var world: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	var tm: Node = sb.time_manager
	_check(tm != null, "SignalBus.time_manager present for day control")
	if tm == null:
		world.queue_free()
		return

	var captured: Array = []
	var handler := func(speaker: String, text: String) -> void:
		captured.append([speaker, text])
	sb.connect("show_dialogue", handler)

	var somsri: Node = world.get_node_or_null("SomsriNPC")
	_check(somsri != null, "SomsriNPC present in World")
	if somsri == null:
		sb.disconnect("show_dialogue", handler)
		world.queue_free()
		return
	var somsri_name: String = String(somsri.get("display_name"))
	somsri.set("_player_in_range", true)
	var ploy_hint: String = _expected_hint(db, "ploy")
	_check(not ploy_hint.contains("_"), "expected hint uses display name (no underscores)")

	# Case 1: first talk of the day surfaces the exact hint line.
	tm.set("day", 5)
	captured.clear()
	await _press(somsri)
	_check(_count_for(captured, somsri_name) == 1 and _line_for(captured, somsri_name) == ploy_hint,
		"first talk of the day to Somsri surfaces the ploy gift hint verbatim")
	_check(int((gd.family_gift_hint_last_day as Dictionary).get("somsri", -1)) == 5,
		"hint talk records day 5 in family_gift_hint_last_day")
	_check(int((gd.affinity as Dictionary).get("somsri", 0)) == 0,
		"hearing the hint grants no affinity (purely informational)")

	# Case 2: second talk the SAME day → normal flavor cycle, no hint.
	captured.clear()
	await _press(somsri)
	var pool: Array = flavor.FLAVOR_LINES.get("somsri", [])
	var line2: String = _line_for(captured, somsri_name)
	_check(_count_for(captured, somsri_name) == 1 and line2 == String(pool[0]),
		"second talk same day returns to normal flavor cycle (pool[0], hint untouched the cycle)")
	_check(not line2.contains("always going on about"),
		"second talk same day does NOT repeat the hint")

	# Case 3: next day re-arms the hint, exactly once.
	tm.set("day", 6)
	captured.clear()
	await _press(somsri)
	_check(_count_for(captured, somsri_name) == 1 and _line_for(captured, somsri_name) == ploy_hint,
		"first talk on the next day surfaces the hint again")
	captured.clear()
	await _press(somsri)
	_check(_count_for(captured, somsri_name) == 1 and _line_for(captured, somsri_name) == String(pool[1]),
		"second talk on the next day is back to flavor cycling (pool[1]) with no hint")
	somsri.set("_player_in_range", false)

	# All 5 family NPCs hint on first talk (fresh day so each is armed),
	# each naming a real item from their own candidate's preferences.
	tm.set("day", 7)
	for npc_id: String in FAMILY_LINKS.keys():
		var node: Node = world.get_node_or_null(String(NODE_NAMES[npc_id]))
		_check(node != null, "%s present in World" % String(NODE_NAMES[npc_id]))
		if node == null:
			continue
		var node_name: String = String(node.get("display_name"))
		node.set("_player_in_range", true)
		captured.clear()
		await _press(node)
		var want: String = _expected_hint(db, String(FAMILY_LINKS[npc_id]))
		_check(_count_for(captured, node_name) == 1 and _line_for(captured, node_name) == want,
			"first talk to %s hints at %s's real gift item" % [npc_id, String(FAMILY_LINKS[npc_id])])
		node.set("_player_in_range", false)

	# Case 4: Somchai (VillagerNPC, Kwan's shared mentor — NOT her family
	# NPC) never hints, across multiple talks and a day boundary.
	_section = "family-gift-hints-kwan"
	var somchai: Node = world.get_node_or_null("SomchaiNPC")
	_check(somchai != null, "SomchaiNPC present in World")
	if somchai != null:
		gd.inventory.clear() # keep VillagerNPC.talk() on the dialogue branch, not gifting
		somchai.set("_player_in_range", true)
		var saw_hint: bool = false
		for d: int in [7, 8]:
			tm.set("day", d)
			for _i in range(3):
				captured.clear()
				somchai.call("talk")
				await process_frame
				for entry: Array in captured:
					if String(entry[1]).contains("always going on about"):
						saw_hint = true
		_check(not saw_hint, "Somchai never surfaces a gift hint (3 talks x 2 days)")
		_check(not (gd.family_gift_hint_last_day as Dictionary).has("somchai"),
			"talking to Somchai writes no family_gift_hint_last_day entry")
		somchai.set("_player_in_range", false)

	sb.disconnect("show_dialogue", handler)
	world.queue_free()
	await process_frame

func _initialize() -> void:
	await _run_all()
	print("\n=== FAMILY-GIFT-HINTS TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("FAMILY-GIFT-HINTS GATE FAILED: %d failing checks" % _failed)
	quit(1 if _failed > 0 else 0)
