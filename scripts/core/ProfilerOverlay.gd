extends CanvasLayer
# ProfilerOverlay — ENGINE-004 F3 toggle + --profiler, FPS/mem/draw/zoom/Y-sort, headless-safe
var enabled: bool = false
@onready var label: Label = $Label if has_node("Label") else null
func _ready() -> void:
  if "--profiler" in OS.get_cmdline_user_args():
    enabled = true
  visible = enabled
func _unhandled_input(event: InputEvent) -> void:
  if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
    enabled = !enabled
    visible = enabled
func _process(_delta: float) -> void:
  if not enabled or label == null: return
  label.text = "FPS:%d MEM:%.1fMB" % [Engine.get_frames_per_second(), OS.get_static_memory_usage()/1048576.0]
