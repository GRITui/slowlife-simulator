extends Node
## RivalClock — TASK-340. Owns the rival win/loss deadline check for every
## romance candidate. Pure mechanism: PAIRS is empty in this task — sprints
## 2/3 (TASK-342) populate it with real candidate/rival npc_ids. This file
## has zero content of its own.
##
## Mechanic (owner-confirmed 2026-09-02, a deliberate one-time reversal of
## this project's no-fail-state precedent — see docs/research/TASK-340-spec.md):
## if a candidate's affinity is still below 25 ("stranger" tier — essentially
## never engaged with) 90 days after the player first met them, the paired
## rival wins and that candidate becomes permanently unavailable for
## marriage. No other consequence — they remain a normal friendly NPC.
## Reaching affinity >= 25 before the deadline clears the clock forever.

const WINDOW_DAYS: int = 90
const WARNING_FRACTIONS: Array[float] = [0.25, 0.5, 0.75]

## npc_id (candidate) -> {"rival_id": ..., "rival_name": ..., "candidate_name": ...}
## TASK-342: populated with all 6 real pairings. _check_candidate() /
## _resolve_loss() read pair via the dict this points at, so tests can
## still exercise them with a temporary pair (matching their explicit-
## parameter signature) without PAIRS itself having to stay empty.
const PAIRS: Dictionary = {
	"ek": {"rival_id": "yai", "rival_name": "Yai", "candidate_name": "Ek"},
	"fah": {"rival_id": "ohm", "rival_name": "Ohm", "candidate_name": "Fah"},
	"ploy": {"rival_id": "rung", "rival_name": "Rung", "candidate_name": "Ploy"},
	"chang": {"rival_id": "note", "rival_name": "Note", "candidate_name": "Chang"},
	"klong": {"rival_id": "fon", "rival_name": "Fon", "candidate_name": "Klong"},
	"yaa": {"rival_id": "boon", "rival_name": "Boon", "candidate_name": "Yaa"},
}

var _last_checked_day: int = -1

func _ready() -> void:
	SignalBus.minute_ticked.connect(_on_minute_ticked)
	SignalBus.rival_clock = self

func _exit_tree() -> void:
	if SignalBus.minute_ticked.is_connected(_on_minute_ticked):
		SignalBus.minute_ticked.disconnect(_on_minute_ticked)
	if SignalBus.rival_clock == self:
		SignalBus.rival_clock = null

func _on_minute_ticked(day: int, _hour: int, _minute: int) -> void:
	if day == _last_checked_day:
		return
	_last_checked_day = day
	for candidate_id: String in PAIRS.keys():
		_check_candidate(candidate_id, day, PAIRS[candidate_id] as Dictionary)

## pair is passed explicitly (not read from PAIRS internally) so tests can
## exercise this logic with a temporary pair without needing PAIRS itself
## to be non-empty (PAIRS stays empty until TASK-342 wires real candidates).
##
## TASK-347: progress is tracked as an explicit float (GameData.rival_progress,
## 0-100) rather than computed purely from day-elapsed, so festival wins/
## losses can nudge it via nudge_progress(). Default pacing (nothing else
## touching it) still reaches 100 in exactly WINDOW_DAYS, matching the
## original day-elapsed behavior.
const _DAILY_RATE: float = 100.0 / float(WINDOW_DAYS)

func _check_candidate(candidate_id: String, day: int, pair: Dictionary) -> void:
	if GameData.married and GameData.spouse == candidate_id:
		return # already won — clock is irrelevant
	if GameData.lost_to_rival.get(candidate_id, false):
		return # already resolved
	var first_met: int = int(GameData.npc_first_met_day.get(candidate_id, 0))
	if first_met <= 0:
		return # haven't met yet — clock hasn't started
	if int(GameData.get_affinity(candidate_id)) >= 25:
		return # cleared stranger tier — permanently safe, nothing left to check
	if not GameData.rival_progress.has(candidate_id):
		GameData.rival_progress[candidate_id] = 0.0
	var progress: float = float(GameData.rival_progress[candidate_id]) + _DAILY_RATE
	progress = clampf(progress, 0.0, 100.0)
	GameData.rival_progress[candidate_id] = progress
	if progress >= 100.0:
		_resolve_loss(candidate_id, pair)
		return
	var frac: float = progress / 100.0
	var shown: int = int(GameData.rival_warning_shown.get(candidate_id, 0))
	for i: int in WARNING_FRACTIONS.size():
		if frac >= WARNING_FRACTIONS[i] and shown <= i:
			GameData.rival_warning_shown[candidate_id] = i + 1
			break

## TASK-347: external nudge (e.g. a festival win/loss). No-op if the
## candidate's clock hasn't started yet or is already resolved (won/lost) —
## nudging a not-yet-relevant or already-settled clock does nothing.
func nudge_progress(candidate_id: String, delta: float) -> void:
	if int(GameData.npc_first_met_day.get(candidate_id, 0)) <= 0:
		return
	if GameData.lost_to_rival.get(candidate_id, false):
		return
	if GameData.married and GameData.spouse == candidate_id:
		return
	var current: float = float(GameData.rival_progress.get(candidate_id, 0.0))
	GameData.rival_progress[candidate_id] = clampf(current + delta, 0.0, 100.0)

func _resolve_loss(candidate_id: String, pair: Dictionary) -> void:
	GameData.lost_to_rival[candidate_id] = true
	var candidate_name: String = String(pair.get("candidate_name", candidate_id.capitalize()))
	var rival_name: String = String(pair.get("rival_name", "someone"))
	SignalBus.show_dialogue.emit("System", "%s has married %s. Life in the village goes on." % [candidate_name, rival_name])
