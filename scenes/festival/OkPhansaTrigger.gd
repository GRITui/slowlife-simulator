extends Node
## OkPhansaTrigger — TASK-330 Ok Phansa, end of the rains retreat (monsoon
## season, day 28). FestivalManager pattern (TASK-040): subscribes to
## minute_ticked via the time_manager registry, fires once per monsoon-
## season festival day. Illuminated boat procession on the canal — light
## on the water, not offerings released (distinct from Loy Krathong).
## Flavor-only dialogue (Songkran shape minus the particle spawn; no new
## item or economy surface in scope).

@export var festival_day: int = 28
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
	# Candlelit boats launch after dark — gate on 18:00-22:00 window.
	if hour < 18 or hour >= 22:
		return
	var tm_local: Node = SignalBus.time_manager
	var year: int = tm_local.year() if tm_local != null and tm_local.has_method("year") else 1
	var key: String = "%d-%s" % [year, season]
	if _triggered_keys.has(key):
		return
	_triggered_keys[key] = true
	SignalBus.festival_triggered.emit("ok_phansa")
	SignalBus.show_dialogue.emit("Elder", "Ok Phansa — the boats wear lanterns on the canal tonight.")
	SignalBus.show_dialogue.emit("Monk", "Three months of rains have passed. Carry the light gently; the water carries it farther.")
