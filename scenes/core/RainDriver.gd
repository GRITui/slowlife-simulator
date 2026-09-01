extends CanvasLayer
## RainDriver — TASK-038. Bus-only: toggles the Monsoon rain GPUParticles2D
## based on SignalBus.season_changed. No new signals, no core logic touched.

@onready var _rain: GPUParticles2D = $RainParticles if has_node("RainParticles") else null

func _ready() -> void:
	if _rain == null:
		return
	SignalBus.season_changed.connect(_on_season)
	var initial: String = GameData.current_season if "current_season" in GameData else "cool"
	_on_season(initial)

func _on_season(season: String) -> void:
	if _rain:
		_rain.emitting = (season == "monsoon")
