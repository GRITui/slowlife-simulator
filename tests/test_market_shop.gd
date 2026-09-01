extends SceneTree
# TASK-327 market shop gate — selectable buy list replaces blind cascade.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  market-shop :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  market-shop :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var sb: Node = root.get_node("SignalBus")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var npc: Node = main.get_node_or_null("MarketStall")
	_check(npc != null, "MarketStallNPC present")
	_check(sb.market_shop != null, "MarketShop registered on SignalBus")
	if npc == null or sb.market_shop == null:
		await process_frame
		quit(1)
		return
	var shop: Node = sb.market_shop
	_check(shop.visible == false, "shop starts hidden")

	npc._open_shop()
	_check(shop.visible == true, "interact opens the shop panel")

	# Seasonal seed purchase: cool season sells seed_cabbage at 8 silver.
	gd.current_season = "cool"
	gd.silver = 20
	gd.inventory.erase("seed_cabbage")
	shop.open(npc._market, "cool")
	shop._on_buy_pressed("seed_cabbage", 8)
	_check(int(gd.inventory.get("seed_cabbage", 0)) == 1, "seed_cabbage granted after purchase")
	_check(int(gd.silver) == 12, "silver deducted by price (20 -> 12)")

	# Insufficient silver: purchase must not grant item or deduct silver.
	gd.silver = 3
	gd.inventory.erase("seed_mango")
	shop._on_buy_pressed("seed_mango", 30)
	_check(int(gd.inventory.get("seed_mango", 0)) == 0, "insufficient silver blocks purchase")
	_check(int(gd.silver) == 3, "silver unchanged on blocked purchase")

	shop.close()
	_check(shop.visible == false, "close hides the panel")

	main.queue_free()
	print("\n=== MARKET-SHOP TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("MARKET-SHOP GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
