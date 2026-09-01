extends CharacterBody2D
## CompanionNPC — TASK-048 (PO_INBOX r4/r5 #4, deferral brought back).
## Cozy cat companion: follows the player past a leash distance, idles
## within, teleports when left far behind (offscreen catch-up). Avoids
## water tiles via WorldRender.ground_at (canal/pond/deep_pond blocked).
## Zero-combat, no schedules, no fail state.
##
## TASK-325: also accumulates a passive "bond" with the player. Each
## SignalBus.minute_ticked while within COMFORT of the player counts as a
## "nearby-minute". Every 60 nearby-minutes (~1 in-game hour of
## togetherness) grants +1 GameData.companion_bond. Dialogue is only
## emitted when the bond tier actually increases.

const FOLLOW_LEASH: float = 96.0    # start following beyond this
const COMFORT: float = 56.0         # stop within this of the player
const TELEPORT: float = 640.0       # catch-up threshold
const WALK_SPEED: float = 140.0
const _WATER := ["canal", "water_lotuspond", "deep_pond"]
## TASK-325: ticks of minute_ticked needed for +1 companion_bond. Mirrors
## "1 in-game hour of togetherness" stated in the design.
const BOND_MINUTES_PER_POINT: int = 60

@export var follow_enabled: bool = true
## Dependency injected by Main._ensure_companion (ENGINE-006 hygiene —
## no node-path tree walks from entities).
var world_render: Node = null

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

## TASK-325: minutes spent within COMFORT of the player since last bond grant.
var _nearby_minutes: int = 0

func _ready() -> void:
	add_to_group("companion")
	SignalBus.minute_ticked.connect(_on_minute_ticked)

func _exit_tree() -> void:
	if SignalBus.minute_ticked.is_connected(_on_minute_ticked):
		SignalBus.minute_ticked.disconnect(_on_minute_ticked)

## TASK-325: bond accrues only while the companion is within COMFORT of the
## player. Counter resets after each +1 grant; dialogue only fires when the
## tier (companion_bond / 25) actually increases, never per tick.
func _on_minute_ticked(_day: int, _hour: int, _minute: int) -> void:
	var player: Node2D = _find_player()
	if player == null:
		return
	var dist: float = global_position.distance_to(player.global_position)
	if dist > COMFORT:
		return
	_nearby_minutes += 1
	if _nearby_minutes >= BOND_MINUTES_PER_POINT:
		_nearby_minutes = 0
		var tier_before: int = GameData.companion_bond_tier()
		GameData.add_companion_bond(1)
		var tier_after: int = GameData.companion_bond_tier()
		if tier_after > tier_before:
			SignalBus.show_dialogue.emit("Companion", _tier_line(tier_after))

func _physics_process(delta: float) -> void:
	var player: Node2D = _find_player()
	if player == null or not follow_enabled:
		_idle()
		return
	var to_player: Vector2 = player.global_position - global_position
	var dist: float = to_player.length()
	if dist > TELEPORT:
		# Catch-up: never leave the cat behind (cozy, no fail).
		global_position = player.global_position + Vector2(40, -24)
		return
	if dist > FOLLOW_LEASH:
		var dir: Vector2 = to_player.normalized()
		var next: Vector2 = global_position + dir * WALK_SPEED * delta
		# Water avoidance: refuse steps into canal/pond cells.
		if not _is_water(next):
			global_position = next
			_walk(dir)
		else:
			# Slide along the water edge (axis-separated retry).
			var side: Vector2 = Vector2(dir.y, dir.x)
			var alt: Vector2 = global_position + side * WALK_SPEED * delta
			if not _is_water(alt):
				global_position = alt
				_walk(side)
			else:
				_idle()
	else:
		_idle()

func _idle() -> void:
	velocity = Vector2.ZERO
	if _anim != null and _anim.animation != &"idle":
		_anim.play(&"idle")

func _walk(dir: Vector2) -> void:
	velocity = dir * WALK_SPEED
	if _anim != null and _anim.animation != &"walk":
		_anim.play(&"walk")

func _is_water(pos: Vector2) -> bool:
	if world_render == null or not world_render.has_method("ground_at"):
		return false
	var cell := Vector2i(int(floor(pos.x / 48.0)), int(floor(pos.y / 48.0)))
	var ground: String = String(world_render.ground_at(cell))
	return ground in _WATER

func _find_player() -> Node2D:
	var nodes: Array = get_tree().get_nodes_in_group("player")
	return nodes[0] as Node2D if not nodes.is_empty() else null

## TASK-325: cozy tier-up dialogue. Index matches companion_bond_tier()
## (0 = new acquaintance, 1..4 = ascending closeness). Cap-safe: any
## out-of-range tier falls back to the highest line.
func _tier_line(tier: int) -> String:
	match tier:
		1: return "Your cat rubs against your leg. (Companion bond: 1)"
		2: return "Your cat follows at your heel. (Companion bond: 2)"
		3: return "Your cat purrs on your lap. (Companion bond: 3)"
		4: return "Your cat is your true companion. (Companion bond: 4)"
		_: return "Your cat purrs. (Companion bond: %d)" % tier
