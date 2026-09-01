extends Node2D
## MiningSpot — TASK-321. Interact while in proximity to the mining spot:
## rolls a find from data/ore/ore.json (3 ore tiers), gated by mining_skill
## (1..3). Stamina-gated instead of tool-gated (mining is always accessible
## once found, cozier and simpler than fishing). Zero-combat dig-and-relax:
## no fail states, soft "too tired" only.
##
## Unlike FishingSpot.gd this builds a real InteractArea programmatically in
## _ready() (CircleShape2D radius 56) so proximity-based interaction works
## in real play. FishingSpot has a latent bug where its @onready var _area
## stays null — that issue is pre-existing and out of scope to fix here.

const ORE_PATH: String = "res://data/ore/ore.json"
## Stamina cost per dig attempt.
@export var dig_cost_stamina: float = 8.0
## Skill growth: +1 per this many successful digs.
@export var rolls_per_skill: int = 5
## Skill cap (matches 3-entry ore roster, not fishing's 4).
@export var skill_cap: int = 3
## Proximity radius (matches SluiceGate/CarpenterUpgrade InteractArea).
@export var interact_radius: float = 56.0

var spot_name: String = "Mining Spot"
var mining_rolls: int = 0 ## lifetime successful digs, +1 skill per rolls_per_skill (cap 3)

var _player_in_range: bool = false
var _roster: Array = []
var _area: Area2D = null

func _ready() -> void:
	add_to_group("mining_spot")
	_build_interact_area()
	_load_roster()

func _build_interact_area() -> void:
	# Build the InteractArea programmatically (FishingSpot's @onready path is
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
	collider.debug_color = Color(0.2, 0.7, 0.5, 0.32)
	_area.add_child(collider)
	add_child(_area)
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)

func _load_roster() -> void:
	var f: FileAccess = FileAccess.open(ORE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Array:
		_roster = parsed as Array
	elif parsed is Dictionary and (parsed as Dictionary).has("ore"):
		_roster = (parsed as Dictionary)["ore"] as Array

func _skill() -> int:
	return clampi(int(GameData.mining_skill), 1, skill_cap)

## Eligible ore: skill requirement met.
func eligible_ore() -> Array:
	var out: Array = []
	for o: Dictionary in _roster:
		if int(o.get("skill_required", 1)) > _skill():
			continue
		out.append(o)
	return out

## Roll an ore by rarity weight: common 4.0 / uncommon 2.5 / rare 1.2.
func _roll_ore() -> Dictionary:
	var pool: Array = eligible_ore()
	if pool.is_empty():
		return {}
	var total: float = 0.0
	var weights: Array = []
	for o: Dictionary in pool:
		var w: float = 4.0
		match String(o.get("rarity", "common")):
			"uncommon": w = 2.5
			"rare": w = 1.2
		weights.append(w)
		total += w
	var roll: float = randf() * total
	var picked: Dictionary = pool[0]
	for i: int in pool.size():
		roll -= weights[i]
		if roll <= 0.0:
			picked = pool[i]
			break
	return picked

func dig() -> bool:
	# Stamina gate: soft-fail with dialogue, no item, no stamina change.
	if GameData.current_stamina < dig_cost_stamina:
		SignalBus.show_dialogue.emit(spot_name, "Too tired to dig. Rest a moment.")
		return false
	var picked: Dictionary = _roll_ore()
	if picked.is_empty():
		SignalBus.show_dialogue.emit(spot_name, "Nothing here worth digging up yet.")
		return false
	var item: String = String(picked.get("item_id", ""))
	if item.is_empty():
		return false
	GameData.add_item(item, 1)
	GameData.add_harmony(int(picked.get("harmony_value", 1)))
	# Deduct stamina via the setter (clamps + emits stamina_changed).
	GameData.current_stamina -= dig_cost_stamina
	mining_rolls += 1
	# Skill growth: 1 level per rolls_per_skill, capped at skill_cap.
	var level: int = clampi(1 + mining_rolls / rolls_per_skill, 1, skill_cap)
	if level > _skill():
		GameData.mining_skill = level
		SignalBus.show_dialogue.emit(spot_name, "Mining skill up! Now level %d." % level)
	SignalBus.craft_completed.emit(item, 1) # reuse item-gained signal (no new orphan)
	SignalBus.show_dialogue.emit(spot_name, "Dug up %s! (+%d harmony)" % [
		String(picked.get("display_name", "ore")), int(picked.get("harmony_value", 1))])
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		dig()
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = false
