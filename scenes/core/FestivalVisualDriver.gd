extends CanvasLayer
## FestivalVisualDriver — TASK-103. Bus-only: on SignalBus.festival_triggered,
## shows the pond glow overlay and bursts the lantern particles for a fixed
## duration, then hides again. Gives festival_triggered its first production
## listener. No game-state mutation, no core logic touched.

const GLOW_DURATION: float = 30.0

@onready var _glow: ColorRect = $"../PondGlowLayer/PondGlowRect" if has_node("../PondGlowLayer/PondGlowRect") else null
@onready var _lanterns: GPUParticles2D = $"../WorldRender/FestivalLanterns" if has_node("../WorldRender/FestivalLanterns") else null
@onready var _timer: Timer = $HideTimer if has_node("HideTimer") else null

func _ready() -> void:
	SignalBus.festival_triggered.connect(_on_festival_triggered)
	if _timer:
		_timer.timeout.connect(_on_hide_timeout)

func _on_festival_triggered(_festival_name: String) -> void:
	if _glow:
		_glow.visible = true
	if _lanterns:
		_lanterns.emitting = true
	if _timer:
		_timer.start(GLOW_DURATION)

func _on_hide_timeout() -> void:
	if _glow:
		_glow.visible = false
	if _lanterns:
		_lanterns.emitting = false
