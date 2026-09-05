extends SceneTree
# TASK-390 gate — three "lives alone, holds a secret" NPCs (Ferryman /
# Fish-Keeper / Scrap Collector) with exclusive wild produce + one-shot
# quest payoffs, plus the Ploen note vignette.
#
# Standalone --script invocation (wired into scripts/ci/run_gate.sh):
#   godot --headless --path . --script res://tests/test_lone_npcs.gd
#
# Follows the tests/test_family_gift_hints.gd convention exactly: real
# World.tscn instantiation, InputEventAction "interact" presses via
# _unhandled_input, and a [speaker, text]-pair dialogue capture filtered
# by speaker name — NEVER a raw captured.size()==1 assertion, since
# ambient World systems (festival triggers etc.) can emit unrelated
# SignalBus.show_dialogue in the same frame (that exact flake was already
# hit and fixed once in this codebase).
#
# Fish-item matching note (delegate's call per spec): every
# data/fish/fish.json sizes.*.item_id starts with "pla_" or "goong_"
# (sized variants like pla_nin_small included), plus the Moon Prawn
# family ("moon_prawn_small/mid/big" — and a bare "moon_prawn" if one
# ever exists). FlavorNPC.is_fish_item() matches those three prefixes,
# so the Fish-Keeper accepts any real catch, not just one size.

var _passed: int = 0
var _failed: int = 0
var _section: String = "lone-npcs"

const FERRYMAN_SECRET_LINE: String = "The Elder's story changes every year because she wants it to. Truth is duller — my grandfather dug the first channel alone, chasing water through one bad drought, and everyone else just kept digging after him. No sluice gate needed fixing for a generation after that. That's all it ever was."
const FISH_KEEPER_RECIPE_LINE: String = "Salt first, always salt first — draws the water out before it draws the rot in. Smoke it slow over banana leaf after that, and it'll outlast the season instead of the week. Nobody around here bothered to ask before you."
const PLOEN_NOTE_LINE: String = "...Where did you find that? I dropped it near the canal weeks ago and never went back for it. Some feelings sound worse written down than they felt at the time — don't you dare repeat a word of it. ...And don't tell anyone I said that either."

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  %s :: %s" % [_section, label])
	else:
		_failed += 1
		print("  FAIL  %s :: %s" % [_section, label])

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
# unrelated ambient dialogue that may have landed in `captured` in the
# same frame. "" if none.
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

func _reset_lone_state(gd: Node) -> void:
	(gd.inventory as Dictionary).clear()
	gd.set("ferryman_secret_shown", false)
	gd.set("fish_keeper_fish_given", 0)
	gd.set("fish_keeper_recipe_unlocked", false)
	(gd.forage_node_last_day as Dictionary).clear()
	gd.set("scrap_collector_note_given", false)
	gd.set("scrap_collector_note_returned", false)

