extends SceneTree
# TASK-384 gate — family reacts to marriage proposal/wedding (one-shot).
# Covers both code paths: FlavorNPC-based (Charoen) + VillagerNPC-based
# (Somchai). Drives the real World.tscn NPCs via the real "interact"
# input path (same pattern as test_npc_roster_wiring.gd /
# test_relationship_status.gd), catching orphan-wiring regressions.

const SaveManagerScript: GDScript = preload("res://scripts/persistence/SaveManager.gd")

var _passed: int = 0
var _failed: int = 0

const CHAROEN_LINE: String = "Fah brought home news today — married, she says, like it's a small thing. It isn't. Take care of her out there on the water."
const SOMCHAI_LINE: String = "Chang told me over the workbench, like it was just another piece of news. I had to put the chisel down for a minute."

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  family-marriage-reactions :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  family-marriage-reactions :: %s" % label)

func _initialize() -> void:
	await _run_all()
	print("\n=== FAMILY-MARRIAGE-REACTIONS TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("FAMILY-MARRIAGE-REACTIONS GATE FAILED")
	quit(1 if _failed > 0 else 0)

func _press_interact(npc: Node) -> Array:
	var sb: Node = root.get_node("SignalBus")
	var captured: Array = []
	var handler := func(speaker: String, text: String) -> void:
		captured.append([speaker, text])
	sb.connect("show_dialogue", handler)
	var ev: InputEvent = InputEventAction.new()
	(ev as InputEventAction).action = "interact"
	(ev as InputEventAction).pressed = true
	npc.call("_unhandled_input", ev)
	await process_frame
	sb.disconnect("show_dialogue", handler)
	return captured

func _run_all() -> void:
	var sb: Node = root.get_node("SignalBus")
	var gd: Node = root.get_node("GameData")
	_check(sb != null, "SignalBus autoload present")
	_check(gd != null, "GameData autoload present")
	if sb == null or gd == null:
		return

	# Clean slate — empty inventory so VillagerNPC's _give_gift() branch
	# never swallows the seasonal/reaction line under test.
	gd.inventory.clear()
	gd.affinity.clear()
	gd.married = false
	gd.spouse = ""
	(gd.family_marriage_reaction_shown as Dictionary).clear()
	gd.current_season = "cool"

	var world: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	var charoen: Node = world.get_node_or_null("CharoenNPC")
	var somchai: Node = world.get_node_or_null("SomchaiNPC")
	var somsri: Node = world.get_node_or_null("SomsriNPC")
	_check(charoen != null, "World.tscn has CharoenNPC")
	_check(somchai != null, "World.tscn has SomchaiNPC")
	_check(somsri != null, "World.tscn has SomsriNPC")
	if charoen == null or somchai == null or somsri == null:
		world.queue_free()
		return

	var FlavorDialogueScript: GDScript = load("res://scripts/narrative/FlavorDialogue.gd") as GDScript
	var charoen_pool: Array = FlavorDialogueScript.FLAVOR_LINES.get("charoen", [])
	_check(charoen_pool.size() == 3, "Charoen has 3 normal flavor lines (unaffected by this task)")

	# --- 1. Before marriage: normal lines, unaffected ---
	charoen.set("_player_in_range", true)
	var before_c: Array = await _press_interact(charoen)
	_check(before_c.size() == 1, "Charoen: 1 interact press -> 1 emit before marriage")
	if before_c.size() >= 1:
		_check(String(before_c[0][1]) == String(charoen_pool[0]), "Charoen before marriage shows normal flavor line 0")
		_check(String(before_c[0][1]) != CHAROEN_LINE, "Charoen before marriage does NOT show the reaction line")

	somchai.set("_player_in_range", true)
	var before_s: Array = await _press_interact(somchai)
	_check(before_s.size() == 1, "Somchai: 1 interact press -> 1 emit before marriage")
	if before_s.size() >= 1:
		_check(String(before_s[0][1]) != SOMCHAI_LINE, "Somchai before marriage does NOT show the reaction line")
		_check(String(before_s[0][1]) != "", "Somchai before marriage shows a normal seasonal line")

	# --- 2. After marriage: NEXT talk shows the EXACT locked line ---
	gd.married = true
	gd.spouse = "fah"
	var react_c: Array = await _press_interact(charoen)
	_check(react_c.size() == 1, "Charoen: 1 interact press -> 1 emit after fah marriage")
	if react_c.size() >= 1:
		_check(String(react_c[0][1]) == CHAROEN_LINE, "Charoen after fah marriage shows the EXACT locked reaction line")
	_check(bool((gd.family_marriage_reaction_shown as Dictionary).get("charoen", false)), "charoen marked shown in family_marriage_reaction_shown")

	gd.spouse = "chang"
	# TASK-384 Code Quality Review fix: Somchai's talk() path goes through
	# VillagerNPC._give_gift() before reaching the marriage-reaction check
	# (see VillagerNPC.gd's talk() ordering) -- something during World's
	# boot (a quest-offer/starter-kit grant, not this task's own code)
	# puts a rice_grain in inventory between the "before marriage" check
	# above and here, so _give_gift() fires first and swallows the
	# reaction line. Clear immediately before each Somchai interaction
	# under test so this test isolates the marriage-reaction path only.
	gd.inventory.clear()
	var react_s: Array = await _press_interact(somchai)
	_check(react_s.size() == 1, "Somchai: 1 interact press -> 1 emit after chang marriage")
	if react_s.size() >= 1:
		_check(String(react_s[0][1]) == SOMCHAI_LINE, "Somchai after chang marriage shows the EXACT locked reaction line")
	_check(bool((gd.family_marriage_reaction_shown as Dictionary).get("somchai", false)), "somchai marked shown in family_marriage_reaction_shown")

	# --- 3. SECOND talk reverts to normal cycling (no repeat) ---
	gd.spouse = "fah"
	var again_c: Array = await _press_interact(charoen)
	_check(again_c.size() == 1, "Charoen: second post-marriage press -> 1 emit")
	if again_c.size() >= 1:
		_check(String(again_c[0][1]) != CHAROEN_LINE, "Charoen second talk does NOT repeat the reaction line")
		_check(charoen_pool.has(String(again_c[0][1])), "Charoen second talk reverted to normal flavor-line cycling")

	gd.spouse = "chang"
	gd.inventory.clear()
	var again_s: Array = await _press_interact(somchai)
	_check(again_s.size() == 1, "Somchai: second post-marriage press -> 1 emit")
	if again_s.size() >= 1:
		_check(String(again_s[0][1]) != SOMCHAI_LINE, "Somchai second talk does NOT repeat the reaction line")

	# --- 5. Wrong-candidate family NPC unaffected (Somsri when spouse == fah) ---
	gd.spouse = "fah"
	(gd.family_marriage_reaction_shown as Dictionary).erase("somsri")
	somsri.set("_player_in_range", true)
	var somsri_pool: Array = FlavorDialogueScript.FLAVOR_LINES.get("somsri", [])
	var wrong: Array = await _press_interact(somsri)
	_check(wrong.size() == 1, "Somsri: 1 interact press -> 1 emit when spouse == fah (not ploy)")
	if wrong.size() >= 1:
		_check(somsri_pool.has(String(wrong[0][1])), "Somsri with spouse == fah shows normal flavor lines, never the reaction")
	_check(not bool((gd.family_marriage_reaction_shown as Dictionary).get("somsri", false)), "somsri NOT marked shown when the wrong candidate married")

	charoen.set("_player_in_range", false)
	somchai.set("_player_in_range", false)
	somsri.set("_player_in_range", false)

	# --- 4. Save/load round-trip (free the world first so the load's
	# scene_transition emit can't retarget the live tree mid-test) ---
	world.queue_free()
	await process_frame

	var sm: Node = SaveManagerScript.new()
	# State at save time: charoen + somchai shown, somsri not shown.
	_check(bool((gd.family_marriage_reaction_shown as Dictionary).get("charoen", false)), "pre-save: charoen shown flag set")
	_check(bool((gd.family_marriage_reaction_shown as Dictionary).get("somchai", false)), "pre-save: somchai shown flag set")
	var saved: bool = sm.save_game()
	_check(saved, "save_game() writes with the new field")
	(gd.family_marriage_reaction_shown as Dictionary).clear()
	_check((gd.family_marriage_reaction_shown as Dictionary).is_empty(), "shown dict wiped before load")
	var loaded: bool = sm.load_game()
	_check(loaded, "load_game() reads saved file back")
	_check(bool((gd.family_marriage_reaction_shown as Dictionary).get("charoen", false)), "round-trip restores charoen shown flag")
	_check(bool((gd.family_marriage_reaction_shown as Dictionary).get("somchai", false)), "round-trip restores somchai shown flag")
	_check(not bool((gd.family_marriage_reaction_shown as Dictionary).get("somsri", false)), "round-trip keeps somsri unshown")
	sm.queue_free()

	# Cleanup.
	gd.inventory.clear()
	gd.married = false
	gd.spouse = ""
	(gd.family_marriage_reaction_shown as Dictionary).clear()
