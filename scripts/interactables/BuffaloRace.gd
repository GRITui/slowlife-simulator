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
		# TASK-325 companion tie-in: bonus sticky_rice when the companion is
		# both nearby (within ~200px of the player) AND bonded enough
		# (tier >= 2). Mirrors the spec's "present + bonded" guard; absent
		# or unbonded -> identical payout, no regression.
		if _companion_bonus_eligible():
			GameData.add_item("sticky_rice", 1)
			SignalBus.show_dialogue.emit("Companion", "Your companion cheered you on! +1 extra sticky rice.")
	else:
		SignalBus.show_dialogue.emit("Wing Kwai", "Out of time — the buffalo grazes on. No shame in the mud.")

## TASK-325: returns true only when the companion is within ~200px of the
## player AND companion_bond_tier() >= 2. Radius is comfortably larger
## than CompanionNPC.COMFORT (56.0) so the cat doesn't need to be glued
## to the player, but still "present" during the race.
func _companion_bonus_eligible() -> bool:
	if GameData.companion_bond_tier() < 2:
		return false
	if _player == null:
		return false
	var companions: Array = get_tree().get_nodes_in_group("companion") if is_inside_tree() else []
	for c in companions:
		if c is Node2D:
			var nd: Node2D = c as Node2D
			if nd.global_position.distance_to(_player.global_position) <= 200.0:
				return true
	return false

## Test/debug helper: force-finish with a result.
func force_finish(won: bool) -> void:
	_finish(won)
