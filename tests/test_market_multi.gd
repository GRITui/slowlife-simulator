extends SceneTree
# TASK-047 market multi-offer gate — fish_sauce/shrimp_paste obtainable.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  market-multi :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  market-multi :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var mm: Node = main.get_node_or_null("MarketStall/MarketManager")
	_check(mm != null, "MarketManager present")
	if mm == null:
		await process_frame
		quit(1)
		return
	# Hot season: 3 offers incl. coastal goods.
	gd.current_season = "hot"
	var hot: Array[Dictionary] = mm.get_offers("hot")
	_check(hot.size() == 3, "hot season has 3 offers")
	var goods: Array = []
	for o: Dictionary in hot:
		goods.append(String(o.get("want", "")))
	_check(goods.has("fish_sauce") and goods.has("shrimp_paste"),
		"coastal goods in hot offers %s" % str(goods))
	# Monsoon: fish_sauce obtainable.
	gd.current_season = "monsoon"
	var mon: Array[Dictionary] = mm.get_offers("monsoon")
	_check(mon.size() == 3, "monsoon season has 3 offers")
	# End-to-end: barter rice_grain -> fish_sauce (needs GameData.barter pair!)
	# NOTE: GameData.BARTER_PAIRS gates barter validity — coastal goods must be
	# barter-legal, else market-only items are still unobtainable.
	gd.add_item("rice_grain", 2)
	var ok: bool = gd.barter("rice_grain", "fish_sauce")
	_check(ok, "barter rice_grain -> fish_sauce accepted")
	_check(int(gd.inventory.get("fish_sauce", 0)) == 1, "fish_sauce in inventory")
	main.queue_free()
	print("\n=== MARKET-MULTI TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("MARKET-MULTI GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
