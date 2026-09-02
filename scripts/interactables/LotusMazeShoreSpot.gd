extends Node2D
## LotusMazeShoreSpot — TASK-344 (Sprint 5 final). The "ultimate" fishing
## spot, on the walkable EDGE of the lotus maze (the 3×3 maze interior at
## GridManager.maze_origin = Vector2i(14, 10) is entirely deep_pond and
## not walkable — same water-adjacency principle FishingSpot.gd already
## uses). Gated behind GameData.milestones_earned.size() >= 5 — every
## TASK-331 milestone earned (deep_miner, master_angler, inseparable,
## herd_keeper, storm_catch). The "completionist" capstone, not a
## single-skill gate. Reuses data/fish/fish.json verbatim (no new
## species); the rarity weighting is biased toward legendary even
## harder than DeepCanalSpot.gd, since this is the "ultimate" spot
## that ties into the elder's "fishing_hint" flavor line about
## "something flashes every color in the sun near the lotus maze."
##
## Same shape as DeepCanalSpot.gd / FishingSpot.gd: water-adjacent,
## rod-gated, season-gated, skill-gated. Does NOT bump fishing_skill
## and does NOT re-trigger master_angler / storm_catch — FishingSpot.gd
## owns those surfaces.

const FISH_PATH: String = "res://data/fish/fish.json"
const _WATER := ["canal", "water_lotuspond", "deep_pond"]

@export var spot_name: String = "Lotus Maze Shore"
## Proximity radius (matches SluiceGate/CarpenterUpgrade/MiningSpot InteractArea).
@export var interact_radius: float = 56.0

var _player_in_range: bool = false
var _roster: Array = []
var _area: Area2D = null

func _ready() -> void:
	add_to_group("lotus_maze_shore_spot")
	_build_interact_area()
	_load_roster()

func _build_interact_area() -> void:
	# Build the InteractArea programmatically (the @onready path is
	# always null because nothing ever adds the child — fix that here).
	_area = Area2D.new()
	_area.name = "InteractArea"
	_area.collision_layer = 0
	_area.collision_mask = 1 # player layer
	_area.monitorable = true
	_area.monitoring = true
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = interact_radius
	var collider: CollisionShape2D = CollisionShape2D.new()
	collider.shape = shape
	collider.debug_color = Color(0.7, 0.4, 0.6, 0.32)
	_area.add_child(collider)
	add_child(_area)
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)

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

## Roll a catch weighted by rarity — biased toward legendary even harder
## than DeepCanalSpot.gd. This is the "ultimate" spot, framing itself
## as the capstone: common 0.2 / uncommon 0.8 / rare 2.5 / legendary
## 5.0. Same 20 species as FishingSpot/DeepCanalSpot — the rarity
## weights do all the differentiation. Effective legendary share
## dwarfs both the regular spot (legendary weight 0.4) and the deep
## canal (legendary weight 4.0).
func _roll_catch() -> Dictionary:
	var pool: Array = eligible_fish()
	if pool.is_empty():
		return {}
	var total: float = 0.0
	var weights: Array = []
	for f: Dictionary in pool:
		var w: float = 0.2
		match String(f.get("rarity", "common")):
			"uncommon": w = 0.8
			"rare": w = 2.5
			"legendary": w = 5.0
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
	if _skill() >= 4:
		big_bias = 0.55
	elif String(picked.get("rarity", "common")) in ["rare", "legendary"]:
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
	# TASK-281: skill-4 mastery tip — silver for every catch.
	if _skill() >= 4:
		GameData.add_silver(5)
	# Deliberately does NOT bump fishing_skill and does NOT re-trigger the
	# master_angler or storm_catch milestones — FishingSpot.gd owns those
	# surfaces. This spot is gated on having every milestone already
	# earned, so the skill/milestone surfaces are not its concern.
	var species: Dictionary = catch_data["species"] as Dictionary
	var size: Dictionary = (species.get("sizes", {}) as Dictionary).get(catch_data["size"], {}) as Dictionary
	SignalBus.craft_completed.emit(item, 1) # reuse item-gained signal (no new orphan)
	var flavor: String = "From the lotus maze shore: a %s %s! (+%d harmony)" % [
		String(catch_data["size"]), String(species.get("display_name", "fish")), int(size.get("harmony_value", 1))]
	# TASK-344: legendary catch at THIS spot specifically gets a one-line
	# flavor reference to the elder's "fishing_hint" line that's been
	# sitting unused since TASK-050 — the mechanical payoff for that
	# sitting-unused lore.
	if String(species.get("rarity", "")) == "legendary":
		flavor = "The elder was right — something flashes every color in the sun here. A %s %s! (+%d harmony)" % [
			String(catch_data["size"]), String(species.get("display_name", "fish")), int(size.get("harmony_value", 1))]
	SignalBus.show_dialogue.emit(spot_name, flavor)
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