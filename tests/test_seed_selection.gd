extends SceneTree
# TASK-350 — seed-selection regression gate. Covers the actual bug fix
# (the "first-held seed" inventory-order pick) plus the new Q-cycle path,
# the no-seed dialogue change, and the SeedIndicator touch handler.

var _passed: int = 0
var _failed: int = 0
var _last_speaker: String = ""
var _last_text: String = ""
var _sb: Node = null

func _on_dialogue(speaker: String, text: String) -> void:
	_last_speaker = speaker
	_last_text = text

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  seed-selection :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  seed-selection :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	_sb = root.get_node("SignalBus")
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
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
	player._primed_seed_id = ""
	player._seed_lookup.clear()
	# Pre-populate _seed_lookup so we don't depend on directory scan order
	# (the lookup-population logic is intentionally not under test here —
	# it's the post-population SELECTION logic the spec changed).
	var sticky: Resource = load("res://data/crops/sticky_rice.tres")
	var mango: Resource = load("res://data/crops/mango.tres")
	var cabbage: Resource = load("res://data/crops/cabbage.tres")
	player._seed_lookup["seed_sticky_rice"] = sticky
	player._seed_lookup["seed_mango"] = mango
	player._seed_lookup["seed_cabbage"] = cabbage
	# Connect dialogue listener for assertion use throughout.
	_sb.show_dialogue.connect(_on_dialogue)

	# --- Test 1: 2+ seeds, cycle advances in deterministic sorted order,
	# wraps around. ---
	gd.inventory.clear()
	player._primed_seed_id = ""
	gd.add_item("seed_mango", 1)
	gd.add_item("seed_cabbage", 1)
	gd.add_item("seed_sticky_rice", 1)
	# sorted: ["seed_cabbage", "seed_mango", "seed_sticky_rice"]
	player.cycle_primed_seed()
	_check(player._primed_seed_id == "seed_cabbage",
		"cycle from empty -> first sorted 'seed_cabbage' (got '%s')" % player._primed_seed_id)
	player.cycle_primed_seed()
	_check(player._primed_seed_id == "seed_mango",
		"cycle advance -> 'seed_mango' (got '%s')" % player._primed_seed_id)
	player.cycle_primed_seed()
	_check(player._primed_seed_id == "seed_sticky_rice",
		"cycle advance -> 'seed_sticky_rice' (got '%s')" % player._primed_seed_id)
	player.cycle_primed_seed()
	_check(player._primed_seed_id == "seed_cabbage",
		"cycle wraps back to 'seed_cabbage' (got '%s')" % player._primed_seed_id)

	# --- Test 2: planting with a seed primed plants THAT crop, not the
	# first-in-inventory one. This is the actual bug fix. ---
	gd.inventory.clear()
	player._primed_seed_id = ""
	gd.add_item("seed_mango", 1)
	gd.add_item("seed_sticky_rice", 1)
	# Sorted order: seed_mango, seed_sticky_rice. Prime the SECOND.
	player._primed_seed_id = "seed_sticky_rice"
	var crop: Resource = player._find_crop_for_held_seed()
	_check(crop != null and String(crop.id) == "sticky_rice",
		"primed seed_sticky_rice resolves to sticky_rice crop (got '%s')" % (String(crop.id) if crop else "null"))
	# Drive the actual plant via _try_grid_interact and confirm the crop
	# placed at the cell is sticky_rice (not mango, which would be the
	# old first-in-Dictionary-order fallback).
	gd.current_stamina = 100.0
	var cell: Vector2i = Vector2i(7, 7)
	player.global_position = Vector2(cell.x * 48 + 24, cell.y * 48 + 24)
	player.mounted = false
	player._try_grid_interact()
	var planted_plot = gm.get_plot(cell) if gm.has_method("get_plot") else null
	_check(planted_plot != null and planted_plot.crop != null
			and String(planted_plot.crop.id) == "sticky_rice",
		"primed seed was the one actually planted (got crop '%s')" %
		(String(planted_plot.crop.id) if planted_plot and planted_plot.crop else "null"))

	# --- Test 3: zero seeds held -> cycle leaves primed empty + dialogue,
	# plant still works with jasmine_rice + new dialogue line. ---
	gd.inventory.clear()
	player._primed_seed_id = ""
	gd.current_stamina = 100.0
	_last_speaker = ""
	_last_text = ""
	player.cycle_primed_seed()
	_check(player._primed_seed_id == "" and _last_text == "No seeds to select.",
		"zero seeds: cycle leaves primed empty + 'No seeds to select.' line (got primed='%s', text='%s')" %
		[player._primed_seed_id, _last_text])
	# Reset primed (cycle doesn't auto-prime anything new on empty).
	player._primed_seed_id = ""
	# Plant at a fresh cell — expect jasmine_rice + new dialogue.
	var cell3: Vector2i = Vector2i(11, 11)
	player.global_position = Vector2(cell3.x * 48 + 24, cell3.y * 48 + 24)
	_last_speaker = ""
	_last_text = ""
	player._try_grid_interact()
	var p3 = gm.get_plot(cell3) if gm.has_method("get_plot") else null
	_check(p3 != null and p3.crop != null and String(p3.crop.id) == "jasmine_rice",
		"zero seeds: plant still succeeds with jasmine_rice (got '%s')" %
		(String(p3.crop.id) if p3 and p3.crop else "null"))
	_check(_last_text == "No seed selected — planted rice instead.",
		"zero seeds: plant emits 'No seed selected — planted rice instead.' line (got '%s')" % _last_text)

	# --- Test 4: held but never primed -> legacy "first held seed_*" path
	# with the NORMAL 'Planted %s.' dialogue (regression check). ---
	gd.inventory.clear()
	player._primed_seed_id = ""
	gd.add_item("seed_mango", 2)
	gd.current_stamina = 100.0
	# Mango is a hot-season crop only; switch the grid to hot so the plant
	# isn't rejected on the season check (the legacy "first held seed_*"
	# path is what we're testing here, not the season gate).
	gm.current_season = "hot"
	var cell4: Vector2i = Vector2i(10, 7)
	player.global_position = Vector2(cell4.x * 48 + 24, cell4.y * 48 + 24)
	_last_speaker = ""
	_last_text = ""
	player._try_grid_interact()
	var p4 = gm.get_plot(cell4) if gm.has_method("get_plot") else null
	_check(p4 != null and p4.crop != null and String(p4.crop.id) == "mango",
		"held-but-not-primed: plants the first held seed (mango, got '%s')" %
		(String(p4.crop.id) if p4 and p4.crop else "null"))
	_check(_last_text.begins_with("Planted ") and not _last_text.contains("No seed selected"),
		"held-but-not-primed: emits normal 'Planted ...' line (got '%s')" % _last_text)
	# Restore default season for downstream tests.
	gm.current_season = "cool"

	# --- Test 5: primed seed runs out -> next cycle skips it. ---
	gd.inventory.clear()
	player._primed_seed_id = ""
	gd.add_item("seed_mango", 1)
	gd.add_item("seed_cabbage", 2)
	# Prime mango (sorted: cabbage, mango). Prime mango.
	player._primed_seed_id = "seed_mango"
	# Drain mango to 0 (simulate planting).
	gd.remove_item("seed_mango", 1)
	# Now cycle should skip the depleted mango and land on cabbage.
	player.cycle_primed_seed()
	_check(player._primed_seed_id == "seed_cabbage",
		"depleted primed seed is skipped on next cycle (got '%s')" % player._primed_seed_id)
	# Drain cabbage to 0 too — only depleted seeds left, no held seeds.
	gd.remove_item("seed_cabbage", 2)
	_last_speaker = ""
	_last_text = ""
	player._primed_seed_id = "seed_cabbage" # stale, but no held anymore
	player.cycle_primed_seed()
	_check(player._primed_seed_id == "" and _last_text == "No seeds to select.",
		"only-depleted seeds: cycle empties primed + 'No seeds to select.' (got primed='%s', text='%s')" %
		[player._primed_seed_id, _last_text])

	# --- Test 6: SeedIndicator's tap synthesizes the cycle_seed action. ---
	var hud: Node = main.get_node_or_null("HUD")
	_check(hud != null, "HUD present in main scene")
	var ind: Control = hud.get_node_or_null("SeedIndicator") if hud else null
	_check(ind != null, "HUD has SeedIndicator")
	if ind != null:
		_check(ind.has_method("_emit_cycle_seed"), "SeedIndicator exposes _emit_cycle_seed")
		ind._emit_cycle_seed()
		await process_frame
		_check(Input.is_action_pressed("cycle_seed"),
			"SeedIndicator tap synthesizes cycle_seed action (got pressed=%s)" %
			str(Input.is_action_pressed("cycle_seed")))
		# Release so subsequent assertions / next tests aren't sticky.
		var rel: InputEventAction = InputEventAction.new()
		rel.action = "cycle_seed"
		rel.pressed = false
		Input.parse_input_event(rel)
		await process_frame

	# --- Test 7: SeedIndicator itself satisfies the 44x44pt touch-target
	# minimum (visible for both desktop and mobile, since only the TAP path
	# is mobile-gated — the label/state is useful for keyboard players
	# too). ---
	if ind != null:
		var ms: Vector2 = (ind as Control).custom_minimum_size
		_check(ms.y >= 44.0,
			"SeedIndicator meets 44pt touch minimum (y=%d)" % int(ms.y))

	# Clean up dialogue listener + tear down.
	if _sb.show_dialogue.is_connected(_on_dialogue):
		_sb.show_dialogue.disconnect(_on_dialogue)
	main.queue_free()
	print("\n=== SEED-SELECTION TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("SEED-SELECTION GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)