extends Node
## FishingCompetitionTrigger — TASK-319 Fishing competition festival (hot season, day 15).
## FestivalManager pattern: subscribes to minute_ticked, fires once per hot-season festival day,
## requires fishing skill >=2, spawns competition banner. Zero-combat celebration.

@export var festival_day: int = 15
var _triggered_keys: Dictionary = {}

func _ready() -> void:
	add_to_group("festival_manager")
	SignalBus.minute_ticked.connect(_on_minute_ticked)

func _exit_tree() -> void:
	if SignalBus.minute_ticked.is_connected(_on_minute_ticked):
		SignalBus.minute_ticked.disconnect(_on_minute_ticked)

func _on_minute_ticked(day: int, hour: int, _minute: int) -> void:
	var season: String = "hot"
	var tm: Node = SignalBus.time_manager
	var dos: int = festival_day
	if tm != null and "current_season" in tm:
		season = String(tm.current_season)
		if tm.has_method("day_of_season"):
			dos = int(tm.day_of_season())
	elif "current_season" in GameData:
		season = String(GameData.current_season)
	if season != "hot" or dos != festival_day:
		return
	if hour < 10 or hour >= 16:
		return
	var tm_local: Node = SignalBus.time_manager
	var year: int = tm_local.year() if tm_local != null and tm_local.has_method("year") else 1
	var key: String = "%d-%s" % [year, season]
	if _triggered_keys.has(key):
		return
	# Skill gate: need fishing skill 2+ to enter
	if int(GameData.fishing_skill) < 2:
		SignalBus.show_dialogue.emit("Fah", "Fishing competition today at the canal! Come back when you've practiced more (skill 2+).")
		return
	_triggered_keys[key] = true
	SignalBus.festival_triggered.emit("fishing_competition")
	SignalBus.show_dialogue.emit("Fah", "Fishing competition! Cast your line at the canal — rare catches win big!")
