extends CanvasLayer
## RainDriver — TASK-038. Bus-only: toggles the rain GPUParticles2D based on
## SignalBus.weather_changed. No new signals, no core logic touched.
##
## FIX (owner-confirmed, 2026-09-03): previously gated on
## SignalBus.season_changed / season == "monsoon", so the rain VFX played
## on every monsoon day regardless of that day's actual weather roll --
## including the ~40% of monsoon days TimeManager rolls as "overcast", not
## "rain". Weather (not season) is the correct signal: it already carries
## exactly the "clear"/"overcast"/"rain"/"fog" distinction this driver
## needs, and reacting to it instead means the rain VFX now only plays on
## days the weather actually is rain (which happens to occur only in
## monsoon season already, since _roll_daily_weather() never rolls "rain"
## for hot/cool).

@onready var _rain: GPUParticles2D = $RainParticles if has_node("RainParticles") else null

func _ready() -> void:
	if _rain == null:
		return
	SignalBus.weather_changed.connect(_on_weather)
	var initial: String = GameData.current_weather if "current_weather" in GameData else "clear"
	_on_weather(initial)

func _on_weather(weather: String) -> void:
	if _rain:
		_rain.emitting = (weather == "rain")
