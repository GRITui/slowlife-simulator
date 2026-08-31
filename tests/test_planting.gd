extends SceneTree
# TASK-043 planting generalization gate — seed-driven crop selection.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  planting :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  planting :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var player: Node = main.get_node_or_null("Player")
	var gm: Node = main.get_node_or_null("GridManager")
	_check(player != null and player.has_method("_find_crop_for_held_seed"),
		"Player exposes _find_crop_for_held_seed")
	if player == null or gm == null:
		main.queue_free()
		await process_frame
		quit(1)
		return
	# Lookup table built from data/crops (23 crops).
	player._seed_lookup.clear()
	# Seed held: seed_mango -> mango CropData. (Clear boot-seeded seed_rice
	# first — the picker takes the FIRST held seed, per inbox spec.)
	gd.inventory.erase("seed_rice")
	gd.add_item("seed_mango", 1)
	var crop: Resource = player._find_crop_for_held_seed()
	_check(crop != null and String(crop.id) == "mango",
		"held seed_mango resolves to mango CropData (got '%s')" % (String(crop.id) if crop else "null"))
	gd.remove_item("seed_mango", 1)
	# No seeds held -> null (caller falls back to jasmine).
	gd.inventory.clear()
	var none: Resource = player._find_crop_for_held_seed()
	_check(none == null, "no seeds held -> null (jasmine fallback upstream)")
	# End-to-end: plant sticky rice with its seed at a paddy cell.
	gd.current_season = "hot"
	gd.add_item("seed_sticky_rice", 2)
	var sticky: Resource = player._find_crop_for_held_seed()
	_check(sticky != null and String(sticky.id) == "sticky_rice", "seed_sticky_rice resolves")
	var seeds_before: int = int(gd.inventory.get("seed_sticky_rice", 0))
	var ok: bool = gm.plant(Vector2i(5, 6), sticky)
	_check(ok, "plant(sticky_rice) succeeds in hot season")
	_check(int(gd.inventory.get("seed_sticky_rice", 0)) == seeds_before - 1, "seed consumed on plant")
	main.queue_free()
	print("\n=== PLANTING TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("PLANTING GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
