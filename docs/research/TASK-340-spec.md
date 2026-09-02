# TASK-340 — Sprint 1: Rival win/loss save schema + core logic

Sprint 1 of the "6 romance + 6 rivals + 5 unlockable areas" plan
(2026-09-02). **This is the highest-risk task in the whole plan — a
save-schema change (always-escalate, never auto-merged) and a genuine
reversal of this project's no-fail-state precedent, both explicitly
confirmed by the owner.** Self-executed, not delegated, given the
stakes. No romance-candidate or rival NPC content is added in this
sprint — purely the mechanism, tested in isolation, so sprints 2-5 have
solid ground to build on.

## Mechanic (owner-confirmed, do not deviate)

- The "clock" for a candidate starts the first time the player ever
  interacts with them (`RomanceNPC.try_interact()`), not from game
  start — so exploring at your own pace before ever meeting someone
  costs nothing.
- Window: **90 days** from first meeting.
- If, at the 90-day mark, `GameData.get_affinity(npc_id) < 25`
  (still "stranger" tier, i.e. essentially never engaged with), the
  rival wins: that candidate becomes permanently unavailable for
  marriage. **No other consequence** — they remain a normal friendly
  NPC, all non-romance interactions (talk, gift, specialty-sell)
  continue working.
- **3 warnings**, surfaced ONLY through the rival NPC's own dialogue
  when the player talks to them directly (never an ambient popup —
  every dialogue line in this game fires on interact, and warnings
  should match that, not break it) — at 25%/50%/75% of the 90-day
  window elapsed. The final "they got married" resolution IS an
  ambient one-time `"System"` dialogue line (matches the existing
  precedent — `SignalBus.show_dialogue.emit("System", "Progress saved.")`
  and similar already fire ambiently elsewhere in `Main.gd`).
- If the player reaches affinity >= 25 before the deadline, the clock
  is irrelevant forever after — there is no re-triggering, no second
  deadline, nothing further to track for that candidate once they've
  cleared "stranger" tier.

## `SaveManager.gd` — v3 → v4 (do this part with maximum care)

Read `SaveManager.gd` in full first (all three functions: `save_game()`,
`migrate()`, `load_game()`) and mirror the exact v2→v3 pattern used for
every field there — this is not a new pattern, it's the established one
applied to 3 more fields.

New `GameData.gd` fields (add near the existing `affinity`/`spouse`
declarations, TASK-051/059 section):
```gdscript
# TASK-340 rival win/loss system. npc_first_met_day: npc_id -> day the
# player first ever interacted with them (clock start). lost_to_rival:
# npc_id -> true once the rival has won (permanent, one-way).
# rival_warning_shown: npc_id -> highest warning index (0-3) already
# surfaced, so a warning line is shown at most once per threshold.
var npc_first_met_day: Dictionary = {}
var lost_to_rival: Dictionary = {}
var rival_warning_shown: Dictionary = {}
```

`SAVE_VERSION` → `4`. Add all 3 fields to `save_game()`'s `data`
dictionary (plain `gd.<field>` references, same as every other
Dictionary field there — `.duplicate(true)` is used on load, not on
save, matching the existing convention exactly).

`migrate()`: add an `if version < 4:` block (after the existing
`if version < 3:` block, same shape) that default-adds all 3 fields as
empty `{}` if missing — a save from before this task loads exactly as
if the player had met nobody yet and no rival had ever progressed
(fully backward-compatible, no behavior change for existing saves).

`load_game()`: restore all 3 via `(data.get(key, {}) as Dictionary).duplicate(true)`,
same pattern as `gd.affinity`/`gd.active_quests`/etc.

## `tests/test_save_compat.gd`

Extend with the exact same shape as the v2→v3 additions: a v3 payload
migrates to v4 with all 3 new fields defaulting to `{}`; a full
round-trip test setting non-empty values for all 3 fields and
confirming they survive save→load. Do not touch any existing assertion
in this file — purely additive, mirroring how the v2→v3 migration was
added without disturbing v1→v2 checks.

## Core logic — where it lives

New file: `scripts/core/RivalClock.gd` (a small standalone, NOT an
autoload — instanced once by `Main.gd`, same `_ensure_*` pattern as
every other system this session). This owns the pairing table and the
daily check; it does NOT own any NPC content yet (sprints 2-3 add the
actual candidates/rivals and wire them into this table).

