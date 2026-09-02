extends Node2D
## SacredGroveSpot — TASK-343. A secondary, unlockable wood-gathering spot the
## cat companion trusts the player enough to show, gated behind
## GameData.companion_bond_tier() reaching its cap (4). Reuses the same
## "wood" item from ForestTree (no new item); the "richer vein, harder to
## reach" framing here is a higher daily yield (3 base + axe bonus, vs
## ForestTree's 1 base + axe bonus) since wood has no rarity tiers to
## invert. Daily-gated per spot, mirroring ForestTree.gd's once-per-day
## logic. The cat's own trust milestone ("inseparable") is owned by the
## companion system — this spot does NOT re-trigger it.
##
## BUGFIX (Code Quality Review): the original draft copied ForestTree.gd's
## @onready $InteractArea pattern, but ForestTree is placed via a real
## .tscn with a real InteractArea child — this spot is instanced dynamically
## via Main.gd's script.new() (same as MountainCaveSpot/DeepCanalSpot), so
## $InteractArea would ALWAYS be null and chop() could only ever fire from
## a direct method call (tests), never from a real player pressing interact.
## Build the Area2D programmatically instead, matching MountainCaveSpot.gd/
## DeepCanalSpot.gd's established pattern for this exact class of spot.

@export var interact_radius: float = 56.0

var _player_in_range: bool = false
var _last_chop_day: int = -1
var _area: Area2D = null

func _ready() -> void:
	add_to_group("sacred_grove_spot")
	_build_interact_area()

func _build_interact_area() -> void:
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
	collider.debug_color = Color(0.35, 0.55, 0.3, 0.32)
	_area.add_child(collider)
	add_child(_area)
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)

func _current_day() -> int:
	var tm: Node = SignalBus.time_manager
	if tm != null and "day" in tm:
		return int(tm.day)
	return 1

func chop() -> bool:
	# Daily gate: one chop per spot per day, mirroring ForestTree.
	var day: int = _current_day()
	if _last_chop_day == day:
		SignalBus.show_dialogue.emit("Sacred Grove", "The grove has given its wood for today — the cat curls up to rest.")
		return false
	_last_chop_day = day
	# Richer vein: 3 base + axe bonus (ForestTree is 1 base + axe bonus).
	var wood: int = 3
	if GameData.has_item("axe", 1):
		wood += 1
	GameData.add_item("wood", wood)
	SignalBus.show_dialogue.emit("Sacred Grove", "+%d wood — the cat watches, the grove answers." % wood)
	# TASK-310: Complete wood gathering quest objective (same hook as
	# ForestTree, in case this spot is the one the player visited last
	# in the chain — the quest system just needs to know *any* wood
	# was gathered today).
	var quest_logs: Array = get_tree().get_nodes_in_group("quest_log")
	if not quest_logs.is_empty():
		var quest_log: Node = quest_logs[0] as Node
		if quest_log != null and quest_log.has_method("complete_objective_everywhere"):
			quest_log.complete_objective_everywhere("gather_reinforcement_wood")
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		chop()
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = false
