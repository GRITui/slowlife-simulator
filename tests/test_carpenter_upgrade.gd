extends SceneTree
# TASK-322 — CarpenterUpgrade house kitchen extension.
# Verifies: node presence + structure_id, pre-recipe invisibility at the
# CookingStation (gated by infrastructure), soft-fail on missing silver/wood/
# stamina, exact-cost success, post-recipe visibility, no-op re-interact.
# TASK-357: CarpenterUpgrade lives under CoastalArea.tscn now (Phase-1
# cluster split), but CookingStation stays in World.tscn — the two
# scenes need to be instantiated side by side under root. This is safe
# because is_repaired()/get_all_craftable() read GameData's global
# infrastructure state, not a scene-tree relationship between the two.
const COASTAL_AREA_PATH: String = "res://scenes/interiors/CoastalArea.tscn"

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  carpenter :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  carpenter :: %s" % label)

func _craftable_ids(station: Node) -> Array:
	var all: Array = station.get_all_craftable() if station != null else []
	var ids: Array = []
	for r: Dictionary in all:
		ids.append(String(r.get("id", "")))
	return ids

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var coastal: Node = (load(COASTAL_AREA_PATH) as PackedScene).instantiate()
	root.add_child(coastal)
	# two frames: one for World._ready/CoastalArea._ready to wire up, one for safety
	await process_frame
	await process_frame

	# (b) node present, structure_id correct
	var carpenter: Node = coastal.get_node_or_null("CarpenterUpgrade")
	_check(carpenter != null, "CarpenterUpgrade node instanced under CoastalArea.tscn")
	if carpenter != null:
		_check(String(carpenter.structure_id) == "house_kitchen",
			"structure_id == 'house_kitchen' (got '%s')" % String(carpenter.structure_id))

	# reset state so prior infra/inventory doesn't leak between test invocations
	gd.silver = 0
	gd.inventory.clear()
	gd.infrastructure.clear()
	gd.current_stamina = 100.0
	gd.harmony = 0

	var station: Node = main.get_node_or_null("CookingStation")
	_check(station != null, "CookingStation present (World.gd _ensure_cooking_station)")

	# (a) before repair, even with all ingredients held, the new recipes
	# must NOT appear in get_all_craftable().
	gd.add_item("rice_flour", 1)
	gd.add_item("coconut_milk", 1)
	gd.add_item("chili", 2)
	gd.add_item("palm_sugar", 2)
	gd.add_item("buffalo_milk_high", 1)
	gd.add_item("peanut", 1)
	if station != null:
		var ids_pre: Array = _craftable_ids(station)
		_check(not ids_pre.has("khao_soi"),
			"khao_soi hidden before house_kitchen repaired (%s)" % str(ids_pre))
		_check(not ids_pre.has("massaman_curry"),
			"massaman_curry hidden before house_kitchen repaired (%s)" % str(ids_pre))

	# (c) soft-fail with insufficient silver (the order-of-checks gate: silver
	# is checked first per spec). Set stamina and wood generously, leave silver=0.
	gd.add_item("wood", 5)
	gd.current_stamina = 100.0
	gd.silver = 0
	if carpenter != null:
		var silver_before: int = int(gd.silver)
		var wood_before: int = int(gd.inventory.get("wood", 0))
		var ok: bool = carpenter._try_repair()
		_check(ok == false, "_try_repair() refuses with 0 silver")
		_check(not gd.is_repaired("house_kitchen"), "house_kitchen NOT repaired after soft-fail")
		_check(int(gd.silver) == silver_before, "silver unchanged on silver-soft-fail (got %d, expected %d)" % [int(gd.silver), silver_before])
		_check(int(gd.inventory.get("wood", 0)) == wood_before, "wood unchanged on silver-soft-fail")

	# (c-2) soft-fail with insufficient wood (silver present, stamina present).
	gd.silver = 50
	gd.inventory.erase("wood")
	if carpenter != null:
		var silver_before2: int = int(gd.silver)
		var wood_before2: int = int(gd.inventory.get("wood", 0))
		var ok2: bool = carpenter._try_repair()
		_check(ok2 == false, "_try_repair() refuses with 0 wood")
		_check(not gd.is_repaired("house_kitchen"), "house_kitchen NOT repaired after wood soft-fail")
		_check(int(gd.silver) == silver_before2, "silver refunded on wood soft-fail (got %d, expected %d)" % [int(gd.silver), silver_before2])
		_check(int(gd.inventory.get("wood", 0)) == wood_before2, "wood unchanged on wood soft-fail")

	# (c-3) soft-fail with insufficient stamina (silver + wood present).
	gd.add_item("wood", 5)
	gd.current_stamina = 5.0 # below 20
	if carpenter != null:
		var silver_before3: int = int(gd.silver)
		var wood_before3: int = int(gd.inventory.get("wood", 0))
		var stamina_before3: float = float(gd.current_stamina)
		var ok3: bool = carpenter._try_repair()
		_check(ok3 == false, "_try_repair() refuses with <20 stamina")
		_check(not gd.is_repaired("house_kitchen"), "house_kitchen NOT repaired after stamina soft-fail")
		_check(int(gd.silver) == silver_before3, "silver refunded on stamina soft-fail (got %d, expected %d)" % [int(gd.silver), silver_before3])
		_check(int(gd.inventory.get("wood", 0)) == wood_before3, "wood unchanged on stamina soft-fail")
		_check(is_equal_approx(float(gd.current_stamina), stamina_before3), "stamina unchanged on stamina soft-fail")

	# (d) full success path: 50 silver, 5 wood, 100 stamina.
	gd.silver = 60
	gd.add_item("wood", 7) # extra so we can detect *exactly* 5 deducted
	gd.current_stamina = 100.0
	gd.harmony = 0
	if carpenter != null:
		var silver_pre: int = int(gd.silver)
		var wood_pre: int = int(gd.inventory.get("wood", 0))
		var ok4: bool = carpenter._try_repair()
		_check(ok4 == true, "_try_repair() succeeds with full resources")
		_check(int(gd.silver) == silver_pre - 50, "exactly 50 silver deducted (got %d, expected %d)" % [int(gd.silver), silver_pre - 50])
		_check(int(gd.inventory.get("wood", 0)) == wood_pre - 5, "exactly 5 wood deducted (got %d, expected %d)" % [int(gd.inventory.get("wood", 0)), wood_pre - 5])
		_check(gd.is_repaired("house_kitchen"), "GameData.is_repaired('house_kitchen') == true")
		_check(int(gd.harmony) == 5, "+5 harmony awarded (got %d)" % int(gd.harmony))

	# (e) after repair, with recipe ingredients in inventory and season "",
	# get_all_craftable() must include both new recipes.
	if station != null:
		var ids_post: Array = _craftable_ids(station)
		_check(ids_post.has("khao_soi"),
			"khao_soi appears in get_all_craftable() after repair (%s)" % str(ids_post))
		_check(ids_post.has("massaman_curry"),
			"massaman_curry appears in get_all_craftable() after repair (%s)" % str(ids_post))

	# (f) second attempt after repair is a no-op (no double-charge).
	if carpenter != null:
		var silver_post: int = int(gd.silver)
		var wood_post: int = int(gd.inventory.get("wood", 0))
		var ok5: bool = carpenter._try_repair()
		_check(ok5 == false, "second _try_repair() returns false (already repaired)")
		_check(int(gd.silver) == silver_post, "silver unchanged on second attempt (no double-charge)")
		_check(int(gd.inventory.get("wood", 0)) == wood_post, "wood unchanged on second attempt (no double-charge)")
		_check(gd.is_repaired("house_kitchen"), "house_kitchen still repaired after no-op re-interact")

	main.queue_free()
	coastal.queue_free()
	print("\n=== CARPENTER TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("CARPENTER GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)