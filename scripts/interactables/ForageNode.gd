extends Node2D
## ForageNode — TASK-390. Interact while in proximity to forage one wild
## item per real day per node instance (cooldown, no stamina cost, no
## rarity roll — just "once per day"). Mirrors MiningSpot.gd's shape:
## single Area2D built programmatically in _ready(), interact_radius 56.0,
## proximity in/out tracking, one item type awarded per interact.
##
## One script serves both lone-NPC nodes (different item_id per instance):
##   FishKeeperForageNode    -> item_id "wild_turmeric"
##   ScrapCollectorForageNode -> item_id "salvaged_scrap"
## Cooldown state lives in GameData.forage_node_last_day (node instance
## name -> last_day), the same additive-Dict shape as
## family_gift_hint_last_day. Day is read from SignalBus.time_manager.day,
## the same source FlavorNPC._current_day() uses.

@export var item_id: String = ""
@export var cooldown_days: int = 1
## Proximity radius (matches SluiceGate/CarpenterUpgrade/MiningSpot InteractArea).
@export var interact_radius: float = 56.0

var spot_name: String = "Forage Spot"

var _player_in_range: bool = false
var _area: Area2D = null

func _ready() -> void:
	add_to_group("forage_node")
	_build_interact_area()

func _build_interact_area() -> void:
	# Same programmatic InteractArea shape as MiningSpot.gd (FishingSpot's
	# old @onready path was always null because nothing ever added the
	# child — build it here instead).
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

func _current_day() -> int:
	# Same "once per day" day-source as FlavorNPC._current_day() —
	# SignalBus.time_manager's current day.
	var tm: Node = SignalBus.time_manager
	if tm != null and "day" in tm:
		return int(tm.day)
	return 1

## Days since this node instance was last foraged (-1 = never).
func days_since_forage() -> int:
	var last: int = int(GameData.forage_node_last_day.get(name, -1))
	if last < 0:
		return 999
	return _current_day() - last

func is_ready() -> bool:
	return days_since_forage() >= cooldown_days

func forage() -> bool:
	if item_id.is_empty():
		return false
	if not is_ready():
		SignalBus.show_dialogue.emit(spot_name, "Nothing new here yet. Give it a day.")
		return false
	GameData.add_item(item_id, 1)
	GameData.forage_node_last_day[name] = _current_day()
	SignalBus.show_dialogue.emit(spot_name, "Found some %s." % item_id.replace("_", " "))
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		forage()
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = false
