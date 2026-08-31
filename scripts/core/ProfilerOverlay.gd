extends CanvasLayer
# TASK-041 — debug-only live perf probe (draw calls / texture mem / FPS).
# Activated by --profiler cmdline OR F3 toggle; no-op in release builds.

const REFRESH_INTERVAL: float = 0.5
const ENABLED_BY_DEFAULT: bool = false

var enabled: bool = ENABLED_BY_DEFAULT
var _accum: float = 0.0
@onready var _label: Label = $Label if has_node("Label") else null

func _ready() -> void:
	if not OS.is_debug_build():
		visible = false
		set_process(false)
		return
	if not has_node("Label"):
		var lbl: Label = Label.new()
		lbl.name = "Label"
		lbl.position = Vector2(12, 12)
		add_child(lbl)
		_label = lbl
	enabled = ENABLED_BY_DEFAULT or "--profiler" in OS.get_cmdline_user_args()
	visible = enabled

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		enabled = not enabled
		visible = enabled

func _process(_delta: float) -> void:
	if not enabled or _label == null:
		return
	_accum += _delta
	if _accum < REFRESH_INTERVAL:
		return
	_accum = 0.0
	_refresh_label()

func _refresh_label() -> void:
	if _label == null:
		return
	var draws: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var tex_mb: float = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED) / 1048576.0
	_label.text = "FPS:%d DRAW:%d TEX:%.1fMB" % [Engine.get_frames_per_second(), draws, tex_mb]