```gdscript
extends Node
## RivalClock — TASK-340. Owns the rival win/loss deadline check for every
## romance candidate. Pure mechanism: sprints 2-3 populate PAIRS with real
## candidate/rival npc_ids; this file has zero content of its own.

const WINDOW_DAYS: int = 90
const WARNING_FRACTIONS: Array[float] = [0.25, 0.5, 0.75]

## npc_id (candidate) -> {"rival_id": ..., "rival_name": ..., "candidate_name": ...}
## Empty until sprints 2/3 add real pairs — an empty table means this file
## does nothing yet, which is the correct state for THIS task.
const PAIRS: Dictionary = {}

var _last_checked_day: int = -1

func _ready() -> void:
	SignalBus.minute_ticked.connect(_on_minute_ticked)

func _exit_tree() -> void:
	if SignalBus.minute_ticked.is_connected(_on_minute_ticked):
		SignalBus.minute_ticked.disconnect(_on_minute_ticked)

func _on_minute_ticked(day: int, _hour: int, _minute: int) -> void:
	if day == _last_checked_day:
		return
	_last_checked_day = day
	for candidate_id: String in PAIRS.keys():
		_check_candidate(candidate_id, day)

func _check_candidate(candidate_id: String, day: int) -> void:
	if GameData.married and GameData.spouse == candidate_id:
		return # already won — clock is irrelevant
	if GameData.lost_to_rival.get(candidate_id, false):
		return # already resolved
	var first_met: int = int(GameData.npc_first_met_day.get(candidate_id, 0))
	if first_met <= 0:
		return # haven't met yet — clock hasn't started
	if int(GameData.get_affinity(candidate_id)) >= 25:
		return # cleared stranger tier — permanently safe, nothing left to check
	var elapsed: int = day - first_met
	if elapsed >= WINDOW_DAYS:
		_resolve_loss(candidate_id)
		return
	var frac: float = float(elapsed) / float(WINDOW_DAYS)
	var shown: int = int(GameData.rival_warning_shown.get(candidate_id, 0))
	for i: int in WARNING_FRACTIONS.size():
		if frac >= WARNING_FRACTIONS[i] and shown <= i:
			GameData.rival_warning_shown[candidate_id] = i + 1
			break

func _resolve_loss(candidate_id: String) -> void:
	GameData.lost_to_rival[candidate_id] = true
	var pair: Dictionary = PAIRS.get(candidate_id, {})
	var candidate_name: String = String(pair.get("candidate_name", candidate_id.capitalize()))
	var rival_name: String = String(pair.get("rival_name", "someone"))
	SignalBus.show_dialogue.emit("System", "%s has married %s. Life in the village goes on." % [candidate_name, rival_name])
```

Note: `_check_candidate` deliberately does NOT emit a dialogue line for
warnings — that's surfaced by the rival NPC's own `talk()` in sprint 3,
reading `GameData.rival_warning_shown[candidate_id]`. This file only
maintains the counter.

## Wiring

`Main.gd`: `_ensure_rival_clock()` (script.new(), no `.tscn`, exact
`_ensure_mining_spot()` shape), called once from `_ready()`.

`RomanceNPC.gd`: at the very top of `try_interact()`, alongside the
existing unconditional quest-tracking calls, add (using the same
`day_bonus`-style lookup already established for TASK-333's weekly
engagement — reuse that exact pattern, don't re-derive `day` a third
way in this file):
```gdscript
if not GameData.npc_first_met_day.has(npc_id):
	GameData.npc_first_met_day[npc_id] = day_bonus
```
Also add, to `_check_proposal()`, as the very first line: `if GameData.lost_to_rival.get(npc_id, false): return false` —
this is the actual enforcement point (a lost candidate can never be
proposed to, permanently).

## Tests

New `tests/test_rival_clock.gd`:
- With `PAIRS` empty (as shipped in this task), `RivalClock` does
  nothing regardless of state — confirms the mechanism is inert until
  sprints 2/3 populate real pairs.
- Since `PAIRS` is empty in this task, most logic can only be tested by
  calling `RivalClock`'s methods directly with a temporary test-local
  pairs override, OR by testing `_check_candidate()` in isolation with
  a manually-constructed `PAIRS`-shaped dictionary passed as an
  argument instead of reading the const directly — restructure
  `_check_candidate`/`_resolve_loss` to accept the pair dictionary as a
  parameter (not read `PAIRS[candidate_id]` internally) if that makes
  testing cleaner; use your judgment on the cleanest testable shape,
  note which approach you took.
- `RomanceNPC.try_interact()` sets `npc_first_met_day` on first
  interact only, never overwrites it on subsequent interacts.
- `_check_proposal()` returns `false` immediately when
  `lost_to_rival[npc_id]` is true, even at affinity 100 with a krathong
  held (the hard enforcement point).
- Full `test_save_compat.gd` v3→v4 migration + round-trip, as specified
  above.

## Constraints

- Do not add any romance-candidate or rival NPC content — `PAIRS` stays
  empty in this task.
- Do not change `_talk()`'s tier computation, `_give_gift()`, or
  `_try_specialty_sell()` in `RomanceNPC.gd` — only `try_interact()`
  (the `npc_first_met_day` set) and `_check_proposal()` (the block).
- This task is self-executed (not delegated) given the save-schema risk.
- Run `bash scripts/ci/run_gate.sh all` — must stay green, paying
  particular attention to `test_save_compat.gd`, `test_anniversary.gd`,
  `test_wedding.gd`, `test_peer_npcs.gd` (existing marriage/proposal
  flows must be completely unaffected for every candidate that never
  loses to a rival, which is every existing test scenario today).
