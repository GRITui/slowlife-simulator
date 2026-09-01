extends CanvasLayer
## HeatHazeDriver — TASK-040. Bus-only: shows/hides the hot-season heat-haze
## overlay based on SignalBus.season_changed. Same shape as SeasonShaderDriver
## / DayNightTintDriver; no new signals, no core logic touched.

@onready var _haze: ColorRect = $"../HazeLayer/HazeRect" if has_node("../HazeLayer/HazeRect") else null

func _ready() -> void:
	if _haze == null:
		return
	SignalBus.season_changed.connect(_on_season)
	var initial: String = GameData.current_season if "current_season" in GameData else "cool"
	_on_season(initial)

func _on_season(season: String) -> void:
	if _haze:
		_haze.visible = (season == "hot")
