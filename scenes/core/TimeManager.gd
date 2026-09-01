extends Node
# TimeManager — Drives day/hour/minute ticks, seasonal rotation, and weather.
# Attach to scenes/core/TimeManager.tscn (Node with this script).
# Emits via SignalBus: minute_ticked, season_changed, weather_changed

## Config
@export var minutes_per_real_second: float = 6.0  # 10 real sec = 1 game hour
@export var start_hour: int = 6  # 06:00 dawn
@export var start_day: int = 1
@export var season_duration_days: int = 30 # 90 days/year, genre-standard pacing (Stardew-class: ~112/year)
@export var auto_tick: bool = true

## Time state
var day: int = 1
var hour: int = 6
var minute: int = 0
var _accum_minutes: float = 0.0

## Season / weather
# Thai seasons: hot (Ruedu Ron), monsoon (Ruedu Fon), cool (Ruedu Nao)
var seasons: Array[String] = ["hot", "monsoon", "cool"]
var current_season: String = "cool"
var _days_in_season: int = 0

var weathers: Array[String] = ["clear", "overcast", "rain", "fog"]
var current_weather: String = "clear"

# Stamina drain multipliers per spec (Hot 1.3x, Monsoon/Cool variants)
var stamina_drain_multiplier: float = 1.0

func _ready() -> void:
	day = start_day
	hour = start_hour
	minute = 0
	_apply_season_effects()
	SignalBus.time_manager = self
	# Emit initial state so listeners can sync on load
	SignalBus.minute_ticked.emit(day, hour, minute)
	SignalBus.season_changed.emit(current_season)
	SignalBus.weather_changed.emit(current_weather)

func _exit_tree() -> void:
	if SignalBus.time_manager == self:
		SignalBus.time_manager = null

func _process(delta: float) -> void:
	if not auto_tick:
		return
	_accum_minutes += delta * minutes_per_real_second
	while _accum_minutes >= 1.0:
		_accum_minutes -= 1.0
		_advance_minute()

func _advance_minute() -> void:
	minute += 1
	if minute >= 60:
		minute = 0
		hour += 1
		if hour >= 24:
			hour = 0
			day += 1
			_days_in_season += 1
			if _days_in_season >= season_duration_days:
				_rotate_season()
			_update_weather_for_new_day()
	SignalBus.minute_ticked.emit(day, hour, minute)
	# TASK-034: day-night fraction for the grade-shader consumer (live again).
	var frac := (hour * 60.0 + minute) / 1440.0
	SignalBus.day_night_cycle_changed.emit(frac)

func _rotate_season() -> void:
	_days_in_season = 0
	var idx := seasons.find(current_season)
	var next_idx := (idx + 1) % seasons.size() if idx != -1 else 0
	current_season = seasons[next_idx]
	GameData.current_season = current_season
	_apply_season_effects()
	SignalBus.season_changed.emit(current_season)

func _apply_season_effects() -> void:
	match current_season:
		"hot":
			stamina_drain_multiplier = 1.3
			current_weather = "clear"
		"monsoon":
			stamina_drain_multiplier = 0.8
			current_weather = "rain"
		"cool":
			stamina_drain_multiplier = 1.0
			current_weather = "fog" if randf() < 0.25 else "clear"
		_:
			stamina_drain_multiplier = 1.0
	SignalBus.weather_changed.emit(current_weather)
	if has_node("/root/GameData"):
		GameData.current_weather = current_weather

func _update_weather_for_new_day() -> void:
	# Light daily weather variation within season
	match current_season:
		"hot":
			current_weather = "clear" if randf() < 0.85 else "overcast"
		"monsoon":
			current_weather = "rain" if randf() < 0.6 else "overcast"
		"cool":
			current_weather = "fog" if randf() < 0.2 else "clear"
	SignalBus.weather_changed.emit(current_weather)
	GameData.current_weather = current_weather

# Public API
func set_time(p_day: int, p_hour: int, p_minute: int) -> void:
	day = p_day
	hour = clamp(p_hour, 0, 23)
	minute = clamp(p_minute, 0, 59)
	SignalBus.minute_ticked.emit(day, hour, minute)

func set_season(season: String) -> void:
	if season not in seasons:
		push_warning("TimeManager: unknown season '%s'" % season)
		return
	current_season = season
	_days_in_season = 0
	GameData.current_season = current_season
	_apply_season_effects()
	SignalBus.season_changed.emit(current_season)

func is_morning_bin_thabat_window() -> bool:
	# Binthabat: 05:00 - 07:30
	var total := hour * 60 + minute
	return total >= 5 * 60 and total <= 7 * 60 + 30

func get_stamina_multiplier() -> float:
	return stamina_drain_multiplier

## TASK-292: day within the current season (1..season_duration_days).
## Festivals must key on this, not the absolute day, or they fire exactly
## once per save game.
func day_of_season() -> int:
	return ((day - 1) % maxi(season_duration_days, 1)) + 1

## TASK-292: current year (1-based), derived from absolute day.
func year() -> int:
	var season_length: int = maxi(season_duration_days, 1) * maxi(seasons.size(), 1)
	return int((day - 1) / float(season_length)) + 1

func get_day_fraction() -> float:
	return (hour * 60.0 + minute) / 1440.0
