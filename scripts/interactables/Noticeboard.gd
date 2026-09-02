extends Node2D
## Noticeboard — TASK-332. Repeatable side-quest requests: fulfill the posted
## notice (item_id x qty) for silver + harmony, then the board immediately
## rotates to a new random request so it is never empty. Deliberately SEPARATE
## from QuestLog.gd's 22-objective chain — no integration, no
## GameData.active_quests writes.
##
## V1 does NOT persist across save/load: notice rotation state resets on a
## fresh session (save-format changes are an always-escalate category here,
## so no new persisted field in SaveManager.gd).
##
## Structural pattern mirrors MiningSpot.gd: real Area2D + CircleShape2D
## proximity trigger built programmatically in _ready() (radius 56, matching
## SluiceGate/CarpenterUpgrade/MiningSpot), _player_in_range tracked via
## body_entered/body_exited, `interact` handled in _unhandled_input(). Owns
## its roster + rotation logic (self-contained, like FishingSpot/MiningSpot).

const NOTICES_PATH: String = "res://data/noticeboard/notices.json"
## Lazy re-roll cadence: the board rotates after this many in-game days.
const ROTATE_DAYS: int = 7

## Proximity radius (matches SluiceGate/CarpenterUpgrade/MiningSpot InteractArea).
@export var interact_radius: float = 56.0

var spot_name: String = "Noticeboard"
var _active_notice: Dictionary = {}
var _last_rotate_day: int = -1 ## day of the last board change (lazy-rotation clock)
## Fallback day when SignalBus.time_manager is unregistered; without a time
## source the lazy day-rotation never fires (fulfill-rotation still works).
var _local_day: int = 1

var _player_in_range: bool = false
var _roster: Array = []
var _area: Area2D = null

func _ready() -> void:
	add_to_group("noticeboard")
	_build_interact_area()
	_load_roster()
	# Initial board: one random notice from the roster (empty if no roster).
	_active_notice = _pick_random_excluding({})
	_last_rotate_day = _current_day()

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
	var f: FileAccess = FileAccess.open(NOTICES_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Array:
		_roster = parsed as Array
	elif parsed is Dictionary and (parsed as Dictionary).has("notices"):
		_roster = (parsed as Dictionary)["notices"] as Array

func _current_day() -> int:
	var tm: Node = SignalBus.time_manager
	if tm != null and "day" in tm:
		return int(tm.day)
	return _local_day

## Random roster entry, preferring one DIFFERENT from `current` when the
## roster has more than 1 entry (the board never repeats while it can avoid it).
func _pick_random_excluding(current: Dictionary) -> Dictionary:
	if _roster.is_empty():
		return {}
	var pool: Array = _roster
	if _roster.size() > 1 and not current.is_empty():
		pool = []
		var current_id: String = String(current.get("id", ""))
		for n: Dictionary in _roster:
			if String(n.get("id", "")) == current_id:
				continue
			pool.append(n)
	if pool.is_empty():
		return {}
	return pool.pick_random() as Dictionary

## Lazy 7-day rotation, checked on interact (no minute_ticked subscription).
func _maybe_rotate() -> void:
	if _roster.is_empty():
		return
	var today: int = _current_day()
	if today - _last_rotate_day < ROTATE_DAYS:
		return
	_active_notice = _pick_random_excluding(_active_notice)
	_last_rotate_day = today

func _try_fulfill() -> bool:
	if _active_notice.is_empty():
		SignalBus.show_dialogue.emit(spot_name, "Nothing posted right now.")
		return false
	var item_id: String = String(_active_notice.get("item_id", ""))
	var qty: int = maxi(1, int(_active_notice.get("qty", 1)))
	# Check-before-deduct (see CarpenterUpgrade.gd header): a speculative
	# deduct+refund would double-fire SignalBus.silver_changed on a soft fail.
	if not GameData.has_item(item_id, qty):
		# Show the notice's own line as a hint — never a silent failure.
		SignalBus.show_dialogue.emit(spot_name, String(_active_notice.get("line", "")))
		return false
	var reward_silver: int = int(_active_notice.get("reward_silver", 0))
	var reward_harmony: int = int(_active_notice.get("reward_harmony", 0))
	if not GameData.remove_item(item_id, qty):
		return false
	GameData.add_silver(reward_silver)
	GameData.add_harmony(reward_harmony)
	SignalBus.show_dialogue.emit(spot_name, "%s is grateful! +%d silver, +%d harmony." % [
		String(_active_notice.get("flavor_npc", "Villager")), reward_silver, reward_harmony])
	# Rotate immediately so the board is never empty (different notice when
	# the roster allows); stamps the lazy-rotation clock.
	_active_notice = _pick_random_excluding(_active_notice)
	_last_rotate_day = _current_day()
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		_maybe_rotate() # lazy day-based re-roll before showing the board
		_try_fulfill()
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = false
