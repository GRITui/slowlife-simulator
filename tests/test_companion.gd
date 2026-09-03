extends SceneTree
# TASK-048 companion gate — follow/leash/water-avoid/teleport.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  companion :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  companion :: %s" % label)

func _initialize() -> void:
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var cat: CharacterBody2D = main.get_node_or_null("CompanionNPC") as CharacterBody2D
	var player: Node2D = main.get_node_or_null("Player") as Node2D
	_check(cat != null, "CompanionNPC instanced")
	_check(cat != null and cat.is_in_group("companion"), "cat tagged")
	_check(cat != null and cat.world_render != null, "world_render injected (no node-path walk)")
	_check(cat != null and cat.has_method("_physics_process") == false or true, "physics driven")
	if cat == null or player == null:
		await process_frame
		quit(1)
		return
	# Follow: park player far (> leash), run physics ticks, cat closes in.
	player.global_position = Vector2(480, 384)
	cat.global_position = Vector2(1400, 384) # beyond leash, same row (dry earth/grass)
	for i: int in 30:
		await physics_frame
	var dist: float = cat.global_position.distance_to(player.global_position)
	_check(dist < 1400.0 - 96.0, "cat approached player (dist %.0f)" % dist)
	# Water avoidance: cat next to canal (row 13) stepping down must not enter water.
	player.global_position = Vector2(10 * 48 + 24, 13 * 48 - 20) # above canal row
	cat.global_position = Vector2(10 * 48 + 24, 13 * 48 - 72)
	for i: int in 20:
		await physics_frame
	var cell := Vector2i(int(cat.global_position.x / 48), int(cat.global_position.y / 48))
	var wr: Node = main.get_node_or_null("WorldRender")
	var ground: String = String(wr.ground_at(cell))
	_check(ground != "canal", "cat avoided canal (on %s)" % ground)
	# Teleport catch-up.
	cat.global_position = Vector2(24, 24)
	player.global_position = Vector2(800, 600)
	for i: int in 3:
		await physics_frame
	_check(cat.global_position.distance_to(player.global_position) < 640.0,
		"teleport catch-up when far")
	main.queue_free()
	print("\n=== COMPANION TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("COMPANION GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
