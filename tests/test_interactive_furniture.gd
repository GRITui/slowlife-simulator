extends SceneTree
# TASK-391 gate — 4 interactive furniture pieces (portrait, chair/bench,
# vase+marigold, transistor radio) on the existing FarmHouseFurniture
# grid-anchor placement system, plus the marigold ForageNode.
#
# Standalone --script invocation (wired into scripts/ci/run_gate.sh):
#   godot --headless --path . --script res://tests/test_interactive_furniture.gd
#
# Follows the tests/test_lone_npcs.gd convention exactly: real scene
# instantiation (FarmHouse.tscn for furniture, World.tscn for the forage
# node), InputEventAction "interact" presses driven through the REAL
# _unhandled_input entry point (place mode OFF), and a [speaker, text]-
# pair dialogue capture filtered by speaker name — NEVER a raw
# captured.size()==1 assertion, since ambient systems can emit unrelated
# SignalBus.show_dialogue in the same frame (that exact flake was already
# hit and fixed twice in this codebase).
#
# Locked lines (verbatim, do not paraphrase):
#   portrait: "You look at the portrait for a moment longer than you meant to."
#   sit:      "You sit a while. The day feels a little less long."
#   vase:     "The marigold brightens the room."

const FURNITURE_SCRIPT_PATH: String = "res://scenes/interiors/FarmHouseFurniture.gd"
const FARMHOUSE_PATH: String = "res://scenes/interiors/FarmHouse.tscn"
const WORLD_PATH: String = "res://scenes/core/World.tscn"
const SaveManagerScript: GDScript = preload("res://scripts/persistence/SaveManager.gd")
const LOCATION_ID: String = "farmhouse"

const PORTRAIT_LINE: String = "You look at the portrait for a moment longer than you meant to."
const SIT_LINE: String = "You sit a while. The day feels a little less long."
const VASE_FILLED_LINE: String = "The marigold brightens the room."

const NEW_ITEM_IDS: Array[String] = [
	"wall_portrait", "wooden_chair", "wooden_bench", "ceramic_vase", "transistor_radio",
]

var _passed: int = 0
var _failed: int = 0
var _section: String = "interactive-furniture"

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  %s :: %s" % [_section, label])
	else:
		_failed += 1
		print("  FAIL  %s :: %s" % [_section, label])

# Drive the REAL input path: place mode OFF, player standing on the
# target cell, a genuine InputEventAction delivered to the furniture
# node's own _unhandled_input (so both the empty-cell fallthrough and
# the per-item dispatch are exercised, not bypassed).
func _press_at(furniture: Node, player: Node2D, cell: Vector2i) -> void:
	player.global_position = Vector2(cell.x * 48 + 24, cell.y * 48 + 24)
	await process_frame
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	furniture.call("_unhandled_input", ev)
	await process_frame

# Returns the most recent captured line spoken by `speaker`, ignoring any
# unrelated ambient dialogue that may have landed in `captured` in the
# same frame. "" if none.
func _line_for(captured: Array, speaker: String) -> String:
	for i in range(captured.size() - 1, -1, -1):
		var entry: Array = captured[i]
		if String(entry[0]) == speaker:
			return String(entry[1])
	return ""

func _reset_furniture_state(gd: Node) -> void:
	(gd.inventory as Dictionary).clear()
	gd.set("placed_furniture", {})
	(gd.furniture_sit_last_day as Dictionary).clear()
	(gd.vase_has_flowers as Dictionary).clear()
	(gd.active_quests as Dictionary).clear()
	gd.set("harmony", 0)

