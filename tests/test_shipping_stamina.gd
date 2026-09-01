extends SceneTree
# TASK-326 shipping-milestone stamina progression — tier grants +15 max_stamina.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  shipping_stamina :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  shipping_stamina :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	gd.max_stamina = 100.0
	gd.current_stamina = 100.0
	gd.lifetime_items_shipped = 0
	gd.stamina_tier = 0
	gd.inventory.clear()

	gd.add_item("rice_grain", 24)
	for i: int in 24:
		var gained: int = gd.sell_item("rice_grain")
		_check(gained == 2, "sale #%d returned 2 silver" % (i + 1))

	_check(int(gd.lifetime_items_shipped) == 24, "24 shipments counted")
	_check(int(gd.stamina_tier) == 0, "no tier before threshold")
	_check(gd.max_stamina == 100.0, "max_stamina still 100.0 at 24 shipments")

	gd.add_item("rice_grain", 1)
	var gained25: int = gd.sell_item("rice_grain")
	_check(gained25 == 2, "25th sale returned 2 silver")
	_check(int(gd.lifetime_items_shipped) == 25, "25 shipments counted")
	_check(int(gd.stamina_tier) == 1, "stamina_tier == 1 at 25 shipments")
	_check(gd.max_stamina == 115.0, "max_stamina == 115.0 after tier 1")
	_check(gd.current_stamina == 115.0, "current_stamina == 115.0 after tier 1")

	gd.add_item("rice_grain", 5)
	for i: int in 5:
		gd.sell_item("rice_grain")
	_check(int(gd.lifetime_items_shipped) == 30, "30 shipments counted")
	_check(int(gd.stamina_tier) == 1, "no double-grant at 30 (still tier 1)")
	_check(gd.max_stamina == 115.0, "max_stamina still 115.0 (no double-grant)")

	gd.inventory.clear()
	gd.add_item("rice_grain", 175)
	for i: int in 175:
		gd.sell_item("rice_grain")
	_check(int(gd.lifetime_items_shipped) == 205, "205 shipments counted (200 + 5 over)")
	_check(int(gd.stamina_tier) == 4, "stamina_tier capped at 4 after crossing all thresholds")
	_check(gd.max_stamina == 160.0, "max_stamina capped at 160.0")

	gd.add_item("rice_grain", 1)
	gd.sell_item("rice_grain")
	_check(int(gd.lifetime_items_shipped) == 206, "206 shipments counted")
	_check(int(gd.stamina_tier) == 4, "stamina_tier stays 4 past 200")
	_check(gd.max_stamina == 160.0, "max_stamina stays 160.0 past 200")

	main.queue_free()
	print("\n=== SHIPPING STAMINA TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("SHIPPING STAMINA TESTS FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)