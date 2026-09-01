extends Node
## WanSartTrigger — TASK-055 (#113) Wan Sart, ancestor-honoring festival
## (cool season, day 5). FestivalManager pattern (Loy Krathong/Songkran).
## Offering: craftable wan_sart_basket (banana_leaf + rice_grain) then
## release at the temple lane for harmony — same shape as krathong flow.

@export var festival_day: int = 5
var _triggered_keys: Dictionary = {}

func _ready() -> void:
	add_to_group("festival_manager")
	SignalBus.minute_ticked.connect(_on_minute_ticked)

func _exit_tree() -> void:
	if SignalBus.minute_ticked.is_connected(_on_minute_ticked):
		SignalBus.minute_ticked.disconnect(_on_minute_ticked)

func _on_minute_ticked(day: int, hour: int, _minute: int) -> void:
	var season: String = "cool"
	var tm: Node = SignalBus.time_manager
	var dos: int = festival_day
	if tm != null and "current_season" in tm:
		season = String(tm.current_season)
		if tm.has_method("day_of_season"):
			dos = int(tm.day_of_season())
	if season != "cool" or dos != festival_day:
		return
	if hour < 6 or hour >= 12: # morning honoring window
		return
	var tm_local: Node = SignalBus.time_manager
	var year: int = tm_local.year() if tm_local != null and tm_local.has_method("year") else 1
	var key: String = "%d-%s" % [year, season]
	if _triggered_keys.has(key):
		return
	_triggered_keys[key] = true
	SignalBus.festival_triggered.emit("wan_sart")
	SignalBus.show_dialogue.emit("Elder", "Wan Sart — lay an offering for those who tended these fields before us.")

## Crafting recipe injected into the seasonal offer flow via recipes.json;
## this helper is the release interaction (mirror of release_krathong).
func release_offering() -> void:
	if not GameData.has_item("wan_sart_basket", 1):
		SignalBus.show_dialogue.emit("Elder", "Prepare a wan sart basket — banana leaf and rice.")
		return
	GameData.remove_item("wan_sart_basket", 1)
	GameData.add_harmony(8)
	SignalBus.show_dialogue.emit("Elder", "The offering is laid. The ancestors remember. (+8 harmony)")
