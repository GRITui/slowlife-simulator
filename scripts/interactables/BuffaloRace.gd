extends Node
## BuffaloRace — TASK-270 (#128) Wing Kwai racing minigame. Right-sized MVP:
## while mounted, pass 4 track checkpoints in order inside 90 real seconds.
## Reward: harmony + sticky_rice (The Mud and the Glory payout). Cozy: no
## opponents, no fail state — the timer only gates the bonus payout.

signal race_started
signal race_finished(won: bool, seconds: float)

const CHECKPOINTS: Array[Vector2] = [
	Vector2(3 * 48 + 24, 11 * 48),
	Vector2(8 * 48 + 24, 14 * 48),
	Vector2(12 * 48 + 24, 12 * 48),
	Vector2(6 * 48 + 24, 11 * 48),
]
const TIME_LIMIT: float = 90.0
const CHECK_RADIUS: float = 56.0

var race_active: bool = false
var race_time: float = 0.0
var next_checkpoint: int = 0
var _player: Node2D = null

func _ready() -> void:
	add_to_group("buffalo_race")

## Requires a mounted rider (Player.mounted == true).
func start_race(player: Node2D) -> bool:
	if race_active:
		return false
	if player == null or not ("mounted" in player) or not bool(player.get("mounted")):
		SignalBus.show_dialogue.emit("Wing Kwai", "Mount a buffalo first (R near the buffalo).")
		return false
	race_active = true
	race_time = 0.0
	next_checkpoint = 0
	_player = player
	race_started.emit()
	SignalBus.show_dialogue.emit("Wing Kwai", "The Mud and the Glory! Hit all 4 flags before the timer runs out.")
	return true

func _process(delta: float) -> void:
	if not race_active or _player == null:
		return
	race_time += delta
	if race_time > TIME_LIMIT:
		_finish(false)
		return
	if next_checkpoint < CHECKPOINTS.size():
		var cp: Vector2 = CHECKPOINTS[next_checkpoint]
		if _player.global_position.distance_to(cp) <= CHECK_RADIUS:
			next_checkpoint += 1
			SignalBus.show_dialogue.emit("Wing Kwai", "Flag %d/%d!" % [next_checkpoint, CHECKPOINTS.size()])
			if next_checkpoint >= CHECKPOINTS.size():
				_finish(true)

func _finish(won: bool) -> void:
	race_active = false
	race_finished.emit(won, race_time)
	if won:
		GameData.add_harmony(15)
		GameData.add_item("sticky_rice", 3)
		SignalBus.show_dialogue.emit("Wing Kwai", "Champion of the mud! +15 harmony, +3 sticky rice.")
	else:
		SignalBus.show_dialogue.emit("Wing Kwai", "Out of time — the buffalo grazes on. No shame in the mud.")

## Test/debug helper: force-finish with a result.
func force_finish(won: bool) -> void:
	_finish(won)