func _run_all() -> void:
	var sb: Node = root.get_node_or_null("SignalBus")
	var gd: Node = root.get_node_or_null("GameData")
	_check(sb != null, "SignalBus autoload present")
	_check(gd != null, "GameData autoload present")
	if sb == null or gd == null:
		return
	var tm: Node = sb.get("time_manager")
	if tm == null:
		tm = root.get_node_or_null("TimeManager")
	_check(tm != null, "SignalBus.time_manager present for day control")
	if tm == null:
		return
	tm.set("auto_tick", false)

	# --- SELL_PRICES catalogue check (no scene needed). ---
	_section = "interactive-furniture-prices"
	# NOTE: SELL_PRICES is read through the live `gd` autoload instance,
	# never the bare `GameData` global — no other test references that
	# global directly, and doing so forces a dependency compile that
	# breaks under `godot --headless --script`.
	_check(int(gd.SELL_PRICES.get("marigold", 0)) == 5,
		"marigold sells for 5 (modest, in wild_turmeric's tier)")

	# --- Save/load round-trip for the new GameData fields (no scene needed). ---
	_section = "interactive-furniture-save"
	var sm: Node = SaveManagerScript.new()
	(gd.furniture_sit_last_day as Dictionary)["2,3"] = 7
	(gd.vase_has_flowers as Dictionary)["1,1"] = true
	_check(sm.save_game(), "save_game succeeds with interactive-furniture state present")
	(gd.furniture_sit_last_day as Dictionary).clear()
	(gd.vase_has_flowers as Dictionary).clear()
	_check(sm.load_game(), "load_game succeeds")
	_check(int((gd.furniture_sit_last_day as Dictionary).get("2,3", -1)) == 7,
		"furniture_sit_last_day round-trips through save/load (string key intact)")
	_check(bool((gd.vase_has_flowers as Dictionary).get("1,1", false)) == true,
		"vase_has_flowers round-trips through save/load (string key intact)")
	(gd.furniture_sit_last_day as Dictionary).clear()
	(gd.vase_has_flowers as Dictionary).clear()

	# --- Catalogue + market acquisition path (no scene needed). ---
	_section = "interactive-furniture-catalogue"
	var fscript: GDScript = load(FURNITURE_SCRIPT_PATH) as GDScript
	_check(fscript != null, "FarmHouseFurniture.gd loads")
	if fscript == null:
		return
	for item_id: String in NEW_ITEM_IDS:
		_check((fscript.DISPLAY_NAMES as Dictionary).has(item_id),
			"DISPLAY_NAMES catalogues '%s'" % item_id)
	_check(String((fscript.DISPLAY_NAMES as Dictionary).get("wall_portrait", "")) == "Portrait",
		"wall_portrait display name is 'Portrait'")
	_check(String((fscript.DISPLAY_NAMES as Dictionary).get("wooden_chair", "")) == "Chair",
		"wooden_chair display name is 'Chair'")
	_check(String((fscript.DISPLAY_NAMES as Dictionary).get("wooden_bench", "")) == "Bench",
		"wooden_bench display name is 'Bench'")
	_check(String((fscript.DISPLAY_NAMES as Dictionary).get("ceramic_vase", "")) == "Vase",
		"ceramic_vase display name is 'Vase'")
	_check(String((fscript.DISPLAY_NAMES as Dictionary).get("transistor_radio", "")) == "Radio",
		"transistor_radio display name is 'Radio'")
	# Acquisition path: the existing three furniture items are owned via
	# MarketManager.BUY_OFFERS (floor_rug 25 / cushion 15 / table 30, all
	# seasons) — the five new entries must follow that same path, not a
	# new one.
	var mm_script: GDScript = load("res://scripts/market/MarketManager.gd") as GDScript
	_check(mm_script != null, "MarketManager.gd loads")
	if mm_script != null:
		for item_id: String in NEW_ITEM_IDS:
			var seasons_found: int = 0
			for season in (mm_script.BUY_OFFERS as Dictionary).keys():
				for offer: Dictionary in ((mm_script.BUY_OFFERS as Dictionary)[season] as Array):
					if String(offer.get("item", "")) == item_id:
						seasons_found += 1
			_check(seasons_found == 3,
				"'%s' is a real MarketManager.BUY_OFFERS entry in all 3 seasons" % item_id)

	# --- FarmHouse interaction tests. ---
	_section = "interactive-furniture"
	var scene: PackedScene = load(FARMHOUSE_PATH) as PackedScene
	_check(scene != null, "FarmHouse.tscn loads")
	if scene == null:
		return
	_reset_furniture_state(gd)
	var farmhouse: Node = scene.instantiate()
	root.add_child(farmhouse)
	await process_frame
	await process_frame
	var furniture: Node2D = farmhouse.get_node_or_null("FarmHouseFurniture") as Node2D
	_check(furniture != null, "FarmHouseFurniture node exists in FarmHouse.tscn")
	if furniture == null:
		farmhouse.queue_free()
		return
	var player: Node2D = get_first_node_in_group("player") as Node2D
	_check(player != null, "InteriorBase auto-spawned a real Player in FarmHouse.tscn")
	if player == null:
		farmhouse.queue_free()
		return
	_check(not bool(furniture.get("_place_mode")),
		"place mode starts OFF (interaction path is live, not placement)")

	var captured: Array = []
	var handler := func(speaker: String, text: String) -> void:
		captured.append([speaker, text])
	sb.connect("show_dialogue", handler)

	# Place the five pieces directly through the shipped placement API
	# (the place/pickup flow itself is covered by test_farmhouse_
	# furniture.gd — here we need already-placed instances to interact
	# with). Open cells: portrait (2,2), chair (2,3), bench (0,2),
	# vase (3,3), radio (0,0); rug (5,4) for the generic fallback.
	var cells: Dictionary = {
		"wall_portrait": Vector2i(2, 2),
		"wooden_chair": Vector2i(2, 3),
		"wooden_bench": Vector2i(0, 2),
		"ceramic_vase": Vector2i(3, 3),
		"transistor_radio": Vector2i(0, 0),
		"floor_rug": Vector2i(5, 4),
	}
	for item_id: String in cells.keys():
		_check(gd.add_placed_furniture(LOCATION_ID, item_id, cells[item_id]),
			"'%s' places at %s via the existing placement API" % [item_id, str(cells[item_id])])
	await process_frame
	_check(furniture.has_node("Portrait_2_2"), "portrait sprite spawns as 'Portrait_2_2'")
	_check(furniture.has_node("Chair_2_3"), "chair sprite spawns as 'Chair_2_3'")
	_check(furniture.has_node("Bench_0_2"), "bench sprite spawns as 'Bench_0_2'")
	_check(furniture.has_node("Vase_3_3"), "vase sprite spawns as 'Vase_3_3'")
	_check(furniture.has_node("Radio_0_0"), "radio sprite spawns as 'Radio_0_0'")

	# New items are also placeable through the real primed-item flow
	# (cycle -> prime -> place), not just the direct API above: clear one
	# cell, prime the chair from owned inventory, and place it for real.
	_check(gd.remove_placed_furniture(LOCATION_ID, "wooden_chair", cells["wooden_chair"]),
		"chair removed again so the primed-item flow can re-place it")
	gd.add_item("wooden_chair", 1)
	furniture.set("_place_mode", true)
	furniture.set("_primed_furniture_id", "wooden_chair")
	await _press_at(furniture, player, cells["wooden_chair"])
	# NOTE: _press_at drives _unhandled_input while place mode is on, so
	# this press runs the real place branch (not the interaction branch).
	_check(gd.has_placed_furniture_at(LOCATION_ID, cells["wooden_chair"]),
		"wooden_chair re-places at (2,3) through the real primed-item flow")
	_check(not gd.has_item("wooden_chair", 1),
		"primed-item placement consumes the chair from inventory")
	furniture.set("_place_mode", false)
	await process_frame

	# --- Portrait: exact locked line, repeatable, no state. ---
	_section = "interactive-furniture-portrait"
	captured.clear()
	await _press_at(furniture, player, cells["wall_portrait"])
	_check(_line_for(captured, "Farmer") == PORTRAIT_LINE,
		"portrait fires its exact locked line")
	captured.clear()
	await _press_at(furniture, player, cells["wall_portrait"])
	_check(_line_for(captured, "Farmer") == PORTRAIT_LINE,
		"portrait repeats its exact locked line on a second interact")
	_check((gd.furniture_sit_last_day as Dictionary).is_empty() and (gd.vase_has_flowers as Dictionary).is_empty(),
		"portrait tracks no state (sit/vase dicts still empty)")

	# --- Chair/bench: once-per-day per instance, +5 harmony. ---
	_section = "interactive-furniture-sit"
	tm.set("day", 10)
	gd.set("harmony", 0)
	captured.clear()
	await _press_at(furniture, player, cells["wooden_chair"])
	_check(_line_for(captured, "Farmer") == SIT_LINE,
		"chair fires its exact locked sit line")
	_check(int(gd.get("harmony")) == 5,
		"chair grants a small flat +5 harmony (modest, capped-small-bonus feel)")
	_check(int((gd.furniture_sit_last_day as Dictionary).get("2,3", -1)) == 10,
		"chair records day 10 for its own cell-string key")
	var harmony_after_sit: int = int(gd.get("harmony"))
	captured.clear()
	await _press_at(furniture, player, cells["wooden_chair"])
	var cooldown_line: String = _line_for(captured, "Farmer")
	_check(cooldown_line != "" and cooldown_line != SIT_LINE,
		"same-day second sit is blocked with a distinct cooldown line (not the main line)")
	_check(int(gd.get("harmony")) == harmony_after_sit,
		"blocked same-day sit grants no further harmony")
	# The bench is a SEPARATE instance with its own cooldown, even today.
	captured.clear()
	await _press_at(furniture, player, cells["wooden_bench"])
	_check(_line_for(captured, "Farmer") == SIT_LINE,
		"bench shares the sit behavior but cools down per-instance (works same day)")
	_check(int(gd.get("harmony")) == harmony_after_sit + 5,
		"bench grants its own +5 harmony independently")
	# Next day re-arms the chair.
	tm.set("day", 11)
	captured.clear()
	await _press_at(furniture, player, cells["wooden_chair"])
	_check(_line_for(captured, "Farmer") == SIT_LINE,
		"chair re-arms the next day (sit line again)")
	_check(int(gd.get("harmony")) == harmony_after_sit + 10,
		"next-day sit grants harmony again (+5)")

	# --- Vase: needs a marigold, consumes exactly 1, then stays filled. ---
	_section = "interactive-furniture-vase"
	captured.clear()
	await _press_at(furniture, player, cells["ceramic_vase"])
	var need_line: String = _line_for(captured, "Farmer")
	_check(need_line != "" and need_line != VASE_FILLED_LINE,
		"empty vase with no marigold prompts for a flower (not the filled line)")
	_check(not (gd.vase_has_flowers as Dictionary).has("3,3"),
		"failed vase interact records no flower state")
	gd.add_item("marigold", 2)
	captured.clear()
	await _press_at(furniture, player, cells["ceramic_vase"])
	_check(_line_for(captured, "Farmer") == VASE_FILLED_LINE,
		"vase with a marigold fires its exact locked filled line")
	_check(int((gd.inventory as Dictionary).get("marigold", 0)) == 1,
		"filling the vase consumes exactly 1 marigold (2 -> 1)")
	_check(bool((gd.vase_has_flowers as Dictionary).get("3,3", false)) == true,
		"vase records flower state under its cell-string key")
	captured.clear()
	await _press_at(furniture, player, cells["ceramic_vase"])
	var already_line: String = _line_for(captured, "Farmer")
	_check(already_line != "" and already_line != VASE_FILLED_LINE,
		"repeat interact on a filled vase shows an already-done line (not the filled line)")
	_check(int((gd.inventory as Dictionary).get("marigold", 0)) == 1,
		"second interact on the same vase consumes no further marigold")

	# --- Generic fallback for pieces with no interaction (rug). ---
	_section = "interactive-furniture-fallback"
	captured.clear()
	await _press_at(furniture, player, cells["floor_rug"])
	var rug_line: String = _line_for(captured, "Farmer")
	_check(rug_line != "" and rug_line != PORTRAIT_LINE and rug_line != SIT_LINE and rug_line != VASE_FILLED_LINE,
		"rug (no special interaction) falls back to a generic line, not a locked one")

	# --- Radio: forecast + festival countdown from LIVE state. ---
	# Expected values below are hand-computed from the 7 (day, season)
	# pairs (season order hot->monsoon->cool, 30-day seasons) — they are
	# the oracle, not a copy of the implementation's formula:
	#   (day 1, cool)    dos=1:  Wan Sart (5,cool) is 4 days out (min).
	#   (day 88, monsoon) dos=28: Ok Phansa (28,monsoon) is today.
	#   (day 6, cool)    dos=6:  Loy Krathong (7,cool) is tomorrow (1 day).
	#   (day 30, cool)   dos=30: Songkran (3,hot) is 3 days out (season
	#                    boundary + year-wraparound case: same-season days
	#                    already passed sit ~a year away, not negative).
	_section = "interactive-furniture-radio"
	tm.set("next_weather", "rain")
	tm.set("day", 1)
	tm.set("current_season", "cool")
	captured.clear()
	await _press_at(furniture, player, cells["transistor_radio"])
	var radio_line: String = _line_for(captured, "Radio")
	_check(radio_line.contains("Tomorrow looks rain."),
		"radio reads the live forecast (next_weather='rain')")
	_check(radio_line.contains("Wan Sart") and radio_line.contains("4 days"),
		"radio countdown correct at (day 1, cool): Wan Sart in 4 days")
	_check(not radio_line.to_lower().contains("headman"),
		"radio omits the quest-hint part when no headman quest is active (no placeholder)")
	tm.set("day", 88)
	tm.set("current_season", "monsoon")
	tm.set("next_weather", "overcast")
	captured.clear()
	await _press_at(furniture, player, cells["transistor_radio"])
	radio_line = _line_for(captured, "Radio")
	_check(radio_line.contains("Tomorrow looks overcast."),
		"radio re-reads the forecast live on the next call (no memoizing)")
	_check(radio_line.contains("Ok Phansa") and radio_line.contains("today"),
		"radio countdown correct at (day 88, monsoon): Ok Phansa is today")
	tm.set("day", 6)
	tm.set("current_season", "cool")
	captured.clear()
	await _press_at(furniture, player, cells["transistor_radio"])
	radio_line = _line_for(captured, "Radio")
	_check(radio_line.contains("Loy Krathong") and radio_line.contains("in 1 day") and not radio_line.contains("in 1 days"),
		"radio countdown correct at (day 6, cool): Loy Krathong in 1 day (singular)")
	tm.set("day", 30)
	tm.set("current_season", "cool")
	captured.clear()
	await _press_at(furniture, player, cells["transistor_radio"])
	radio_line = _line_for(captured, "Radio")
	_check(radio_line.contains("Songkran") and radio_line.contains("3 days"),
		"radio countdown correct across the season boundary at (day 30, cool): Songkran in 3 days")

	# --- Radio headman quest hint: omitted live, shown when armed. ---
	# Verified against the shipped data: NO quest in quests.json has
	# giver_npc_id "headman", so the omit-path above is the live behavior
	# until a headman quest ships. The append path is covered by injecting
	# a headman chain into a real QuestLog node (white-box, same as the
	# lone-NPC tests' direct GameData state setups).
	_section = "interactive-furniture-radio-quest"
	var ql_script: GDScript = load("res://scripts/persistence/QuestLog.gd") as GDScript
	_check(ql_script != null, "QuestLog.gd loads")
	var ql: Node = null
	if ql_script != null:
		ql = (ql_script as GDScript).new() as Node
		ql.name = "QuestLog"
		root.add_child(ql)
		await process_frame
		_check(ql.is_in_group("quest_log"), "QuestLog test node registers in group 'quest_log'")
		var chains: Dictionary = ql.get("_chains")
		var has_live_headman: bool = false
		for quest_id: String in chains.keys():
			if String((chains[quest_id] as Dictionary).get("giver_npc_id", "")) == "headman":
				has_live_headman = true
		_check(not has_live_headman,
			"no shipped quest chain has giver_npc_id 'headman' (omit-path is the live behavior)")
		(chains as Dictionary)["headman_test_errand"] = {
			"id": "headman_test_errand",
			"display_name": "Test Errand",
			"giver_npc_id": "headman",
			"objectives": ["test_obj"],
		}
		ql.set("_chains", chains)
		gd.start_quest("headman_test_errand", 1)
		tm.set("day", 1)
		tm.set("current_season", "cool")
		tm.set("next_weather", "clear")
		captured.clear()
		await _press_at(furniture, player, cells["transistor_radio"])
		radio_line = _line_for(captured, "Radio")
		_check(radio_line.to_lower().contains("headman") and radio_line.contains("Test Errand"),
			"radio appends a headman hint naming the active quest when one exists")
		_check(radio_line.contains("Tomorrow looks clear."),
			"radio keeps the forecast part when the quest hint is appended (one combined emit)")
		gd.complete_objective("headman_test_errand", "test_obj")
		_check(gd.is_quest_complete("headman_test_errand"),
			"injected quest completes after its only objective (sanity check on the fixture)")
		captured.clear()
		await _press_at(furniture, player, cells["transistor_radio"])
		radio_line = _line_for(captured, "Radio")
		_check(not radio_line.to_lower().contains("headman"),
			"radio omits the hint for a completed (paid-out) headman quest")
		(gd.active_quests as Dictionary).erase("headman_test_errand")
		ql.queue_free()
		await process_frame

	sb.disconnect("show_dialogue", handler)
	farmhouse.queue_free()
	await process_frame
	_reset_furniture_state(gd)

	# --- MarigoldForageNode in World (presence, position, once-per-day). ---
	_section = "interactive-furniture-forage"
	var world: Node = (load(WORLD_PATH) as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	var marigold_node: Node = world.get_node_or_null("MarigoldForageNode")
	_check(marigold_node != null, "MarigoldForageNode present in World")
	if marigold_node != null:
		_check((marigold_node as Node2D).position == Vector2(840, 24),
			"MarigoldForageNode at the pre-verified position Vector2(840, 24)")
		_check(String(marigold_node.get("item_id")) == "marigold",
			"MarigoldForageNode item_id == 'marigold'")
		_check(marigold_node.is_in_group("forage_node"),
			"MarigoldForageNode in group 'forage_node'")
		var fscript_path: String = String((marigold_node.get_script() as Script).get_path())
		_check(fscript_path.ends_with("ForageNode.gd"),
			"MarigoldForageNode runs ForageNode.gd (no fork)")
		var captured2: Array = []
		var handler2 := func(speaker: String, text: String) -> void:
			captured2.append([speaker, text])
		sb.connect("show_dialogue", handler2)
		_reset_furniture_state(gd)
		tm.set("day", 20)
		marigold_node.set("_player_in_range", true)
		var ev2 := InputEventAction.new()
		ev2.action = "interact"
		ev2.pressed = true
		marigold_node.call("_unhandled_input", ev2)
		await process_frame
		_check(int((gd.inventory as Dictionary).get("marigold", 0)) == 1,
			"MarigoldForageNode grants 1 marigold when off cooldown")
		_check(int((gd.forage_node_last_day as Dictionary).get("MarigoldForageNode", -1)) == 20,
			"forage records day 20 for MarigoldForageNode")
		marigold_node.call("_unhandled_input", ev2)
		await process_frame
		_check(int((gd.inventory as Dictionary).get("marigold", 0)) == 1,
			"same-day second forage is blocked (still 1 marigold)")
		tm.set("day", 21)
		marigold_node.call("_unhandled_input", ev2)
		await process_frame
		_check(int((gd.inventory as Dictionary).get("marigold", 0)) == 2,
			"next-day forage grants again (2 marigold)")
		marigold_node.set("_player_in_range", false)
		sb.disconnect("show_dialogue", handler2)
	world.queue_free()
	await process_frame
	_reset_furniture_state(gd)
	tm.set("auto_tick", true)

func _initialize() -> void:
	await _run_all()
	print("\n=== INTERACTIVE-FURNITURE TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("INTERACTIVE-FURNITURE GATE FAILED: %d failing checks" % _failed)
	quit(1 if _failed > 0 else 0)
