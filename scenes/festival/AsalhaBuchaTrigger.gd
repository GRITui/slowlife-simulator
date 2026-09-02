extends Node
## AsalhaBuchaTrigger — TASK-330 Asalha Puja / Wan Asanha Bucha (monsoon
## season, day 5). FestivalManager pattern (TASK-040): subscribes to
## minute_ticked via the time_manager registry, fires once per monsoon-
## season festival day. Evening candle procession marking the start of the
## rains retreat — flavor-only dialogue (Songkran shape minus the particle
## spawn; no new item or economy surface in scope).

@export var festival_day: int = 5
var _triggered_keys: Dictionary = {}

func _ready() -> void:
	add_to_group("festival_manager")
	SignalBus.minute_ticked.connect(_on_minute_ticked)

func _exit_tree() -> void:
	if SignalBus.minute_ticked.is_connected(_on_minute_ticked):
		SignalBus.minute_ticked.disconnect(_on_minute_ticked)

func _on_minute_ticked(day: int, hour: int, _minute: int) -> void:
	var season: String = "monsoon"
	var tm: Node = SignalBus.time_manager
	var dos: int = festival_day
	if tm != null and "current_season" in tm:
		season = String(tm.current_season)
		if tm.has_method("day_of_season"):
			dos = int(tm.day_of_season())
	elif "current_season" in GameData:
		season = String(GameData.current_season)
	if season != "monsoon" or dos != festival_day:
		return
	# Candle procession runs at dusk — gate on 17:00-21:00 window.
	if hour < 17 or hour >= 21:
		return
	var tm_local: Node = SignalBus.time_manager
	var year: int = tm_local.year() if tm_local != null and tm_local.has_method("year") else 1
	var key: String = "%d-%s" % [year, season]
	if _triggered_keys.has(key):
		return
	_triggered_keys[key] = true
	SignalBus.festival_triggered.emit("asalha_bucha")
	SignalBus.show_dialogue.emit("Elder", "Asalha Bucha tonight — bring a candle to the temple before dark.")
	SignalBus.show_dialogue.emit("Monk", "The rains retreat begins. Walk slowly, and let the flame steady the heart.")
