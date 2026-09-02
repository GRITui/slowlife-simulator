extends Node
## FishingCompetitionTrigger — TASK-319 Fishing competition festival (hot season, day 15).
## FestivalManager pattern: subscribes to minute_ticked, fires once per hot-season festival day,
## requires fishing skill >=2, spawns competition banner. Zero-combat celebration.
##
## TASK-336 — added real scored competition loop: while the 10:00-16:00 window
## is open, every fish catch (SignalBus.craft_completed with a `pla_` item_id)
## contributes points (1 small / 2 mid / 3 big) to _player_score. At the end of
## the window a rival score (randi_range(2, 8)) is rolled and the player is
## placed 1st / tied 2nd / participation, all with strictly-positive rewards
## (silver + harmony). No fail state, per project precedent.

@export var festival_day: int = 15
var _triggered_keys: Dictionary = {}
var _competition_active: bool = false
var _player_score: int = 0

func _ready() -> void:
	add_to_group("festival_manager")
	SignalBus.minute_ticked.connect(_on_minute_ticked)
	SignalBus.craft_completed.connect(_on_craft_completed)

func _exit_tree() -> void:
	if SignalBus.minute_ticked.is_connected(_on_minute_ticked):
		SignalBus.minute_ticked.disconnect(_on_minute_ticked)
	if SignalBus.craft_completed.is_connected(_on_craft_completed):
		SignalBus.craft_completed.disconnect(_on_craft_completed)

func _on_minute_ticked(day: int, hour: int, _minute: int) -> void:
	# TASK-336: window-close check must run BEFORE the season/day/hour gate so
	# it still fires once the window itself would otherwise early-return
	# (handles the hour 16:00 tick cleanly and protects against stuck-open
	# state across a save/load or day skip).
	if _competition_active and _is_past_window(day, hour):
		_resolve_competition()
		return
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
	_competition_active = true
	_player_score = 0
	SignalBus.festival_triggered.emit("fishing_competition")
	SignalBus.show_dialogue.emit("Fah", "Fishing competition! Cast your line at the canal — rare catches win big!")

# TASK-336: window close — same festival day past 16:00, OR moved past the
# window entirely (different day, or no longer the festival day-of-season).
func _is_past_window(day: int, hour: int) -> bool:
	var tm: Node = SignalBus.time_manager
	var dos: int = festival_day
	if tm != null and tm.has_method("day_of_season"):
		dos = int(tm.day_of_season())
	if dos != festival_day:
		return true
	return hour >= 16

func _resolve_competition() -> void:
	var rival_score: int = randi_range(2, 8)
	var placement: String = _placement_for(_player_score, rival_score)
	var silver_reward: int = 0
	var harmony_reward: int = 0
	var placement_label: String = ""
	match placement:
		"first":
			silver_reward = 30
			harmony_reward = 10
			placement_label = "First place"
		"tie":
			silver_reward = 15
			harmony_reward = 5
			placement_label = "Second place (tied)"
		_:
			silver_reward = 5
			harmony_reward = 2
			placement_label = "Participation"
	GameData.add_silver(silver_reward)
	GameData.add_harmony(harmony_reward)
	SignalBus.show_dialogue.emit("Fah",
		"Competition's over — you: %d, the field: %d. %s! (+%d silver, +%d harmony)" % [
			_player_score, rival_score, placement_label, silver_reward, harmony_reward])
	# TASK-347: only Fah's own rival (thematically linked to fishing) is
	# nudged — a "first" win pushes the rival's clock back, a
	# "participation" loss (the field/rival won) pushes it forward. A tie
	# does nothing. The other 5 rivals are deliberately unaffected.
	var rc: Node = SignalBus.rival_clock
	if rc != null:
		if placement == "first":
			rc.nudge_progress("fah", -5.0)
		elif placement == "participation":
			rc.nudge_progress("fah", 5.0)
	_competition_active = false
	_player_score = 0

## Pure placement logic extracted so tests can drive tie outcomes deterministically
## without depending on the randi_range rival roll.
func _placement_for(player_score: int, rival_score: int) -> String:
	if player_score > rival_score:
		return "first"
	if player_score == rival_score:
		return "tie"
	return "participation"

func _on_craft_completed(item_id: String, qty: int) -> void:
	if not _competition_active or not item_id.begins_with("pla_"):
		return
	var points: int = 1
	if item_id.ends_with("_big"):
		points = 3
	elif item_id.ends_with("_mid"):
		points = 2
	_player_score += points * qty
