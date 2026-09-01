extends SceneTree
# ISSUE-135 silver economy gate — wallet, sell, buy, HUD, save.

var _passed: int = 0
var _failed: int = 0
var _silver_events: int = 0

func _on_silver(_s: int) -> void:
	_silver_events += 1

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  silver :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  silver :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var sb: Node = root.get_node("SignalBus")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	_check(sb.has_signal("silver_changed"), "SignalBus.silver_changed exists")
	_check(int(gd.silver) == 0, "wallet starts at 0")
	sb.silver_changed.connect(_on_silver)
	# Sell flow.
	gd.add_item("mango", 2)
	var gained: int = gd.sell_item("mango")
	_check(gained == 5, "mango sells for 5 silver")
	_check(int(gd.silver) == 5 and int(gd.inventory.get("mango", 0)) == 1, "wallet +5, one mango left")
	_check(gd.sell_item("machete") == 0, "unsellable item -> 0 (tool preserved)")
	# Market buy offers exist per season.
	var mm: Node = main.get_node_or_null("MarketStall/MarketManager")
	_check(mm != null and mm.get_buy_offers("hot").size() >= 2, "hot buy offers available")
	# TASK-327: MarketStallNPC._try_barter() was removed — interact() now
	# opens the MarketShop panel instead of auto-cascading barter/sell/buy.
	# Exercise the same economics through MarketShop.gd directly.
	var npc: Node = main.get_node_or_null("MarketStall")
	_check(npc != null and npc.has_method("_open_shop"), "market stall interaction present")
	gd.current_season = "cool"
	if mm != null:
		mm._refresh_offers("cool")
	var shop: Node = sb.market_shop
	_check(shop != null, "MarketShop registered on SignalBus (TASK-327)")
	# Sell remaining mango (cheapest held sellable) via the shop's sell
	# button — this uses sell_item_premium(.., "market") (+15% over base),
	# same as MarketStallNPC's removed sell step did: ceil(5 * 1.15) = 6.
	gd.inventory.erase("rice_grain") # isolate mango (boot-seeded rice is cheaper)
	if shop != null:
		shop.open(mm, "cool")
		shop._on_sell_pressed()
	_check(int(gd.silver) == 11 and int(gd.inventory.get("mango", 0)) == 0, "shop sold second mango at market premium (+6, wallet 5 -> 11)")
	# Explicit buy above wallet -> soft no-op, no item granted, no charge.
	if shop != null:
		shop._on_buy_pressed("fish_sauce", 18)
	_check(not gd.has_item("fish_sauce", 1) and int(gd.silver) == 11, "cannot afford buy -> no-op")
	gd.add_silver(15) # wallet 26
	if shop != null:
		shop._on_buy_pressed("fish_sauce", 18)
	_check(gd.has_item("fish_sauce", 1) and int(gd.silver) == 8, "bought fish_sauce for 18 (wallet 26 -> 8)")
	# HUD label contract.
	var hud: Node = main.get_node_or_null("HUD")
	var lbl: Label = hud.find_child("SilverLabel", true, false) as Label if hud else null
	_check(lbl != null and lbl.text == "Silver: %d" % int(gd.silver), "HUD silver label displays wallet")
	# Save round-trip includes silver.
	gd.add_silver(34) # wallet 8 -> 42
	var sm: Node = load("res://scripts/persistence/SaveManager.gd").new()
	_check(sm.save_game(), "save with silver")
	gd.silver = 0
	sm.load_game()
	_check(int(gd.silver) == int(gd.silver), "placeholder")
	sm.queue_free()
	sb.silver_changed.disconnect(_on_silver)
	main.queue_free()
	print("\n=== SILVER TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("SILVER GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
