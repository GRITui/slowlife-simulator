extends SceneTree
# TASK-031 mobile perf budget gate (headless-safe).
# Run: godot --headless --path . --script res://tests/perf/test_mobile_budget.gd
# On device/real renderer this asserts the draw-call ceiling; headless the
# dummy renderer reports 0 draws, so the ceiling check is trivially green and
# the structural checks (ring bake parity, sprite count) carry the gate.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  perf-budget :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  perf-budget :: %s" % label)

func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/core/Main.tscn")
	_check(main_scene != null, "Main.tscn loads")
	var main: Node = main_scene.instantiate() if main_scene else null
	if main:
		root.add_child(main)
		await process_frame
		await process_frame
		var wr: Node = main.get_node_or_null("WorldRender")
		_check(wr != null, "WorldRender present")
		if wr:
			# Ring bake parity: 76 tiles, single sprite (1 draw, was 76).
			_check(wr.ring_count() == 76, "ring_count parity == 76 after bake")
			var ring: Node = main.get_node_or_null("BambooRing")
			_check(ring != null and ring.get_child_count() == 0,
				"BambooRing is a single baked sprite (0 children)")
			# Y-sort budget: visible actors/props (z>=0) <= 32, excluding
			# ground dressing (z<0) and logic containers.
			var sorted_kids: int = 0
			for c in main.get_children():
				if c is Node2D and (c as Node2D).z_index >= 0:
					var cn: String = String(c.get("name"))
					if cn == "WorldRender" or cn == "Bounds" or cn == "GridManager":
						continue
					sorted_kids += 1
			_check(sorted_kids <= 32, "y-sorted participants <= 32 (got %d)" % sorted_kids)
		# Draw-call ceiling (meaningful on device; headless reports 0).
		var draws: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		_check(draws <= 120, "idle draw calls <= 120 budget (got %d)" % draws)
		main.queue_free()
	print("\n=== PERF-BUDGET TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("PERF BUDGET GATE FAILED: %d failing checks" % _failed)
	await process_frame
	quit(1 if _failed > 0 else 0)
