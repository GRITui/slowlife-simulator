extends SceneTree
# TASK-029 crafting wiring gate — station live, RecipeData consumed end-to-end.

var _passed: int = 0
var _failed: int = 0
var _craft_hits: int = 0

func _on_craft(_id: String, _qty: int) -> void:
	_craft_hits += 1

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  crafting :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  crafting :: %s" % label)

func _initialize() -> void:
	var sb: Node = root.get_node("SignalBus")
	_check(sb.has_signal("craft_completed"), "SignalBus.craft_completed exists")
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var station: Node = main.get_node_or_null("CookingStation")
	_check(station != null, "CookingStation instanced at hall floor")
	_check(station != null and station.is_in_group("cooking_station"), "station tagged")
	if station == null:
		main.queue_free()
		await process_frame
		quit(1)
		return
	# Seasonal craft path: cool season + seeded basil/rice -> thai_basil_stirfry.
	gd.current_season = "cool"
	gd.add_item("thai_basil", 3)
	gd.add_item("rice_grain", 2)
	var craftable: Dictionary = station.get_craftable()
	_check(not craftable.is_empty(), "cool season yields a craftable recipe")
	_check(String(craftable.get("id", "")) == "thai_basil_stirfry",
		"thai_basil_stirfry selected (got '%s')" % String(craftable.get("id", "")))
	var rice_before: int = int(gd.inventory.get("rice_grain", 0))
	sb.craft_completed.connect(_on_craft)
	_check(station.try_craft(), "try_craft succeeds")
	_check(_craft_hits == 1, "craft_completed emitted once")
	_check(int(gd.inventory.get("thai_basil_stirfry", 0)) == 1, "output added to inventory")
	_check(int(gd.inventory.get("rice_grain", 0)) == rice_before - 2, "inputs consumed")
	_check(int(gd.harmony) >= 5, "harmony rewarded")
	# Empty pantry: soft fail, no signal.
	_craft_hits = 0
	gd.inventory.clear()
	_check(station.try_craft() == false, "empty pantry soft-fails")
	_check(_craft_hits == 0, "no emission on soft fail")
	sb.craft_completed.disconnect(_on_craft)
	main.queue_free()
	print("\n=== CRAFTING TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("CRAFTING GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
