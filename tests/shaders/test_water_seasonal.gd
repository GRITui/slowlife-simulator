extends SceneTree
# TASK-032 shader wiring gate (headless-safe structural checks).
# NOTE: pixel-level hue anchors / hash-diff (spec "Unit"/"Visual" sections)
# require a real renderer — verify on device per spec's Manual row; headless
# dummy RD cannot rasterize canvas shaders, so this gate asserts the wiring
# contract: resources compile-load, materials attach, uniforms map seasons.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  shaders :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  shaders :: %s" % label)

func _initialize() -> void:
	var ws: Shader = load("res://assets/shaders/water_seasonal.gdshader") as Shader
	var fs: Shader = load("res://assets/shaders/foliage_sway.gdshader") as Shader
	_check(ws != null and ws.get_rid().is_valid(), "water_seasonal.gdshader compiles/loads")
	_check(fs != null and fs.get_rid().is_valid(), "foliage_sway.gdshader compiles/loads")
	var wm: ShaderMaterial = load("res://assets/shaders/water_seasonal.tres") as ShaderMaterial
	_check(wm != null and wm.shader == ws, "water ShaderMaterial bound to shader")
	_check(wm != null and wm.get_shader_parameter("season_index") != null,
		"water season_index uniform present")

	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var wr: Node = main.get_node_or_null("WorldRender")
	_check(wr != null, "WorldRender present")
	var water: TileMapLayer = null
	var ring: Sprite2D = null
	var swayed: int = 0
	var rigid_caps: int = 0
	for c in main.get_children():
		if c is TileMapLayer and String(c.name) == "WaterOverlay":
			water = c
		if c is Sprite2D and String(c.name) == "BambooRing":
			ring = c
		if c is Sprite2D and c.get_meta("worldrender_prop", false):
			if c.material is ShaderMaterial:
				swayed += 1
			else:
				rigid_caps += 1
	_check(water != null and water.material is ShaderMaterial,
		"WaterOverlay carries seasonal material")
	_check(ring != null and ring.material is ShaderMaterial,
		"baked ring carries sway material")
	_check(swayed >= 10 and rigid_caps >= 5 and swayed + rigid_caps == wr.prop_count(),
		"tall props swayed (%d) + rigid caps (%d) == prop_count (%d)" % [swayed, rigid_caps, wr.prop_count()])
	# Season mapping: driver writes 0/1/2 for hot/monsoon/cool.
	if wr.has_method("_apply_season_to_water") and water != null and water.material != null:
		wr._apply_season_to_water("monsoon")
		var m: ShaderMaterial = water.material as ShaderMaterial
		_check(is_equal_approx(float(m.get_shader_parameter("season_index")), 1.0),
			"season driver maps monsoon -> 1.0")
		wr._apply_season_to_water("cool")
		_check(is_equal_approx(float((water.material as ShaderMaterial).get_shader_parameter("season_index")), 2.0),
			"season driver maps cool -> 2.0")
	main.queue_free()
	print("\n=== SHADER TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("SHADER GATE FAILED: %d failing checks" % _failed)
	await process_frame
	quit(1 if _failed > 0 else 0)
