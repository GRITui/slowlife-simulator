extends SceneTree
# TASK-041 profiler-overlay gate — headless-safe structural + format checks.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  profiler :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  profiler :: %s" % label)

func _initialize() -> void:
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var overlay: CanvasLayer = main.get_node_or_null("ProfilerOverlay") as CanvasLayer
	_check(overlay != null, "ProfilerOverlay attached under World")
	if overlay == null:
		main.queue_free()
		print("\n=== PROFILER TESTS: %d passed, %d failed ===" % [_passed, _failed])
		await process_frame
		quit(1)
		return
	_check(overlay.has_method("_refresh_label"), "probe exposes _refresh_label")
	# Enable + force a refresh; verify label contract.
	overlay.enabled = true
	overlay.visible = true
	overlay._accum = 0.5
	overlay._refresh_label()
	var label: Label = overlay.get_node_or_null("Label") as Label
	if label == null:
		# Label lives under the CanvasLayer; create contract check via text var.
		_check(false, "Label child present")
	else:
		_check(label.text.begins_with("FPS:") and label.text.contains("DRAW:") and label.text.contains("TEX:") and label.text.ends_with("MB"),
			"label format 'FPS:n DRAW:n TEX:n.nMB' (got '%s')" % label.text)
		var before: String = label.text
		overlay._accum = 0.1
		overlay._process(0.1)
		_check(label.text == before, "throttle: sub-interval _process keeps label")
		var draws: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		_check(label.text.contains("DRAW:%d" % draws), "draw-call source parity (DRAW:%d)" % draws)
	_check(overlay.get("REFRESH_INTERVAL") != null, "typed constants present")
	main.queue_free()
	print("\n=== PROFILER TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("PROFILER GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
