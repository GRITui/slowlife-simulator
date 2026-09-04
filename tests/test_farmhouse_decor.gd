extends SceneTree
# TASK-360 farmhouse decor anchor-slots test. Covers the full
# end-to-end contract of the new decor system without needing a
# player to drive the interactable:
#   1. decor_choice("shrine") defaults to "basic" when unset.
#   2. set_decor_choice() refuses an unowned style (the required
#      item is the gate, not the catalogue itself).
#   3. set_decor_choice() accepts an owned style.
#   4. The chosen style survives a SaveManager.save_game() ->
#      wipe-state -> load_game() round trip (decor_choices is in
#      the persisted payload, defaulting to {} for old data).
#   5. The style picker interactable only cycles through owned
#      styles — the player can't reach "ornate" until they own the
#      blueprint.
#
# Follows the existing tests' `_check(cond, label)` convention (see
# tests/test_farmhouse_content.gd, tests/test_carpenter_upgrade.gd)
# and reads the real autoload GameData, not a mock — same harness the
# other tests use.

const FARMHOUSE_PATH: String = "res://scenes/interiors/FarmHouse.tscn"
const PICKER_PATH: String = "res://scenes/interactables/FarmHouseShrineStylePicker.tscn"
const SaveManagerScript: GDScript = preload("res://scripts/persistence/SaveManager.gd")

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  farmhouse-decor :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  farmhouse-decor :: %s" % label)

