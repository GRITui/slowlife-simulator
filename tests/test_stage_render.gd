extends SceneTree
# TASK-045 stage rendering gate — stage_textures finally consumed.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  stage-render :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  stage-render :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var gm: Node = main.get_node_or_null("GridManager")
	_check(gm != null, "GridManager present")
	if gm == null:
		await process_frame
		quit(1)
		return
	var crop: Resource = load("res://data/crops/jasmine_rice.tres")
	var cell := Vector2i(6, 5)
	_check(gm.plant(cell, crop), "plant at (6,5)")
	var sprite: Sprite2D = gm._stage_sprites.get(cell) as Sprite2D
	var ps: Variant = gm.plots[cell] # GridManager.PlotState inner class
	_check(sprite != null, "stage sprite created on plant")
	if sprite != null:
		var tex0: Texture2D = sprite.texture
		_check(tex0 == crop.stage_textures[0], "stage 0 texture bound")
		# Advance two stages via internal state (mirrors minute-tick path).
		ps.stage = 2
		gm._set_stage_sprite(cell, ps)
		_check(sprite.texture == crop.stage_textures[2], "stage 2 texture swaps")
	# Harvest frees the sprite (non-regrow crop).
	ps.stage = crop.total_stages - 1
	gd.add_item("seed_rice", 0) # no-op guard
	gm._set_stage_sprite(cell, ps)
	var y: int = gm.harvest(cell)
	_check(y >= 1, "harvest succeeds")
	_check(gm._stage_sprites.has(cell) == false, "sprite freed on harvest")
	main.queue_free()
	print("\n=== STAGE-RENDER TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("STAGE-RENDER GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
