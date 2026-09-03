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
# TASK-355: one-day-ahead forecast. Populated lazily on _ready() and on
# every day-rollover. Becomes `current_weather` on the next rollover —
# so a forecast a player sees at 22:00 describes what the sky will
# actually be when they wake up at 06:00 tomorrow. The forecast is
# rerolled under the new season if a season boundary happens to fall
# between the roll and the day it describes (rare; ~1/30 days).
var next_weather: String = ""

# Stamina drain multipliers per spec (Hot 1.3x, Monsoon/Cool variants)
var stamina_drain_multiplier: float = 1.0

func _ready() -> void:
	day = start_day
	hour = start_hour
	minute = 0
	_apply_season_effects()
	SignalBus.time_manager = self
	# TASK-355: roll the first forecast AFTER the initial season is set,
	# so the very first next_weather already reflects the current season's
	# odds instead of an empty string.
	next_weather = _roll_daily_weather(current_season)
	SignalBus.weather_forecast_changed.emit(next_weather)
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
			# TASK-280: veteran year rolls over (GameData synced lazily).
			GameData.veteran_year = year()
			_days_in_season += 1
			if _days_in_season >= season_duration_days:
				_rotate_season()
				# TASK-355: season just changed — yesterday's forecast was
				# rolled under the OLD season's odds and is now stale;
				# reroll under the new season so the "final" weather
				# value for today matches this codebase's pre-forecast
				# behavior exactly (today's weather has always reflected
				# whatever season is current AFTER rotation, not before).
				next_weather = _roll_daily_weather(current_season)
				SignalBus.weather_forecast_changed.emit(next_weather)
			# TASK-355: today's weather is whatever was forecast for it
			# yesterday (genuine 1-day-ahead accuracy on normal days).
			current_weather = next_weather
			SignalBus.weather_changed.emit(current_weather)
			GameData.current_weather = current_weather
			# Roll TOMORROW's forecast now, using whatever season is
			# current today (post-rotation if we just rotated).
			next_weather = _roll_daily_weather(current_season)
			SignalBus.weather_forecast_changed.emit(next_weather)
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
	# TASK-355: kept as a thin shim for any legacy caller (the rollover
	# branch in _advance_minute no longer uses it directly — it composes
	# `_roll_daily_weather()` with the next_weather -> current_weather
	# swap so the forecast a player saw yesterday becomes today's
	# actual weather). The probabilities are unchanged.
	current_weather = _roll_daily_weather(current_season)
	SignalBus.weather_changed.emit(current_weather)
	GameData.current_weather = current_weather

# TASK-355: pure per-season daily weather roll. NO side effects — just
# returns a weather string using the EXACT same match-statement odds
# _update_weather_for_new_day() used before the forecast refactor
# (owner explicitly confirmed: carry the current odds forward
# unchanged). Called by _ready() (initial forecast), _advance_minute()
# rollover branch (post-season-change reroll + tomorrow's forecast),
# and any caller that wants to know what a given season tends to
# produce without mutating current_weather.
func _roll_daily_weather(season: String) -> String:
	match season:
		"hot":
			return "clear" if randf() < 0.85 else "overcast"
		"monsoon":
			return "rain" if randf() < 0.6 else "overcast"
		"cool":
			return "fog" if randf() < 0.2 else "clear"
	# Unknown season: fall back to the same safe default _update_weather
	# used to leave current_weather at (i.e., don't touch it). Matches
	# the pre-refactor behavior where an unknown season simply skipped
	# the match.
	return current_weather

# Public API
func set_time(p_day: int, p_hour: int, p_minute: int) -> void:
	day = p_day
	hour = clamp(p_hour, 0, 23)
	minute = clamp(p_minute, 0, 59)
	SignalBus.minute_ticked.emit(day, hour, minute)

# TASK-355: bed/sleep "skip to tomorrow morning" — like the rollover
# branch in _advance_minute(), but on demand. The brief warned NOT to
# use set_time() for this (raw setter, no side effects — would skip
# the season check + weather roll). This method drives the same
# sequence of side effects as a passive minute-tick rollover at
# 23:59, then pins the clock to (day+1, target_hour, 0). Order
# matters: advance to a fresh day FIRST (so the rollover branch's
# season-check + next_weather->current_weather flip + new
# next_weather roll all fire), THEN snap the clock to the requested
# wake-up hour. The single minute_ticked emit at the end is what
# HUD/day-night-tint drivers observe.
func advance_to_next_day(target_hour: int = 6) -> void:
	# Set hour just past midnight (25 > 23) so _advance_minute()'s
	# rollover branch fires exactly once and walks the same
	# season-check + weather swap path the passive tick uses.
	hour = 23
	minute = 59
	# One forced minute-tick rollover — identical sequence to the
	# passive path; preserves all TASK-355 forecast semantics.
	_advance_minute()
	# _advance_minute() left us at (day+1, 0, 0). Snap to the
	# requested wake-up hour so the player "woke up at 06:00".
	hour = clamp(target_hour, 0, 23)
	minute = 0
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
