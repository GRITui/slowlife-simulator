extends CanvasLayer
## FogDriver — TASK-365. Bus-only: shows/hides a low-alpha full-screen
## fog overlay based on SignalBus.weather_changed. Mirrors HeatHazeDriver's
## exact shape (CanvasLayer + sibling ColorRect, visible toggle) and listens
## to the same SignalBus.weather_changed string that TimeManager rolls on
## cool-season days (~1 in 5). No new signals, no core logic touched.
##
## Color is intentionally a near-neutral pale haze at low opacity — per the
## project's "screen-space overlay" precedent in TintLayer/TintRect (alpha
## 0.078) and HeatHazeDriver, a full-opacity overlay that hides the world is
## wrong; fog should read as light haze, not a wall.

@onready var _fog: ColorRect = $"../FogLayer/FogRect" if has_node("../FogLayer/FogRect") else null

func _ready() -> void:
	if _fog == null:
		return
	SignalBus.weather_changed.connect(_on_weather)
	var initial: String = GameData.current_weather if "current_weather" in GameData else "clear"
	_on_weather(initial)

func _on_weather(weather: String) -> void:
	if _fog:
		_fog.visible = (weather == "fog")