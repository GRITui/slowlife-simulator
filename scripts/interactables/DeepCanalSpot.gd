extends Node2D
## DeepCanalSpot — TASK-343. A secondary, unlockable fishing spot at the deep
## canal bend, gated behind GameData.fishing_skill reaching its cap (4).
## Reuses data/fish/fish.json's existing 20 species verbatim (no new fish);
## the "richer vein, harder to reach" framing lives in the rarity weights,
## inverted from FishingSpot.gd so the legendary species (pla_buk /
## pla_sai_rung) are the MOST likely result here instead of the least.
## Canal casts here do NOT bump fishing_skill (the gate already held) and
## do NOT re-trigger the master_angler or storm_catch milestones —
## FishingSpot.gd owns those surfaces.

const FISH_PATH: String = "res://data/fish/fish.json"
const _WATER := ["canal", "water_lotuspond", "deep_pond"]

@export var spot_name: String = "Deep Canal Bend"
## Proximity radius (matches SluiceGate/CarpenterUpgrade/MiningSpot InteractArea).
@export var interact_radius: float = 56.0

var _player_in_range: bool = false
var _roster: Array = []
var _area: Area2D = null

func _ready() -> void:
	add_to_group("deep_canal_spot")
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
	collider.debug_color = Color(0.3, 0.5, 0.7, 0.32)
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
	# TASK-352: prefer the SignalBus.world_render registry slot so this
	# works identically in the outdoor World scene AND in any future
	# interior without depending on a hardcoded child node path.
	var wr: Node = SignalBus.world_render
	if wr == null or not wr.has_method("ground_at"):
		return false
	var origin := Vector2i(int(global_position.x / 48.0), int(global_position.y / 48.0))
	for offset: Vector2i in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
		if String(wr.ground_at(origin + offset)) in _WATER:
			return true
	return false

## Roll a catch weighted by rarity — inverted from FishingSpot.gd's
## common 4.0 / uncommon 2.5 / rare 1.2 / legendary 0.4 weighting so the
## legendary species (pla_buk, pla_sai_rung) are the MOST likely result
## here at the deep canal bend, instead of the least likely. Same 20
## species, just a richer vein.
func _roll_catch() -> Dictionary:
	var pool: Array = eligible_fish()
	if pool.is_empty():
		return {}
	var total: float = 0.0
	var weights: Array = []
	for f: Dictionary in pool:
		var w: float = 0.4
		match String(f.get("rarity", "common")):
			"uncommon": w = 1.2
			"rare": w = 2.5
			"legendary": w = 4.0
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
	# surfaces (the player already earned the cap to get here). This spot's
	# catch is independent of those progression milestones.
	var species: Dictionary = catch_data["species"] as Dictionary
	var size: Dictionary = (species.get("sizes", {}) as Dictionary).get(catch_data["size"], {}) as Dictionary
	SignalBus.craft_completed.emit(item, 1) # reuse item-gained signal (no new orphan)
	SignalBus.show_dialogue.emit(spot_name, "From the deep canal bend: a %s %s! (+%d harmony)" % [
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
