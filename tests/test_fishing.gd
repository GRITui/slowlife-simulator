extends SceneTree
# TASK-050 fishing gate — eligibility, skill gating, rod gate, catch roll.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  fishing :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  fishing :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var spot: Node = main.get_node_or_null("FishingSpot")
	_check(spot != null, "FishingSpot instanced on canal bank")
	_check(int(gd.get("fishing_skill")) == 1, "fishing_skill starts at 1")
	_check(int(gd.inventory.get("fishing_rod", 0)) >= 1, "rod in starting inventory")
	if spot == null:
		await process_frame
		quit(1)
		return
	# Rod gate.
	gd.inventory.erase("fishing_rod")
	_check(spot.cast_line() == false, "no rod -> soft fail")
	gd.add_item("fishing_rod", 1)
	# Skill gate: level-4 species unreachable at skill 1.
	var elig: Array = spot.eligible_fish()
	_check(not elig.is_empty(), "eligible pool non-empty at skill 1")
	var max_req: int = 0
	for f: Dictionary in elig:
		max_req = maxi(max_req, int(f.get("skill_required", 1)))
	_check(max_req <= 1, "skill 1 sees only skill_required <= 1 (max %d)" % max_req)
	# Season gate: hot season pool excludes cool-only species. Set via the
	# authoritative TimeManager (the spot prefers the registry season).
	var tm2: Node = root.get_node("SignalBus").time_manager
	if tm2 != null:
		tm2.set_season("hot")
	gd.current_season = "hot"
	var hot: Array = spot.eligible_fish()
	for f: Dictionary in hot:
		_check((f.get("seasons", []) as Array).has("hot"), "%s listed hot" % String(f.get("id")))
	# Catch: succeeds, grants item, advances skill over rolls.
	var caught: bool = false
	for i: int in 10:
		if spot.cast_line():
			caught = true
	_check(caught, "cast_line lands a catch within 10 rolls")
	_check(gd.fishing_skill >= 2, "skill grew to %d after 10 rolls" % int(gd.fishing_skill))
	# Caught items exist in the roster sizes.
	var inv_keys: Array = gd.inventory.keys()
	var fish_items: int = 0
	for k: String in inv_keys:
		if k.begins_with("pla_") or k.contains("_small") or k.contains("_mid") or k.contains("_big"):
			fish_items += 1
	_check(fish_items >= 1, "caught fish items in inventory (%d kinds)" % fish_items)
	# Phase 3 audit: real InteractArea now exists (was always null before —
	# see FishingSpot.gd's header comment) so proximity actually works.
	_check(spot.get("_area") != null, "FishingSpot._area is a real Area2D (not null)")
	var player: Node2D = main.get_node_or_null("Player") as Node2D
	if player != null:
		# Simulate the Area2D proximity signal directly — headless has no
		# physics step to reliably drive real body_entered/exited firing.
		spot.call("_on_body_entered", player)
		_check(bool(spot.get("_player_in_range")) == true, "entering the InteractArea sets _player_in_range")
		spot.call("_on_body_exited", player)
		_check(bool(spot.get("_player_in_range")) == false, "exiting the InteractArea clears _player_in_range")
	main.queue_free()
	print("\n=== FISHING TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("FISHING GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
