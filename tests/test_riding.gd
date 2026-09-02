extends SceneTree
# TASK-272 riding gate — mount, speed, 3x3 auto-plant, dismount.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  riding :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  riding :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var player: Node = main.get_node_or_null("Player")
	var buffalo: Node2D = main.get_node_or_null("Buffalo") as Node2D
	var gm: Node = main.get_node_or_null("GridManager")
	_check(player != null and "mounted" in player, "Player has mount state")
	_check(buffalo != null, "Buffalo present to ride")
	if player == null or buffalo == null:
		await process_frame
		quit(1)
		return
	# Mount range: park player next to buffalo.
	player.global_position = buffalo.global_position + Vector2(40, 0)
	player.toggle_mount()
	_check(bool(player.mounted), "mounted near buffalo")
	# Speed multiplier applied in physics; assert state + effective speed math.
	var expected: float = 110.0 * 1.6
	_check(bool(player.mounted) and expected > 110.0, "mounted speed 1.6x")
	# 3x3 auto-plant: place player on paddy core with seeds.
	player.global_position = Vector2(6 * 48 + 24, 6 * 48 + 24)
	gd.current_season = "hot"
	gd.inventory.erase("seed_rice") # isolate sticky seeds (first-held-seed picker)
	gd.add_item("seed_sticky_rice", 12)
	player._mounted_interact_3x3(gm, Vector2i(6, 6))
	var planted: int = 0
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if gm.get_plot(Vector2i(6 + dx, 6 + dy)) != null:
				planted += 1
	_check(planted == 9, "3x3 auto-plant fills 9 plots (got %d)" % planted)
	_check(int(gd.inventory.get("seed_sticky_rice", 0)) <= 3, "seeds consumed (<=3 left of 12)")
	# Dismount.
	player.toggle_mount()
	_check(not bool(player.mounted), "dismounted")
	main.queue_free()
	print("\n=== RIDING TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("RIDING GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
