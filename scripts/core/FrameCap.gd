extends Node
# TASK-042 — battery-aware frame cap. Mobile only; desktop/headless unlimited.
# 30 fps while paused or on the title screen, 60 fps during gameplay.
# Autoload: registers itself via project.godot; reacts to
# SignalBus.game_paused_changed and polls the title-screen state at 1 Hz.

const FPS_GAMEPLAY: int = 60
const FPS_SAVED: int = 30

var _poll_accum: float = 0.0

func _ready() -> void:
	# Headless/CI and desktop stay uncapped (tests rely on unlimited frames).
	if not OS.has_feature("mobile"):
		set_process(false)
		return
	_apply(false)
	SignalBus.game_paused_changed.connect(_apply)

func _process(delta: float) -> void:
	_poll_accum += delta
	if _poll_accum < 1.0:
		return
	_poll_accum = 0.0
	# Title screen case: no pause signal fires there, so poll the flag.
	if not get_tree().paused and _title_up():
		_apply(true)

func _title_up() -> bool:
	var main: Node = get_tree().current_scene
	if main == null or not main.has_method("_is_title_up"):
		return false
	return bool(main.call("_is_title_up"))

func _apply(paused: bool) -> void:
	if not OS.has_feature("mobile"):
		return # desktop/headless passthrough — never touch max_fps
	Engine.max_fps = FPS_SAVED if paused else FPS_GAMEPLAY
