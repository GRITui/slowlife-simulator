extends SceneTree
# TASK-344 coastal trading post gate — lazy unlock (default shipped
# count hides the spot), unlock on the next minute_ticked once
# lifetime_items_shipped reaches 200 (the stamina_tier 4 cap threshold),
# immediate presence on a fresh boot when the save already had 200
# shipped, real InteractArea (the @onready null-bug has shipped twice
# in this project), the priciest-sellable behavior (construct an
# inventory with 2+ sellable items of different value and confirm the
# higher-priced one is chosen and sold at the "coastal" rate
# specifically, i.e. price == ceil(base * 1.25), NOT the base /
# market / specialty rate), and the soft-fail zero-mutation path
# when nothing sellable is held.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  coastal-trading-post :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  coastal-trading-post :: %s" % label)

func _initialize() -> void:
	var sb: Node = root.get_node("SignalBus")
	var gd: Node = root.get_node("GameData")
	# 1) Default state (lifetime_items_shipped=0) — CoastalTradingPost NOT
	# present under Main after boot. Mirrors test_mountain_cave.gd's
	# SceneTree + Main.tscn-instantiation pattern. Force the autoload into
	# a known state so the "no spot at default shipping" assertion is
	# unambiguous.
	gd.lifetime_items_shipped = 0
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	# Also assert it's NOT in Main.tscn (would mean someone hard-coded it).
	var tscn_text: String = FileAccess.get_file_as_string("res://scenes/core/Main.tscn")
	_check(not tscn_text.contains("[node name=\"CoastalTradingPost\""),
		"CoastalTradingPost is NOT hard-authored in Main.tscn (dynamic only)")
	_check(main.get_node_or_null("CoastalTradingPost") == null,
		"CoastalTradingPost absent at default lifetime_items_shipped=0")
	_check(int(gd.lifetime_items_shipped) == 0, "lifetime_items_shipped starts at 0 for this test")
	# 2) Setting shipped to 200 and emitting one minute_ticked tick — the
	# spot should appear (lazy unlock via Main's minute_ticked handler).
	gd.lifetime_items_shipped = 200
	sb.minute_ticked.emit(1, 6, 0)
	await process_frame
	var post: Node = main.get_node_or_null("CoastalTradingPost")
	_check(post != null, "CoastalTradingPost appears after lifetime_items_shipped=200 + minute_ticked")
	# 3) Fresh boot with shipped already at 200: a brand-new Main instance
	# must show the spot immediately, no tick required (proves the
	# _ready() call path covers loaded saves).
	main.queue_free()
	await process_frame
	gd.lifetime_items_shipped = 200
	var main2: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main2)
	await process_frame
	await process_frame
	var post2: Node = main2.get_node_or_null("CoastalTradingPost")
	_check(post2 != null, "fresh boot with shipped=200 shows CoastalTradingPost immediately (no tick needed)")
	# 4) Real InteractArea — this project has twice shipped the
	# @onready $InteractArea null-bug; do not repeat it.
	if post2 == null:
		await process_frame
		quit(1)
		return
	_check(post2.get("_area") != null, "CoastalTradingPost._area is a real Area2D (not null)")
	var area: Node = post2.get("_area")
	if area != null:
		_check(area.get_class() == "Area2D", "InteractArea is an Area2D node")
		var has_circle: bool = false
		for child: Node in area.get_children():
			if child is CollisionShape2D and child.shape is CircleShape2D:
				var cs: CircleShape2D = child.shape
				if is_equal_approx(cs.radius, 56.0):
					has_circle = true
					break
		_check(has_circle, "InteractArea has CollisionShape2D with CircleShape2D radius 56")
	# Spot should be at tile (16, 6) — spec-verified-clear position via
	# headless ground_at() probe (plantable_soil, near market cluster).
	var pos: Vector2 = (post2 as Node2D).position
	_check(is_equal_approx(pos.x, 16 * 48 + 24) and is_equal_approx(pos.y, 6 * 48),
		"CoastalTradingPost positioned at coast lane (792, 288)")
	# 5) Soft-fail when nothing sellable is held. trade() returns false,
	# nothing is removed from inventory, nothing added to silver,
	# lifetime_items_shipped is unchanged.
	gd.inventory.clear()
	gd.silver = 0
	var pre_shipped: int = int(gd.lifetime_items_shipped)
	var pre_inv_size: int = gd.inventory.size()
	var traded_empty: bool = post2.call("trade")
	_check(traded_empty == false, "trade() soft-fails when nothing sellable is held")
	_check(gd.inventory.size() == pre_inv_size,
		"soft-fail leaves inventory untouched (size %d == %d)" % [gd.inventory.size(), pre_inv_size])
	_check(int(gd.silver) == 0, "soft-fail leaves silver at 0")
	_check(int(gd.lifetime_items_shipped) == pre_shipped,
		"soft-fail leaves lifetime_items_shipped unchanged (%d)" % pre_shipped)
	# 6) Construct an inventory with 2+ sellable items of different value
	# and confirm the higher-priced one is chosen and sold at the
	# "coastal" rate specifically, i.e. price == ceil(base * 1.25),
	# NOT the base / market / specialty rate.
	# Items:
	#   mango (base 5)         -> coastal ceil(5*1.25)=7, market ceil(5*1.15)=6, specialty ceil(5*1.45)=8
	#   durian (base 8)        -> coastal ceil(8*1.25)=10, market ceil(8*1.15)=10, specialty ceil(8*1.45)=12
	#   massaman_curry (base 24)-> coastal ceil(24*1.25)=30, market ceil(24*1.15)=28, specialty ceil(24*1.45)=35
	# mango+massaman_curry gives the cleanest spread: priciest is massaman,
	# base 24, coastal 30, market 28, specialty 35.
	gd.inventory.clear()
	gd.silver = 0
	gd.lifetime_items_shipped = 0
	gd.add_item("mango", 1)
	gd.add_item("massaman_curry", 1)
	var pre_wallet: int = int(gd.silver)
	var pre_mango: int = int(gd.inventory.get("mango", 0))
	var pre_curry: int = int(gd.inventory.get("massaman_curry", 0))
	var traded: bool = post2.call("trade")
	_check(traded == true, "trade() returns true when sellable items are held")
	# massaman_curry (base 24) is the priciest: it should have been
	# removed, mango (base 5) should remain untouched.
	_check(int(gd.inventory.get("massaman_curry", 0)) == pre_curry - 1,
		"priciest item (massaman_curry, base 24) was sold: %d -> %d" % [
			pre_curry, int(gd.inventory.get("massaman_curry", 0))])
	_check(int(gd.inventory.get("mango", 0)) == pre_mango,
		"cheaper item (mango, base 5) was NOT sold: still (%d)" % pre_mango)
	# Silver gained must equal the "coastal" rate, NOT base / market /
	# specialty:
	#   base      : 24
	#   market    : ceil(24 * 1.15) = 28
	#   coastal   : ceil(24 * 1.25) = 30  <-- what we want
	#   specialty : ceil(24 * 1.45) = 35
	var gained: int = int(gd.silver) - pre_wallet
	_check(gained == 30,
		"silver gained equals coastal rate ceil(24*1.25)=30 (got %d)" % gained)
	_check(gained != 24, "silver gained is NOT base rate 24 (got %d)" % gained)
	_check(gained != 28, "silver gained is NOT market rate ceil(24*1.15)=28 (got %d)" % gained)
	_check(gained != 35, "silver gained is NOT specialty rate ceil(24*1.45)=35 (got %d)" % gained)
	# lifetime_items_shipped should have ticked up by 1 (sell_item_premium
	# counts toward it, just like the cart/market/specialty channels).
	_check(int(gd.lifetime_items_shipped) == 1,
		"lifetime_items_shipped incremented by 1 after coastal trade (got %d)" % int(gd.lifetime_items_shipped))
	# 7) Construct an inventory where the highest-priced item is a
	# cheaper mango (after the curry was sold above). Verify the
	# priciest-held-item is still being selected (not stale), and that
	# the rate stays at coastal (not e.g. changing because mango is
	# cheaper).
	gd.inventory.clear()
	gd.silver = 0
	gd.add_item("rice_grain", 1) # base 2, cheap
	gd.add_item("egg", 1)        # base 4
	gd.add_item("mango", 1)      # base 5, priciest here
	var pre_wallet2: int = int(gd.silver)
	var pre_mango2: int = int(gd.inventory.get("mango", 0))
	var pre_egg2: int = int(gd.inventory.get("egg", 0))
	var pre_rice2: int = int(gd.inventory.get("rice_grain", 0))
	var traded2: bool = post2.call("trade")
	_check(traded2 == true, "trade() returns true for the next priciest item")
	# mango (base 5) is the priciest here; coastal ceil(5*1.25)=7.
	_check(int(gd.inventory.get("mango", 0)) == pre_mango2 - 1,
		"new priciest item (mango, base 5) was sold: %d -> %d" % [
			pre_mango2, int(gd.inventory.get("mango", 0))])
	_check(int(gd.inventory.get("egg", 0)) == pre_egg2,
		"cheaper item (egg, base 4) was NOT sold: still %d" % pre_egg2)
	_check(int(gd.inventory.get("rice_grain", 0)) == pre_rice2,
		"cheapest item (rice_grain, base 2) was NOT sold: still %d" % pre_rice2)
	# Silver gained at coastal rate: ceil(5*1.25)=7.
	var gained2: int = int(gd.silver) - pre_wallet2
	_check(gained2 == 7,
		"silver gained equals coastal rate ceil(5*1.25)=7 (got %d)" % gained2)
	main2.queue_free()
	print("\n=== COASTAL TRADING POST TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("COASTAL TRADING POST GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)