func _initialize() -> void:
	await _run_all()
	print("\n=== FARMHOUSE-DECOR TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("FARMHOUSE-DECOR GATE FAILED: %d failing checks" % _failed)
	quit(1 if _failed > 0 else 0)
func _run_all() -> void:
	var gd_node: Node = root.get_node_or_null("GameData")
	var sb_node: Node = root.get_node_or_null("SignalBus")
	_check(gd_node != null, "GameData autoload present")
	_check(sb_node != null, "SignalBus autoload present")
	if gd_node == null or sb_node == null:
		return
	await process_frame
	# Wipe decor state + inventory up front so prior test runs don't leak.
	gd_node.decor_choices.clear()
	gd_node.inventory.clear()
	gd_node.silver = 0

	# (1) default is "basic" when unset
	_check(String(gd_node.decor_choice("shrine")) == "basic",
		"decor_choice('shrine') defaults to 'basic' when unset (got '%s')"
			% String(gd_node.decor_choice("shrine")))
	_check(gd_node.decor_choices.is_empty(),
		"reading decor_choice() does NOT mutate decor_choices")

	# (2) reject unowned "ornate"
	var ok_unowned: bool = gd_node.set_decor_choice("shrine", "ornate")
	_check(ok_unowned == false,
		"set_decor_choice('shrine', 'ornate') REJECTS when blueprint unowned")
	_check(String(gd_node.decor_choice("shrine")) == "basic",
		"rejected set_decor_choice leaves default style intact (still 'basic')")
	_check(not gd_node.decor_choices.has("shrine"),
		"rejected set_decor_choice does NOT write to decor_choices")

	# reject unknown slot/style for negative-path coverage
	_check(gd_node.set_decor_choice("does_not_exist", "anything") == false,
		"set_decor_choice rejects an unknown slot")
	_check(gd_node.set_decor_choice("shrine", "does_not_exist") == false,
		"set_decor_choice rejects an unknown style for a known slot")

	# (3) accept "ornate" once blueprint is owned
	gd_node.add_item("ornate_shrine_blueprint", 1)
	var ok_owned: bool = gd_node.set_decor_choice("shrine", "ornate")
	_check(ok_owned == true,
		"set_decor_choice('shrine', 'ornate') ACCEPTS when blueprint owned")
	_check(String(gd_node.decor_choice("shrine")) == "ornate",
		"decor_choice('shrine') now returns 'ornate' (got '%s')"
			% String(gd_node.decor_choice("shrine")))
	_check(gd_node.decor_choices.get("shrine") == "ornate",
		"decor_choices['shrine'] == 'ornate' after accepted set")

	# (4) save / wipe / load round-trip
	var sm: Node = SaveManagerScript.new()
	# Seed a non-default choice so the round-trip has something visible to
	# restore (an unset "shrine" key would also round-trip, but this also
	# exercises the "key was actually written" path).
	gd_node.set_decor_choice("shrine", "ornate")
	gd_node.inventory["rice_grain"] = 4
	# Snapshot decor_choices before save.
	var saved_choice: String = String(gd_node.decor_choices.get("shrine", ""))
	_check(saved_choice == "ornate",
		"pre-save: decor_choices['shrine'] == 'ornate' (got '%s')" % saved_choice)
	var saved: bool = sm.save_game()
	_check(saved, "SaveManager.save_game() writes user://savegame.json")

	# Confirm the on-disk payload actually contains decor_choices — this
	# is the cheapest way to catch a SaveManager typo that silently drops
	# the field.
	var f: FileAccess = FileAccess.open("user://savegame.json", FileAccess.READ)
	var raw: String = f.get_as_text() if f else ""
	var parsed: Variant = JSON.parse_string(raw)
	_check(parsed is Dictionary,
		"saved JSON parses to a Dictionary")
	if parsed is Dictionary:
		var d: Dictionary = parsed as Dictionary
		_check(d.has("decor_choices"),
			"saved JSON carries a 'decor_choices' key")
		var dc: Dictionary = d.get("decor_choices", {}) as Dictionary
		_check(String(dc.get("shrine", "")) == "ornate",
			"saved JSON: decor_choices.shrine == 'ornate' (got '%s')"
				% String(dc.get("shrine", "")))

	# Wipe and reload.
	gd_node.decor_choices.clear()
	gd_node.inventory.clear()
	_check(gd_node.decor_choices.is_empty(),
		"post-wipe: decor_choices is empty (sanity)")
	var loaded: bool = sm.load_game()
	_check(loaded, "SaveManager.load_game() reads the saved file back")
	await process_frame
	var restored_choice: String = String(gd_node.decor_choice("shrine"))
	_check(restored_choice == "ornate",
		"round-trip: decor_choice('shrine') == 'ornate' after load (got '%s')"
			% restored_choice)
	_check(gd_node.decor_choices.get("shrine") == "ornate",
		"round-trip: decor_choices['shrine'] == 'ornate' after load")
	sm.queue_free()

	# (5) the picker only cycles through owned styles
	# Reset to a clean state: own ONLY the basic-style "blueprint" (which
	# is the empty string — basic is always selectable) and confirm
	# owned_decor_styles("shrine") reports exactly ["basic"].
	gd_node.decor_choices.clear()
	gd_node.inventory.clear()
	# basic doesn't require anything, so don't add anything to inventory.
	var owned_basic_only: Array[String] = gd_node.owned_decor_styles("shrine")
	_check(owned_basic_only.size() == 1 and owned_basic_only[0] == "basic",
		"owned_decor_styles('shrine') with nothing = ['basic'] (got %s)"
			% str(owned_basic_only))

	# Add the ornate blueprint, expect both.
	gd_node.add_item("ornate_shrine_blueprint", 1)
	var owned_both: Array[String] = gd_node.owned_decor_styles("shrine")
	_check(owned_both.size() == 2 and owned_both.has("basic") and owned_both.has("ornate"),
		"owned_decor_styles('shrine') with blueprint = both styles (got %s)"
			% str(owned_both))

	# Instantiate the picker against the same GameData and drive its
	# cycle method directly (mirrors how test_farmhouse_content.gd
	# drives bed._sleep and shrine._read_forecast). The picker's
	# _cycle_style() advances through owned_decor_styles() and emits
	# decor_style_changed.
	var picker_scene: PackedScene = load(PICKER_PATH) as PackedScene
	_check(picker_scene != null,
		"FarmHouseShrineStylePicker.tscn loads as a PackedScene")
	if picker_scene == null:
		return
	var picker: Node = picker_scene.instantiate()
	root.add_child(picker)
	await process_frame
	# Snap the index back to -1 (one step before the first item) so we
	# can confirm the first cycle lands on the FIRST owned style
	# deterministically.
	picker._cycle_index = -1
	# Capture the decor_style_changed signal payload via a one-shot
	# handler — GDScript lambdas capture by value for primitives, so
	# route the String through a one-element Array box.
	var seen: Array = ["", ""]
	var handler := func(slot: String, style: String) -> void:
		seen[0] = slot
		seen[1] = style
	sb_node.decor_style_changed.connect(handler, CONNECT_ONE_SHOT)
	picker._cycle_style()
	await process_frame
	_check(seen[0] == "shrine",
		"picker._cycle_style() emits decor_style_changed with slot='shrine' (got '%s')"
			% seen[0])
	# The picker advances from the CURRENT choice (not from index 0), so
	# the first press moves the picker to the NEXT owned style. The
	# current choice was set to "basic" by decor_choices.clear() above;
	# with both styles owned, next is "ornate".
	_check(seen[1] == "ornate",
		"first cycle advances FROM current 'basic' -> next 'ornate' (got '%s')"
			% seen[1])
	_check(String(gd_node.decor_choice("shrine")) == "ornate",
		"after first cycle, decor_choice('shrine') == 'ornate'")

	# Second cycle: should wrap back to "basic" (the next owned style).
	var seen2: Array = ["", ""]
	var handler2 := func(slot: String, style: String) -> void:
		seen2[0] = slot
		seen2[1] = style
	sb_node.decor_style_changed.connect(handler2, CONNECT_ONE_SHOT)
	picker._cycle_style()
	await process_frame
	_check(seen2[1] == "basic",
		"second cycle wraps back to 'basic' (got '%s')" % seen2[1])
	_check(String(gd_node.decor_choice("shrine")) == "basic",
		"after second cycle, decor_choice('shrine') == 'basic'")

	# Now simulate spending the blueprint — confirm the picker's cycle
	# list shrinks back to ["basic"] and the next cycle lands back on
	# "basic" (not on a now-unowned "ornate").
	gd_node.remove_item("ornate_shrine_blueprint", 1)
	var owned_after_spend: Array[String] = gd_node.owned_decor_styles("shrine")
	_check(owned_after_spend.size() == 1 and owned_after_spend[0] == "basic",
		"after blueprint spent: owned_decor_styles = ['basic'] (got %s)"
			% str(owned_after_spend))
	var seen3: Array = ["", ""]
	var handler3 := func(slot: String, style: String) -> void:
		seen3[0] = slot
		seen3[1] = style
	sb_node.decor_style_changed.connect(handler3, CONNECT_ONE_SHOT)
	picker._cycle_style()
	await process_frame
	# "ornate" was the persisted choice. The picker skips unowned entries
	# and lands on "basic"; set_decor_choice accepts because "basic"
	# requires no item.
	_check(seen3[1] == "basic",
		"picker skips unowned 'ornate', lands on 'basic' (got '%s')" % seen3[1])

	# Also drive the picker the way a player would, via _unhandled_input
	# on the "interact" action — this is the same path the real game
	# takes and catches mistakes where, say, the prompt shows but the action
	# isn't actually wired. Use an InputEventAction + pressed=true.
	# Force the choice back to "basic" so the press advances to "ornate".
	gd_node.set_decor_choice("shrine", "basic")
	gd_node.add_item("ornate_shrine_blueprint", 1)
	picker._cycle_index = -1
	picker._player_in_range = true
	var ev: InputEvent = InputEventAction.new()
	(ev as InputEventAction).action = "interact"
	(ev as InputEventAction).pressed = true
	var seen4: Array = ["", ""]
	var handler4 := func(slot: String, style: String) -> void:
		seen4[0] = slot
		seen4[1] = style
	sb_node.decor_style_changed.connect(handler4, CONNECT_ONE_SHOT)
	picker._unhandled_input(ev)
	await process_frame
	_check(seen4[1] == "ornate",
		"full _unhandled_input path: 'interact' press advances current 'basic' -> 'ornate' (got '%s')"
			% seen4[1])

	# Confirm the picker does NOTHING when the player is out of range.
	var gd_before: String = String(gd_node.decor_choice("shrine"))
	picker._player_in_range = false
	var ev2: InputEvent = InputEventAction.new()
	(ev2 as InputEventAction).action = "interact"
	(ev2 as InputEventAction).pressed = true
	picker._unhandled_input(ev2)
	await process_frame
	_check(String(gd_node.decor_choice("shrine")) == gd_before,
		"picker ignores 'interact' when player is out of range")
# Visual swap hook: when the picker fires decor_style_changed, the
	# FarmHouse.gd _on_decor_style_changed listener should swap the
	# Shrine's Sprite2D texture to the new style. Build a FarmHouse
	# instance and verify the texture actually changes.
	var farm_scene: PackedScene = load(FARMHOUSE_PATH) as PackedScene
	_check(farm_scene != null, "FarmHouse.tscn loads as a PackedScene")
	if farm_scene != null:
		var farm_node: Node = farm_scene.instantiate()
		root.add_child(farm_node)
		await process_frame
		# FarmHouse._build_render already called _apply_shrine_style in
		# _ready. Force-set the choice to "ornate" and verify the
		# initial texture swap worked.
		gd_node.decor_choices.clear()
		gd_node.set_decor_choice("shrine", "ornate")
		await process_frame
		var shrine: Node = farm_node.get_node_or_null("Shrine")
		var shrine_sprite: Sprite2D = shrine.get_node_or_null("Sprite2D") as Sprite2D if shrine != null else null
		if shrine_sprite != null:
			var tex_path_before: String = shrine_sprite.texture.resource_path if shrine_sprite.texture != null else ""
			_check(tex_path_before == "res://assets/environment/mohom_cloth.png",
				"after setting 'ornate': Shrine Sprite2D uses mohom_cloth (got '%s')" % tex_path_before)
			# Now flip back to "basic" and fire the signal — the live
			# listener should re-skin the sprite immediately.
			gd_node.set_decor_choice("shrine", "basic")
			sb_node.decor_style_changed.emit("shrine", "basic")
			await process_frame
			var tex_path_after: String = shrine_sprite.texture.resource_path if shrine_sprite.texture != null else ""
			_check(tex_path_after == "res://assets/environment/structure_wall_front.png",
				"on decor_style_changed: Shrine Sprite2D swaps back to structure_wall_front (got '%s')" % tex_path_after)
		farm_node.queue_free()

	picker.queue_free()
	# Leave GameData in a clean state for any test that runs after us.
	gd_node.decor_choices.clear()
	gd_node.inventory.clear()