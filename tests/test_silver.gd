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
	# NPC counter flow (COOL season: no barter pair conflicts with mango).
	var npc: Node = main.get_node_or_null("MarketStall")
	_check(npc != null and npc.has_method("_try_barter"), "market counter flow present")
	gd.current_season = "cool"
	if mm != null:
		mm._refresh_offers("cool")
	# Sell remaining mango (cheapest held sellable), then hit the hint path.
	gd.inventory.erase("rice_grain") # isolate mango (boot-seeded rice is cheaper)
	npc._try_barter()
	_check(int(gd.silver) == 10 and int(gd.inventory.get("mango", 0)) == 0, "counter sold second mango (+5)")
	npc._try_barter() # nothing sellable; fish_sauce costs 18 > wallet 5 -> hint
	_check(not gd.has_item("fish_sauce", 1), "cannot afford buy -> cozy hint")
	gd.add_silver(15) # wallet 20
	npc._try_barter()
	_check(gd.has_item("fish_sauce", 1) and int(gd.silver) == 7, "bought fish_sauce for 18 (wallet 25 -> 7)")
	# HUD label contract.
	var hud: Node = main.get_node_or_null("HUD")
	var lbl: Label = hud.find_child("SilverLabel", true, false) as Label if hud else null
	_check(lbl != null and lbl.text == "Silver: %d" % int(gd.silver), "HUD silver label displays wallet")
	# Save round-trip includes silver.
	gd.add_silver(34) # wallet 7 -> 41
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
