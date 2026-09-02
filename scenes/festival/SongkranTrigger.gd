extends Node
## SongkranTrigger — TASK-046 Thai New Year water festival (hot season, day 3).
## FestivalManager pattern (TASK-040): subscribes to minute_ticked via the
## time_manager registry, fires once per hot-season festival day, spawns the
## authored splash particle burst at the lotus pond, dialogue via DialogueDB.
## Zero-combat, pure celebration.
##
## TASK-339 — added real scored cooking-contest loop reusing the existing
## 12:00-18:00 window (no new festival day, hot season stays at 2 festivals
## per TASK-330). Every successful craft emitted on SignalBus.craft_completed
## contributes harmony_reward points (only for actual recipe ids from
## data/recipes/recipes.json — the signal is shared with fish/ore catches so
## membership is the only safe filter). At window close a rival score
## (randi_range(4, 14)) is rolled and the player is placed 1st / tied /
## participation, all with strictly-positive rewards (silver + harmony).
## No fail state, matching the fishing contest and project precedent.

const RECIPES_PATH: String = "res://data/recipes/recipes.json"

@export var festival_day: int = 3
var _triggered_keys: Dictionary = {}
var _splash: GPUParticles2D = null
var _recipe_harmony: Dictionary = {} # recipe_id -> harmony_reward, for scoring
var _cook_active: bool = false
var _cook_score: int = 0

func _ready() -> void:
	add_to_group("festival_manager")
	SignalBus.minute_ticked.connect(_on_minute_ticked)
	SignalBus.craft_completed.connect(_on_craft_completed)
	_load_recipes()

func _exit_tree() -> void:
	if SignalBus.minute_ticked.is_connected(_on_minute_ticked):
		SignalBus.minute_ticked.disconnect(_on_minute_ticked)
	if SignalBus.craft_completed.is_connected(_on_craft_completed):
		SignalBus.craft_completed.disconnect(_on_craft_completed)

func _load_recipes() -> void:
	var f: FileAccess = FileAccess.open(RECIPES_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary and (parsed as Dictionary).has("recipes"):
		var arr: Array = (parsed as Dictionary)["recipes"] as Array
		for r: Dictionary in arr:
			var rid: String = String(r.get("id", ""))
			if rid == "":
				continue
			_recipe_harmony[rid] = int(r.get("harmony_reward", 0))

func _on_minute_ticked(day: int, hour: int, _minute: int) -> void:
	# TASK-339: window-close check must run BEFORE the season/day/hour gate so
	# it still fires once the window itself would otherwise early-return
	# (handles the hour 18:00 tick cleanly and protects against stuck-open
	# state across a save/load or day skip).
	if _cook_active and _is_past_window(day, hour):
		_resolve_contest()
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
	# Songkran water play peaks midday — gate on 12:00-18:00 window.
	if hour < 12 or hour >= 18:
		return
	var tm_local: Node = SignalBus.time_manager
	var year: int = tm_local.year() if tm_local != null and tm_local.has_method("year") else 1
	var key: String = "%d-%s" % [year, season]
	if _triggered_keys.has(key):
		return
	_triggered_keys[key] = true
	_cook_active = true
	_cook_score = 0
	_spawn_splash()
	SignalBus.festival_triggered.emit("songkran")
	SignalBus.show_dialogue.emit("Child", "Songkran! Happy New Year — you're soaked!")
	SignalBus.show_dialogue.emit("Elder", "Rod Nam Dum Hua — the scented water honors those who came before us.")

func _spawn_splash() -> void:
	if _splash != null:
		return
	var mat: Material = load("res://assets/particles/songkran_splash.tres")
	if mat == null:
		return
	var main: Node = get_parent()
	if main == null or not (main is Node2D):
		return
	_splash = GPUParticles2D.new()
	_splash.name = "SongkranSplash"
	_splash.position = Vector2(2 * 48 + 24, 2 * 48) # lotus pond
	_splash.amount = 64
	_splash.lifetime = 1.6
	_splash.one_shot = true
	_splash.explosiveness = 0.9
	_splash.emitting = true
	(_splash as GPUParticles2D).process_material = mat
	main.add_child(_splash)

# TASK-339: window close — same festival day past 18:00, OR moved past the
# window entirely (different day, or no longer the festival day-of-season).
func _is_past_window(day: int, hour: int) -> bool:
	var tm: Node = SignalBus.time_manager
	var dos: int = festival_day
	if tm != null and tm.has_method("day_of_season"):
		dos = int(tm.day_of_season())
	if dos != festival_day:
		return true
	return hour >= 18

func _resolve_contest() -> void:
	var rival_score: int = randi_range(4, 14)
	var placement: String = _placement_for(_cook_score, rival_score)
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
	SignalBus.show_dialogue.emit("Elder",
		"The tasting's done — you: %d, the field: %d. %s! (+%d silver, +%d harmony)" % [
			_cook_score, rival_score, placement_label, silver_reward, harmony_reward])
	# TASK-347: only Ploy's own rival (thematically linked to cooking) is
	# nudged — a "first" win pushes the rival's clock back, a
	# "participation" loss (the field/rival won) pushes it forward. A tie
	# does nothing. The other 5 rivals are deliberately unaffected.
	var rc: Node = SignalBus.rival_clock
	if rc != null:
		if placement == "first":
			rc.nudge_progress("ploy", -5.0)
		elif placement == "participation":
			rc.nudge_progress("ploy", 5.0)
	_cook_active = false
	_cook_score = 0

## Pure placement logic extracted so tests can drive tie outcomes deterministically
## without depending on the randi_range rival roll.
func _placement_for(player_score: int, rival_score: int) -> String:
	if player_score > rival_score:
		return "first"
	if player_score == rival_score:
		return "tie"
	return "participation"

func _on_craft_completed(item_id: String, qty: int) -> void:
	# craft_completed is shared with fish/ore catches — only score events
	# whose item_id is an actual recipe id (membership check, not prefix).
	if not _cook_active or not _recipe_harmony.has(item_id):
		return
	_cook_score += int(_recipe_harmony[item_id]) * qty
