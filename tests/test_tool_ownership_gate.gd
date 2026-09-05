extends SceneTree
# Owner playtest finding (2026-09-05): tilling/watering/harvesting had no
# tool-ownership gate at all -- GameData.tool_tiers only ever scaled an
# efficiency bonus, never gated the action. Player._try_grid_interact()
# now checks GameData.has_item("hoe"/"watering_can"/"sickle", 1) before
# each action, mirroring FishingSpot.gd's canonical "you need a fishing
# rod" gate. World._ensure_fishing_spot() grants all 3 tools once, same
# idempotent pattern as fishing_rod.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  tool-ownership-gate :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  tool-ownership-gate :: %s" % label)

func _press_interact(player: Node) -> void:
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	player.call("_unhandled_input", ev)
	await process_frame

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var player: Node = main.get_node_or_null("Player")
	var gm: Node = main.get_node_or_null("GridManager")
	_check(player != null, "Player present in World")
	_check(gm != null, "GridManager present in World")
	if player == null or gm == null:
		main.queue_free()
		quit(1)
		return

	# World._ready() should have granted all 3 starting tools already.
	_check(gd.has_item("hoe", 1), "hoe granted at boot")
	_check(gd.has_item("watering_can", 1), "watering_can granted at boot")
	_check(gd.has_item("sickle", 1), "sickle granted at boot")

	var sb: Node = root.get_node("SignalBus")
	var captured: Array = []
	var handler := func(speaker: String, text: String) -> void:
		captured.append([speaker, text])
	sb.connect("show_dialogue", handler)

	# --- Till/plant: no hoe -> blocked, exact soft-fail line, no plot made. ---
	gd.remove_item("hoe", int(gd.inventory.get("hoe", 0)))
	_check(not gd.has_item("hoe", 1), "hoe removed for this case")
	var till_cell: Vector2i = Vector2i(5, 5)
	(player as Node2D).global_position = Vector2(till_cell.x * 48 + 24, till_cell.y * 48 + 24)
	captured.clear()
	await _press_interact(player)
	_check(captured.size() == 1 and String(captured[0][1]) == "A hoe would help. The handler's shop carries them.",
		"no hoe: interact blocked with the exact soft-fail line")
	_check(gm.get_plot(till_cell) == null, "no hoe: no plot was actually created")

	# Grant the hoe back -> planting now works.
	gd.add_item("hoe", 1)
	gd.current_season = "hot"
	gd.add_item("seed_mango", 1)
	captured.clear()
	await _press_interact(player)
	_check(gm.get_plot(till_cell) != null, "hoe granted: interact now creates a plot")
	_check(captured.size() == 1 and String(captured[0][1]).begins_with("Planted"),
		"hoe granted: interact shows the normal Planted line")

	# --- Water: no watering_can -> blocked. Plot from above is unwatered. ---
	gd.remove_item("watering_can", int(gd.inventory.get("watering_can", 0)))
	captured.clear()
	await _press_interact(player)
	_check(captured.size() == 1 and String(captured[0][1]) == "A watering can would help. The handler's shop carries them.",
		"no watering_can: interact blocked with the exact soft-fail line")
	var plot_after_water_gate = gm.get_plot(till_cell)
	_check(plot_after_water_gate != null and not bool(plot_after_water_gate.watered),
		"no watering_can: plot really wasn't watered")

	gd.add_item("watering_can", 1)
	captured.clear()
	await _press_interact(player)
	_check(String(captured[0][1]) == "Watered plot.", "watering_can granted: interact waters normally")

	# --- Harvest: no sickle -> blocked. Force a harvest-ready plot directly
	# (fast-forwarding growth isn't this test's concern). ---
	var harvest_cell: Vector2i = Vector2i(6, 5)
	var crop: Resource = load("res://data/crops/jasmine_rice.tres")
	gm.plant(harvest_cell, crop)
	var hplot = gm.get_plot(harvest_cell)
	if hplot != null:
		hplot.stage = crop.total_stages - 1
	gd.remove_item("sickle", int(gd.inventory.get("sickle", 0)))
	(player as Node2D).global_position = Vector2(harvest_cell.x * 48 + 24, harvest_cell.y * 48 + 24)
	captured.clear()
	await _press_interact(player)
	_check(captured.size() == 1 and String(captured[0][1]) == "A sickle would help. The handler's shop carries them.",
		"no sickle: interact blocked with the exact soft-fail line")
	_check(gm.get_plot(harvest_cell) != null, "no sickle: harvest-ready plot was NOT cleared")

	gd.add_item("sickle", 1)
	captured.clear()
	await _press_interact(player)
	_check(String(captured[0][1]).begins_with("Harvested"), "sickle granted: interact harvests normally")

	sb.disconnect("show_dialogue", handler)
	main.queue_free()
	print("\n=== TOOL-OWNERSHIP-GATE TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("TOOL-OWNERSHIP-GATE GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
