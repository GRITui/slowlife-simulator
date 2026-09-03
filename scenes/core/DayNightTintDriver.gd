extends CanvasLayer
## DayNightTintDriver — TASK-034. Bus-only driver: subscribes to
## SignalBus.day_night_cycle_changed and writes the day-fraction uniform on
## the TintLayer/TintRect overlay material. Inert (visible=false parent logic
## stays with World's seasonal tint) — this adds time-of-day grading on top.

@onready var _tint: ColorRect = $"../TintLayer/TintRect" if has_node("../TintLayer/TintRect") else null

func _ready() -> void:
	if _tint == null:
		return
	var mat: ShaderMaterial = load("res://assets/shaders/day_night_tint.tres") as ShaderMaterial
	if mat == null:
		return
	# Layer the grade under the seasonal tint: grade material on the rect,
	# seasonal ColorRect color continues to modulate via modulate.
	_tint.material = mat
	SignalBus.day_night_cycle_changed.connect(_on_day_fraction)
	# Initial sync from TimeManager registry (no node-path coupling).
	var tm: Node = SignalBus.time_manager
	if tm != null and "get_day_fraction" in tm:
		_on_day_fraction(float(tm.get_day_fraction()))

func _on_day_fraction(fraction: float) -> void:
	if _tint == null or not (_tint.material is ShaderMaterial):
		return
	(_tint.material as ShaderMaterial).set_shader_parameter("day_fraction", clampf(fraction, 0.0, 1.0))
