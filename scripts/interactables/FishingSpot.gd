extends Node2D
## FishingSpot — TASK-050 (PO_INBOX r5 #5/#6). Interact adjacent to a water
## tile while holding a fishing rod: rolls a catch from data/fish/fish.json
## (20 Thai freshwater species x 3 sizes), gated by season + fishing skill.
## Zero-combat catch-and-relax: no fail states, soft "nothing biting" only.

const FISH_PATH: String = "res://data/fish/fish.json"
const _WATER := ["canal", "water_lotuspond", "deep_pond"]

@export var spot_name: String = "Fishing Spot"
var fishing_rolls: int = 0 ## lifetime catches, +1 skill per 5 rolls (cap 4)

var _player_in_range: bool = false
var _roster: Array = []

@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null

func _ready() -> void:
	add_to_group("fishing_spot")
	if _area != null:
		_area.body_entered.connect(_on_body_entered)
		_area.body_exited.connect(_on_body_exited)
	_load_roster()

func _load_roster() -> void:
	var f: FileAccess = FileAccess.open(FISH_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Array:
		_roster = parsed as Array
	elif parsed is Dictionary and (parsed as Dictionary).has("fish"):
		_roster = (parsed as Dictionary)["fish"] as Array

func _skill() -> int:
	return clampi(int(GameData.fishing_skill), 1, 4)

func _current_season() -> String:
	var tm: Node = SignalBus.time_manager
	if tm != null and "current_season" in tm:
		return String(tm.current_season)
	return String(GameData.current_season)

## Eligible species: season matches + skill requirement met.
func eligible_fish() -> Array:
	var season: String = _current_season()
	var out: Array = []
	for f: Dictionary in _roster:
		var seasons: Array = f.get("seasons", []) as Array
		if not seasons.has(season):
			continue
		if int(f.get("skill_required", 1)) > _skill():
			continue
		out.append(f)
	return out

func _water_adjacent() -> bool:
	var main: Node = get_parent()
	var wr: Node = main.get_node_or_null("WorldRender") if main != null else null
	if wr == null or not wr.has_method("ground_at"):
		return false
	var origin := Vector2i(int(global_position.x / 48.0), int(global_position.y / 48.0))
	for offset: Vector2i in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
		if String(wr.ground_at(origin + offset)) in _WATER:
			return true
	return false

## Roll size weighted by rarity: common favors small, rare favors big.
func _roll_catch() -> Dictionary:
	var pool: Array = eligible_fish()
	if pool.is_empty():
		return {}
	var total: float = 0.0
	var weights: Array = []
	for f: Dictionary in pool:
		var w: float = 4.0
		match String(f.get("rarity", "common")):
			"uncommon": w = 2.5
			"rare": w = 1.2
			"legendary": w = 0.4
		weights.append(w)
		total += w
	var roll: float = randf() * total
	var picked: Dictionary = pool[0]
	for i: int in pool.size():
		roll -= weights[i]
		if roll <= 0.0:
			picked = pool[i]
			break
	# Size roll skews by rarity (rare -> bigger expected size).
	var big_bias: float = 0.15
	if String(picked.get("rarity", "common")) in ["rare", "legendary"]:
		big_bias = 0.4
	var size_roll: float = randf()
	var size: String = "small"
	if size_roll > 1.0 - big_bias:
		size = "big"
	elif size_roll > 0.55:
		size = "mid"
	var sizes: Dictionary = picked.get("sizes", {}) as Dictionary
	return {"species": picked, "size": size, "item": String(sizes.get(size, {}).get("item_id", "")),
		"harmony": int(sizes.get(size, {}).get("harmony_value", 1))}

func cast_line() -> bool:
	if not _water_adjacent():
		SignalBus.show_dialogue.emit(spot_name, "Stand closer to the water.")
		return false
	if not GameData.has_item("fishing_rod", 1):
		SignalBus.show_dialogue.emit(spot_name, "A fishing rod would help. The market boats carry them.")
		return false
	var catch_data: Dictionary = _roll_catch()
	if catch_data.is_empty():
		SignalBus.show_dialogue.emit(spot_name, "Nothing biting this season yet.")
		return false
	var item: String = String(catch_data["item"])
	if item.is_empty():
		return false
	GameData.add_item(item, 1)
	GameData.add_harmony(int(catch_data["harmony"]))
	fishing_rolls += 1
	# Skill growth: 1 level per 5 rolls, capped at 4 (top tier).
	var level: int = clampi(1 + fishing_rolls / 5, 1, 4)
	if level > _skill():
		GameData.fishing_skill = level
		SignalBus.show_dialogue.emit(spot_name, "Fishing skill up! Now level %d." % level)
	var species: Dictionary = catch_data["species"] as Dictionary
	var size: Dictionary = (species.get("sizes", {}) as Dictionary).get(catch_data["size"], {}) as Dictionary
	SignalBus.craft_completed.emit(item, 1) # reuse item-gained signal (no new orphan)
	SignalBus.show_dialogue.emit(spot_name, "Caught a %s %s! (+%d harmony)" % [
		String(catch_data["size"]), String(species.get("display_name", "fish")), int(size.get("harmony_value", 1))])
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		cast_line()
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = false