func _run_all() -> void:
	var sb: Node = root.get_node_or_null("SignalBus")
	var gd: Node = root.get_node_or_null("GameData")
	_check(sb != null, "SignalBus autoload present")
	_check(gd != null, "GameData autoload present")
	if sb == null or gd == null:
		return
	var flavor: GDScript = load("res://scripts/narrative/FlavorDialogue.gd") as GDScript
	_check(flavor != null, "FlavorDialogue.gd loads")
	if flavor == null:
		return

	# --- Save/load round-trip first (no world needed). ---
	_section = "lone-npcs-save"
	var sm: Node = load("res://scripts/persistence/SaveManager.gd").new()
	gd.set("ferryman_secret_shown", true)
	gd.set("fish_keeper_fish_given", 2)
	gd.set("fish_keeper_recipe_unlocked", true)
	(gd.forage_node_last_day as Dictionary)["FishKeeperForageNode"] = 7
	(gd.forage_node_last_day as Dictionary)["ScrapCollectorForageNode"] = 9
	gd.set("scrap_collector_note_given", true)
	gd.set("scrap_collector_note_returned", true)
	_check(sm.save_game(), "save_game succeeds with lone-NPC state present")
	_reset_lone_state(gd)
	_check(sm.load_game(), "load_game succeeds")
	_check(bool(gd.get("ferryman_secret_shown")) == true,
		"ferryman_secret_shown round-trips through save/load")
	_check(int(gd.get("fish_keeper_fish_given")) == 2,
		"fish_keeper_fish_given round-trips through save/load")
	_check(bool(gd.get("fish_keeper_recipe_unlocked")) == true,
		"fish_keeper_recipe_unlocked round-trips through save/load")
	_check(int((gd.forage_node_last_day as Dictionary).get("FishKeeperForageNode", -1)) == 7,
		"FishKeeperForageNode forage day round-trips through save/load")
	_check(int((gd.forage_node_last_day as Dictionary).get("ScrapCollectorForageNode", -1)) == 9,
		"ScrapCollectorForageNode forage day round-trips through save/load")
	_check(bool(gd.get("scrap_collector_note_given")) == true,
		"scrap_collector_note_given round-trips through save/load")
	_check(bool(gd.get("scrap_collector_note_returned")) == true,
		"scrap_collector_note_returned round-trips through save/load")
	_reset_lone_state(gd)

	# --- SELL_PRICES catalogue checks (no world needed). ---
	_section = "lone-npcs-prices"
	# NOTE: SELL_PRICES is read through the live `gd` autoload instance,
	# never the bare `GameData` global — no other test references that
	# global directly, and doing so forces a dependency compile that
	# breaks under `godot --headless --script`.
	_check(int(gd.SELL_PRICES.get("wild_turmeric", 0)) == 6,
		"wild_turmeric sells for 6")
	_check(int(gd.SELL_PRICES.get("preserved_fish", 0)) == 18,
		"preserved_fish sells for 18 (premium vs raw fish)")
	_check(int(gd.SELL_PRICES.get("salvaged_scrap", 0)) == 3,
		"salvaged_scrap sells for 3")
	_check(not gd.SELL_PRICES.has("ploen_note"),
		"ploen_note is NOT sellable (plain quest token)")

	# --- World-based tests. ---
	_section = "lone-npcs"
	var world: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	var tm: Node = sb.get("time_manager")
	_check(tm != null, "SignalBus.time_manager present for day control")
	if tm == null:
		world.queue_free()
		return

	var captured: Array = []
	var handler := func(speaker: String, text: String) -> void:
		captured.append([speaker, text])
	sb.connect("show_dialogue", handler)

	var ferryman: Node = world.get_node_or_null("FerrymanNPC")
	var keeper: Node = world.get_node_or_null("FishKeeperNPC")
	var scrap: Node = world.get_node_or_null("ScrapCollectorNPC")
	var ploen: Node = world.get_node_or_null("PloenNPC")
	_check(ferryman != null, "FerrymanNPC present in World")
	_check(keeper != null, "FishKeeperNPC present in World")
	_check(scrap != null, "ScrapCollectorNPC present in World")
	_check(ploen != null, "PloenNPC present in World")
	if ferryman == null or keeper == null or scrap == null or ploen == null:
		sb.disconnect("show_dialogue", handler)
		world.queue_free()
		return
	_check(String(ferryman.get("npc_id")) == "ferryman", "FerrymanNPC npc_id == 'ferryman'")
	_check(String(keeper.get("npc_id")) == "fish_keeper", "FishKeeperNPC npc_id == 'fish_keeper'")
	_check(String(scrap.get("npc_id")) == "scrap_collector", "ScrapCollectorNPC npc_id == 'scrap_collector'")
	_check((ferryman as Node2D).position == Vector2(600, 576),
		"FerrymanNPC at locked position Vector2(600, 576)")
	_check((keeper as Node2D).position == Vector2(744, 432),
		"FishKeeperNPC at locked position Vector2(744, 432)")
	# TASK-390 fix (manual playtest, 2026-09-05): moved from (936, 600) --
	# that position sat inside EastEdge's scene-transition trigger
	# (RectangleShape2D 48x864 at x=940, spanning x=916-964 across nearly
	# the full map height), so a real player walking up to interact would
	# get warped to CoastalArea.tscn before ever reaching him. Direct
	# _player_in_range assertions like this file's never exercised the
	# EastEdge Area2D, so the automated gate never caught it.
	_check((scrap as Node2D).position == Vector2(850, 528),
		"ScrapCollectorNPC at locked position Vector2(850, 528)")
	_check(ferryman.is_in_group("flavor_npc"), "FerrymanNPC in group 'flavor_npc'")
	_check(keeper.is_in_group("flavor_npc"), "FishKeeperNPC in group 'flavor_npc'")
	_check(scrap.is_in_group("flavor_npc"), "ScrapCollectorNPC in group 'flavor_npc'")
	# All three share the SAME FlavorNPC.gd script (no fork).
	var fscript: String = String((ferryman.get_script() as Script).get_path())
	_check(fscript.ends_with("FlavorNPC.gd"), "FerrymanNPC runs FlavorNPC.gd")
	_check(String((keeper.get_script() as Script).get_path()) == fscript,
		"FishKeeperNPC runs the same FlavorNPC.gd (no fork)")
	_check(String((scrap.get_script() as Script).get_path()) == fscript,
		"ScrapCollectorNPC runs the same FlavorNPC.gd (no fork)")

	var keeper_node: Node = world.get_node_or_null("FishKeeperForageNode")
	var scrap_node: Node = world.get_node_or_null("ScrapCollectorForageNode")
	_check(keeper_node != null, "FishKeeperForageNode present in World")
	_check(scrap_node != null, "ScrapCollectorForageNode present in World")
	if keeper_node != null:
		_check(String(keeper_node.get("item_id")) == "wild_turmeric",
			"FishKeeperForageNode item_id == 'wild_turmeric'")
	if scrap_node != null:
		_check(String(scrap_node.get("item_id")) == "salvaged_scrap",
			"ScrapCollectorForageNode item_id == 'salvaged_scrap'")

	# --- Normal 3-line cycles with empty hands (no one-shot armed). ---
	_section = "lone-npcs-cycles"
	_reset_lone_state(gd)
	tm.set("day", 5)
	var ferryman_name: String = String(ferryman.get("display_name"))
	var keeper_name: String = String(keeper.get("display_name"))
	var scrap_name: String = String(scrap.get("display_name"))
	var ploen_name: String = String(ploen.get("display_name"))
	var ferryman_pool: Array = flavor.FLAVOR_LINES.get("ferryman", [])
	var keeper_pool: Array = flavor.FLAVOR_LINES.get("fish_keeper", [])
	var scrap_pool: Array = flavor.FLAVOR_LINES.get("scrap_collector", [])
	var ploen_pool: Array = flavor.FLAVOR_LINES.get("ploen", [])
	_check(ferryman_pool.size() == 3, "FLAVOR_LINES['ferryman'] is a 3-element Array")
	_check(keeper_pool.size() == 3, "FLAVOR_LINES['fish_keeper'] is a 3-element Array")
	_check(scrap_pool.size() == 3, "FLAVOR_LINES['scrap_collector'] is a 3-element Array")
	_check(ploen_pool.size() == 3, "Ploen's FLAVOR_LINES entry still exactly 3 lines (untouched)")
	ferryman.set("_player_in_range", true)
	keeper.set("_player_in_range", true)
	captured.clear()
	await _press(ferryman)
	_check(_count_for(captured, ferryman_name) == 1 and _line_for(captured, ferryman_name) == String(ferryman_pool[0]),
		"Ferryman with empty hands cycles normally (pool[0])")
	captured.clear()
	await _press(keeper)
	_check(_count_for(captured, keeper_name) == 1 and _line_for(captured, keeper_name) == String(keeper_pool[0]),
		"Fish-Keeper with empty hands cycles normally (pool[0])")
	ferryman.set("_player_in_range", false)
	keeper.set("_player_in_range", false)

	# Ploen's NORMAL cycle still works before ever getting the note.
	ploen.set("_player_in_range", true)
	for i in range(3):
		captured.clear()
		await _press(ploen)
		_check(_count_for(captured, ploen_name) == 1 and _line_for(captured, ploen_name) == String(ploen_pool[i]),
			"Ploen pre-note talk %d matches pool[%d]" % [i + 1, i])
	ploen.set("_player_in_range", false)

	# --- Ferryman's reveal: only with a moon prawn, only once. ---
	_section = "lone-npcs-ferryman"
	_reset_lone_state(gd)
	ferryman.set("_line_index", 0) # node cycle state persists across sections; reset for determinism
	ferryman.set("_player_in_range", true)
	captured.clear()
	await _press(ferryman)
	_check(_line_for(captured, ferryman_name) == String(ferryman_pool[0]),
		"Ferryman without a moon prawn shows normal flavor, not the secret")
	gd.add_item("moon_prawn_small", 1)
	captured.clear()
	await _press(ferryman)
	_check(_count_for(captured, ferryman_name) == 1 and _line_for(captured, ferryman_name) == FERRYMAN_SECRET_LINE,
		"Ferryman with a moon prawn fires the exact secret line")
	_check(bool(gd.get("ferryman_secret_shown")) == true,
		"ferryman_secret_shown set after the reveal")
	_check(not (gd.inventory as Dictionary).has("moon_prawn_small"),
		"the moon prawn is consumed by the reveal")
	gd.add_item("moon_prawn_mid", 1)
	captured.clear()
	await _press(ferryman)
	_check(_line_for(captured, ferryman_name) == String(ferryman_pool[1]),
		"Ferryman reveal fires only once (second prawn -> normal cycle, pool[1])")
	_check(int((gd.inventory as Dictionary).get("moon_prawn_mid", 0)) == 1,
		"second moon prawn is NOT consumed after the one-shot")
	ferryman.set("_player_in_range", false)

	# --- Fish-Keeper: unlocks only at 3 fish given, only once. ---
	_section = "lone-npcs-keeper"
	_reset_lone_state(gd)
	keeper.set("_line_index", 0) # node cycle state persists across sections; reset for determinism
	keeper.set("_player_in_range", true)
	gd.add_item("pla_nin_small", 2)
	gd.add_item("goong_mae_nam_mid", 1)
	captured.clear()
	await _press(keeper)
	_check(int(gd.get("fish_keeper_fish_given")) == 1 and not bool(gd.get("fish_keeper_recipe_unlocked")),
		"first fish: counter 1, still locked")
	_check(_line_for(captured, keeper_name).contains("few more"),
		"first fish shows the in-progress line, not the recipe")
	captured.clear()
	await _press(keeper)
	_check(int(gd.get("fish_keeper_fish_given")) == 2 and not bool(gd.get("fish_keeper_recipe_unlocked")),
		"second fish: counter 2, still locked")
	captured.clear()
	await _press(keeper)
	_check(_count_for(captured, keeper_name) == 1 and _line_for(captured, keeper_name) == FISH_KEEPER_RECIPE_LINE,
		"third fish fires the exact recipe line")
	_check(bool(gd.get("fish_keeper_recipe_unlocked")) == true,
		"fish_keeper_recipe_unlocked set at 3 fish")
	gd.add_item("pla_duk_small", 1)
	captured.clear()
	await _press(keeper)
	_check(int((gd.inventory as Dictionary).get("pla_duk_small", 0)) == 1,
		"fish given after unlock is NOT consumed")
	_check(_line_for(captured, keeper_name) == String(keeper_pool[0]),
		"post-unlock talks return to the normal flavor cycle (pool[0])")
	keeper.set("_player_in_range", false)

	# --- ForageNode: grants once per day, blocked same-day. ---
	_section = "lone-npcs-forage"
	_reset_lone_state(gd)
	tm.set("day", 10)
	keeper_node.set("_player_in_range", true)
	captured.clear()
	await _press(keeper_node)
	_check(int((gd.inventory as Dictionary).get("wild_turmeric", 0)) == 1,
		"ForageNode grants 1 wild_turmeric when off cooldown")
	_check(int((gd.forage_node_last_day as Dictionary).get("FishKeeperForageNode", -1)) == 10,
		"forage records day 10 for FishKeeperForageNode")
	captured.clear()
	await _press(keeper_node)
	_check(int((gd.inventory as Dictionary).get("wild_turmeric", 0)) == 1,
		"same-day second forage is blocked (still 1 turmeric)")
	tm.set("day", 11)
	captured.clear()
	await _press(keeper_node)
	_check(int((gd.inventory as Dictionary).get("wild_turmeric", 0)) == 2,
		"next-day forage grants again (2 turmeric)")
	keeper_node.set("_player_in_range", false)
	# Second node instance tracks its own cooldown independently.
	scrap_node.set("_player_in_range", true)
	captured.clear()
	await _press(scrap_node)
	_check(int((gd.inventory as Dictionary).get("salvaged_scrap", 0)) == 1,
		"ScrapCollectorForageNode grants 1 salvaged_scrap independently")
	scrap_node.set("_player_in_range", false)

	# --- Scrap Collector note -> Ploen one-shot -> Ploen cycle resumes. ---
	_section = "lone-npcs-ploen"
	_reset_lone_state(gd)
	scrap.set("_line_index", 0) # node cycle state persists across sections; reset for determinism
	ploen.set("_line_index", 0)
	scrap.set("_player_in_range", true)
	ploen.set("_player_in_range", true)
	# Ploen WITHOUT the note still cycles normally (fresh state).
	captured.clear()
	await _press(ploen)
	_check(_line_for(captured, ploen_name) == String(ploen_pool[0]),
		"Ploen without the note shows her normal cycle (pool[0])")
	captured.clear()
	await _press(scrap)
	_check(int((gd.inventory as Dictionary).get("ploen_note", 0)) == 1,
		"first Scrap Collector talk grants 1 ploen_note")
	_check(bool(gd.get("scrap_collector_note_given")) == true,
		"scrap_collector_note_given set after first talk")
	captured.clear()
	await _press(ploen)
	_check(_count_for(captured, ploen_name) == 1 and _line_for(captured, ploen_name) == PLOEN_NOTE_LINE,
		"Ploen with the note fires her exact one-shot line")
	_check(not (gd.inventory as Dictionary).has("ploen_note"),
		"the ploen_note is consumed by Ploen's one-shot")
	_check(bool(gd.get("scrap_collector_note_returned")) == true,
		"scrap_collector_note_returned set after Ploen's one-shot")
	captured.clear()
	await _press(ploen)
	_check(_line_for(captured, ploen_name) == String(ploen_pool[1]),
		"Ploen's normal cycle resumes after the one-shot (pool[1], index unadvanced)")
	captured.clear()
	await _press(scrap)
	_check(int((gd.inventory as Dictionary).get("ploen_note", 0)) == 0,
		"Scrap Collector gives the note only once (no second note)")
	scrap.set("_player_in_range", false)
	ploen.set("_player_in_range", false)

	# --- moon_prawn is dock-exclusive in the fishing roster. ---
	_section = "lone-npcs-exclusive-fish"
	var fish_script: GDScript = load("res://scripts/interactables/FishingSpot.gd") as GDScript
	_check(fish_script != null, "FishingSpot.gd loads")
	if fish_script != null:
		gd.set("fishing_skill", 4)
		var away: Node2D = (fish_script as GDScript).new() as Node2D
		away.name = "AwaySpot"
		away.position = Vector2(11 * 48 + 24, 13 * 48 - 48) # canal bank, cell (11, 12)
		root.add_child(away)
		await process_frame
		await process_frame
		var away_ids: Array = []
		for f: Dictionary in away.call("eligible_fish"):
			away_ids.append(String(f.get("id", "")))
		_check(not away_ids.has("moon_prawn"),
			"moon_prawn NOT eligible at the canal-bank spot (cell 11,12)")
		_check(away_ids.has("pla_nin"),
			"non-exclusive fish (pla_nin) still eligible away from the dock")
		var dock: Node2D = (fish_script as GDScript).new() as Node2D
		dock.name = "DockSpot"
		dock.set("spot_cell", Vector2i(13, 13))
		dock.position = Vector2(13 * 48 + 24, 13 * 48 + 24)
		root.add_child(dock)
		await process_frame
		await process_frame
		var dock_ids: Array = []
		for f: Dictionary in dock.call("eligible_fish"):
			dock_ids.append(String(f.get("id", "")))
		_check(dock_ids.has("moon_prawn"),
			"moon_prawn IS eligible at the dock spot (cell 13,13)")
		_check(dock_ids.has("pla_nin"),
			"non-exclusive fish unaffected at the dock spot too")
		away.queue_free()
		dock.queue_free()
		await process_frame
		gd.set("fishing_skill", 1)

	sb.disconnect("show_dialogue", handler)
	world.queue_free()
	await process_frame
	_reset_lone_state(gd)

func _initialize() -> void:
	await _run_all()
	print("\n=== LONE-NPCS TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("LONE-NPCS GATE FAILED: %d failing checks" % _failed)
	quit(1 if _failed > 0 else 0)
