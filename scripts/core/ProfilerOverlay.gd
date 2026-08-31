extends CanvasLayer
# ProfilerOverlay — ENGINE-004 render QA + profiler hook (@profiler-inspector)
# Headless-safe: uses Performance monitors, toggles via F3 or --profiler flag.
# Decoupled: no SignalBus dependency; self-contained.

var _visible_profiler: bool = false
var _label: Label
var _accum: float = 0.0

func _ready() -> void:
	layer = 100
	visible = _visible_profiler
	# CLI flag: --profiler enables overlay on start (useful for QA screenshots)
	if "--profiler" in OS.get_cmdline_user_args():
		_visible_profiler = true
		visible = true
	# Build label
	_label = Label.new()
	_label.name = "ProfilerLabel"
	_label.position = Vector2(8, 8)
	_label.add_theme_font_size_override("font_size", 10)
	_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	# Semi-transparent background via Panel behind label
	var bg := ColorRect.new()
	bg.name = "ProfilerBG"
	bg.color = Color(0, 0, 0, 0.55)
	bg.size = Vector2(220, 72)
	bg.position = Vector2(4, 4)
	add_child(bg)
	add_child(_label)
	_update_text()

func _process(delta: float) -> void:
	_accum += delta
	if _accum < 0.5:
		return
	_accum = 0.0
	if _visible_profiler:
		_update_text()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		_visible_profiler = not _visible_profiler
		visible = _visible_profiler
		if _visible_profiler:
			_update_text()

func _update_text() -> void:
	if _label == null:
		return
	var fps: float = Performance.get_monitor(Performance.TIME_FPS)
	var proc: float = Performance.get_monitor(Performance.TIME_PROCESS)
	var phys: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	var mem_static: float = Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0
	var obj_count: int = Performance.get_monitor(Performance.OBJECT_COUNT)
	var draw_calls: int = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME) if Performance.has_method("get_monitor") else 0
	_label.text = "FPS %d | proc %.3fms phys %.3fms\nMem %.1fMB | Objs %d | Draw %d\nZoom %.1f | Y-sort %s" % [
		int(fps), proc * 1000.0, phys * 1000.0, mem_static, obj_count, draw_calls,
		_get_camera_zoom(), _get_y_sort_status()
	]

func _get_camera_zoom() -> float:
	var cam := _find_camera()
	if cam and "zoom" in cam:
		return cam.zoom.x
	return 0.0

func _get_y_sort_status() -> String:
	var main: Node = get_tree().current_scene if get_tree() else null
	if main and "y_sort_enabled" in main:
		return "on" if main.y_sort_enabled else "off"
	return "?"

func _find_camera() -> Camera2D:
	var tree := get_tree()
	if tree == null:
		return null
	# Player's Camera2D is the active gameplay camera
	var scene: Node = tree.current_scene
	if scene:
		var p: Node = scene.find_child("Player", true, false) if scene.has_method("find_child") else null
		if p:
			var cam: Node = p.get_node_or_null("Camera2D")
			if cam is Camera2D:
				return cam as Camera2D
		var cam_direct: Node = scene.find_child("Camera2D", true, false) if scene.has_method("find_child") else null
		if cam_direct is Camera2D:
			return cam_direct as Camera2D
	return null

func is_visible_profiler() -> bool:
	return _visible_profiler
