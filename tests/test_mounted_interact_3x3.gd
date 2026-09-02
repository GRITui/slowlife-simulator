extends SceneTree
# TASK-334 mounted interact 3x3 gate — mixed empty/growing/harvest-ready
# patch must plant/water/harvest in one call and emit one summary dialogue
# line that reports only non-zero categories.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  mounted-interact :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  mounted-interact :: %s" % label)

func _on_dialogue(speaker: String, text: String) -> void:
	_last_speaker = speaker
	_last_text = text

var _last_speaker: String = ""
var _last_text: String = ""

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var player: Node = main.get_node_or_null("Player")
	var gm: Node = main.get_node_or_null("GridManager")
	_check(player != null and gm != null, "Player + GridManager available")
	if player == null or gm == null:
		main.queue_free()
		await process_frame
		quit(1)
		return
	# Stamina + inventory reset for deterministic counts.
	gd.current_stamina = 100.0
	gd.inventory.clear()
	# Hold a known seed so _find_crop_for_held_seed() returns a deterministic crop.
	gd.add_item("seed_sticky_rice", 20)
	# Seed the lookup cache so we don't depend on directory scan order.
	player._seed_lookup.clear()
	var crop: Resource = player._find_crop_for_held_seed()
	_check(crop != null and String(crop.id) == "sticky_rice",
		"held seed_sticky_rice resolves (got '%s')" % (String(crop.id) if crop else "null"))
	# Center the 3x3 on (5, 5) — well inside the 20x16 paddy, away from the
	# maze inset at (14, 10).
	# Layout: 4 cells empty (3 corners + the center (5,5)), 3 growing
	# (top-mid, left-mid, bottom-right), 2 harvest-ready (right-mid,
	# bottom-left). The implementation will plant the 4 empty cells, water
	# the 3 growing ones, and harvest the 2 ready ones in one call.
	var center: Vector2i = Vector2i(5, 5)
	var sticky: Resource = load("res://data/crops/sticky_rice.tres")
	var ready: Resource = load("res://data/crops/jasmine_rice.tres")
	var growing_cells: Array[Vector2i] = [
		Vector2i(5, 4), Vector2i(4, 5), Vector2i(6, 6)
	]
	var ready_cells: Array[Vector2i] = [
		Vector2i(6, 5), Vector2i(5, 6)
	]
	var empty_cells: Array[Vector2i] = [
		Vector2i(4, 4), Vector2i(6, 4), Vector2i(4, 6), Vector2i(5, 5)
	]
	var seeds_before: int = int(gd.inventory.get("seed_sticky_rice", 0))
	# Plant 3 growing at stage 0 (1 minute in stage; not watered).
	for c in growing_cells:
		var ok_g: bool = gm.plant(c, sticky)
		_check(ok_g, "growing cell (%d,%d) pre-plant" % [c.x, c.y])
		var ps_g: Object = gm.get_plot(c)
		ps_g.stage = 0
		ps_g.minutes_in_stage = 0
		ps_g.watered = false
	# Plant 2 harvest-ready at stage total_stages-1 (sticky_rice: 3).
	for c in ready_cells:
		var ok_r: bool = gm.plant(c, ready)
		_check(ok_r, "ready cell (%d,%d) pre-plant" % [c.x, c.y])
		var ps_r: Object = gm.get_plot(c)
		ps_r.stage = ready.total_stages - 1
		ps_r.minutes_in_stage = 0
	# Stamina check: each plant costs 5 (post-hoe-discount ~4), each harvest 3,
	# no water cost. 5 plants + 2 harvests ~= 26 stamina; ensure fresh.
	gd.current_stamina = 100.0
	# Snapshot inventory items used in yield check.
	var rice_before: int = int(gd.inventory.get("rice_grain", 0))
	var sticky_before: int = int(gd.inventory.get("sticky_rice", 0))
	# Capture the next show_dialogue payload (mount interact emits one line).
	var sb: Node = root.get_node("SignalBus")
	sb.show_dialogue.connect(_on_dialogue)
	player._mounted_interact_3x3(gm, center)
	if sb.show_dialogue.is_connected(_on_dialogue):
		sb.show_dialogue.disconnect(_on_dialogue)
	# Per-cell outcome assertions.
	# 1) The 4 empty cells (3 corners + center) should now hold plots.
	for c in empty_cells:
		var p: Object = gm.get_plot(c)
		_check(p != null, "empty cell (%d,%d) got planted" % [c.x, c.y])
		if p != null:
			_check(String(p.crop.id) == "sticky_rice",
				"empty cell (%d,%d) has sticky_rice (got '%s')" % [c.x, c.y, String(p.crop.id)])
	# 2) Growing cells should now be watered (watered flag set).
	for c in growing_cells:
		var p2: Object = gm.get_plot(c)
		_check(p2 != null, "growing cell (%d,%d) still has a plot" % [c.x, c.y])
		if p2 != null:
			_check(bool(p2.watered), "growing cell (%d,%d) is watered" % [c.x, c.y])
	# 3) Harvest-ready cells should be cleared (crop with regrow_after_harvest
	# false, so the plot is removed). jasmine_rice has regrow_after_harvest = false.
	for c in ready_cells:
		var p3: Object = gm.get_plot(c)
		_check(p3 == null, "ready cell (%d,%d) cleared by harvest" % [c.x, c.y])
	# 4) Inventory: rice_grain went up by >=1 (from harvesting the two ready cells).
	var rice_after: int = int(gd.inventory.get("rice_grain", 0))
	_check(rice_after > rice_before,
		"harvest added rice_grain to inventory (before=%d after=%d)" % [rice_before, rice_after])
	# 5) Seed consumption: 3 growing pre-plants (sticky) + 4 mount plants
	# (sticky) consume 7 seeds; the 2 ready pre-plants are jasmine, which the
	# GridManager allows without a seed when seed_rice is absent.
	var seeds_after: int = int(gd.inventory.get("seed_sticky_rice", 0))
	var expected_seeds: int = seeds_before - (growing_cells.size() + empty_cells.size())
	_check(seeds_after == expected_seeds,
		"seeds consumed == planted cells (before=%d after=%d expected=%d)" % [seeds_before, seeds_after, expected_seeds])
	# 6) Summary dialogue: must mention each non-zero category and omit zero
	# categories. Expected: 4 planted (empty), 2 harvested (ready), 3 watered (growing).
	_check(_last_speaker == "Farmer", "dialogue speaker is 'Farmer' (got '%s')" % _last_speaker)
	_check(_last_text.contains("4 planted"),
		"dialogue contains '4 planted' (got '%s')" % _last_text)
	_check(_last_text.contains("2 harvested"),
		"dialogue contains '2 harvested' (got '%s')" % _last_text)
	_check(_last_text.contains("3 watered"),
		"dialogue contains '3 watered' (got '%s')" % _last_text)
	_check(_last_text.begins_with("Buffalo plow:"),
		"dialogue starts with 'Buffalo plow:' (got '%s')" % _last_text)
	# Verify the summary line has no "0 X" noise for any category.
	_check(not _last_text.contains("0 planted"),
		"dialogue omits '0 planted' (got '%s')" % _last_text)
	_check(not _last_text.contains("0 harvested"),
		"dialogue omits '0 harvested' (got '%s')" % _last_text)
	_check(not _last_text.contains("0 watered"),
		"dialogue omits '0 watered' (got '%s')" % _last_text)
	# 6b) Regression: an entirely-empty 3x3 patch must still plant all 9
	# cells and emit a "9 planted" summary with no other categories.
	# (This mirrors the test_riding.gd scenario against the renamed fn.)
	gd.current_stamina = 100.0
	gd.inventory.clear()
	gd.add_item("seed_sticky_rice", 20)
	player._seed_lookup.clear()
	# Use a center well away from the previous test's 3x3 (5,5) and from
	# the unmounted test's 3x3 (8,8) below — pick (12, 12) which is inside
	# the 20x16 paddy (the maze inset starts at (14, 10)).
	var empty_center: Vector2i = Vector2i(12, 12)
	for dxe in [-1, 0, 1]:
		for dye in [-1, 0, 1]:
			_check(gm.get_plot(empty_center + Vector2i(dxe, dye)) == null,
				"all-empty pre: cell (%d,%d) empty" % [empty_center.x + dxe, empty_center.y + dye])
	_last_text = ""
	# Reconnect the dialogue listener for this second scenario.
	sb.show_dialogue.connect(_on_dialogue)
	player._mounted_interact_3x3(gm, empty_center)
	if sb.show_dialogue.is_connected(_on_dialogue):
		sb.show_dialogue.disconnect(_on_dialogue)
	var e_planted: int = 0
	for dxe in [-1, 0, 1]:
		for dye in [-1, 0, 1]:
			if gm.get_plot(empty_center + Vector2i(dxe, dye)) != null:
				e_planted += 1
	_check(e_planted == 9, "all-empty 3x3 plants all 9 cells (got %d)" % e_planted)
	_check(_last_text.contains("9 planted"),
		"all-empty summary says '9 planted' (got '%s')" % _last_text)
	_check(not _last_text.contains("harvested") and not _last_text.contains("watered"),
		"all-empty summary has no harvest/water noise (got '%s')" % _last_text)
	# 7) Unmounted single-cell behavior unchanged: existing test files cover
	# plant/water/harvest at a single cell. Here we just sanity-check the
	# unmounted branch still calls plant on an empty cell with the same seed
	# and does NOT touch the surrounding 3x3 ring.
	gd.current_stamina = 100.0
	gd.inventory.clear()
	gd.add_item("seed_sticky_rice", 4)
	player._seed_lookup.clear()
	# Pick a cell with all 8 neighbors empty + the 1x1 target itself empty.
	var u_cell: Vector2i = Vector2i(8, 8)
	# Snapshot surroundings BEFORE the unmounted interact.
	for dxa in [-1, 0, 1]:
		for dya in [-1, 0, 1]:
			var nb: Vector2i = u_cell + Vector2i(dxa, dya)
			if nb == u_cell:
				continue
			_check(gm.get_plot(nb) == null,
				"pre-unmounted: neighbor (%d,%d) empty" % [nb.x, nb.y])
	# Fire the unmounted path: re-aim player at u_cell, ensure not mounted.
	player.mounted = false
	player.global_position = Vector2(u_cell.x * 48 + 24, u_cell.y * 48 + 24)
	player._try_grid_interact()
	_check(gm.get_plot(u_cell) != null, "unmounted single-cell plant fills target cell")
	for dxa in [-1, 0, 1]:
		for dya in [-1, 0, 1]:
			var nb2: Vector2i = u_cell + Vector2i(dxa, dya)
			if nb2 == u_cell:
				continue
			_check(gm.get_plot(nb2) == null,
				"unmounted: neighbor (%d,%d) UNTOUCHED (no 3x3 spill)" % [nb2.x, nb2.y])
	main.queue_free()
	print("\n=== MOUNTED-INTERACT TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("MOUNTED INTERACT GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
