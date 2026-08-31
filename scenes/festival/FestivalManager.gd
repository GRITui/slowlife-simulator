extends Node
# FestivalManager — TASK-022 Loy Krathong, cozy no-fail, SignalBus.
# TASK-040 (PO_INBOX directive #3): now wired live — instances under Main,
# subscribes to minute_ticked via the time_manager registry, emits
# festival_triggered (spec: docs/research/TASK-022-spec.md).

@export var festival_day: int = 7
var _triggered_seasons: Dictionary = {}

func _ready() -> void:
	add_to_group("festival_manager")
	SignalBus.minute_ticked.connect(_on_minute_ticked)

func _exit_tree() -> void:
	if SignalBus.minute_ticked.is_connected(_on_minute_ticked):
		SignalBus.minute_ticked.disconnect(_on_minute_ticked)

func _on_minute_ticked(day: int, _hour: int, _minute: int) -> void:
	var season: String = "cool"
	var tm: Node = SignalBus.time_manager
	if tm != null and "current_season" in tm:
		season = String(tm.current_season)
	elif "current_season" in GameData:
		season = String(GameData.current_season)
	try_trigger_festival(day, season)

func try_trigger_festival(day: int, season: String) -> bool:
	if season != "cool":
		return false
	if day != festival_day:
		return false
	var key: String = "%d-%s" % [day, season]
	if _triggered_seasons.has(key):
		return false
	_triggered_seasons[key] = true
	SignalBus.festival_triggered.emit("loy_krathong")
	SignalBus.show_dialogue.emit("Elder", "Krathongs drift on the lotus pond tonight.")
	return true

func craft_krathong() -> bool:
	if not GameData.has_item("lotus_root", 1):
		return false
	if not GameData.remove_item("lotus_root", 1):
		return false
	GameData.add_item("krathong", 1)
	SignalBus.show_dialogue.emit("System", "Crafted a krathong (lotus).")
	return true

func release_krathong() -> void:
	if not GameData.has_item("krathong", 1):
		SignalBus.show_dialogue.emit("System", "Need a krathong to release.")
		return
	GameData.remove_item("krathong", 1)
	GameData.add_harmony(5)
	SignalBus.show_dialogue.emit("System", "Krathong released — harmony +5, merit drifts.")
