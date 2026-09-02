# TASK-324 — Rival flavor + life progression (rivals + pregnancy/childbirth/toddler)

**Status:** `todo` | **Priority:** medium | **Category:** narrative | **Owner:** OpenCode/Cline
**Files:** `scripts/autoload/GameData.gd`, `scenes/entities/RomanceNPC.gd`, `scripts/narrative/DialogueDB.gd`, `tests/test_life_progression.gd` (new)

## Owner decision this task must honor
Approved in full scope 2026-09-01, **explicitly accepting** the tension
with this project's no-fail-state cozy precedent (`TASK-319`) rather than
avoiding it — but the note attached to that approval said rival pressure
and no-fail-state aren't mutually exclusive, and implementation should
still aim to avoid a hard fail state where possible. This spec follows
that: rivals are flavor-only social pressure with zero mechanical effect
(no affinity loss, no blocked proposal, no timer) — they add texture to
courtship, not risk.

## Design — reuses the existing romance/marriage system entirely
No new NPCs, no new scenes, no new mechanics invented. Both pieces build
directly on what `RomanceNPC.gd`/`DialogueDB.gd`/`GameData.gd` already
ship (affinity tiers, proposal, marriage, the TASK-282 yearly anniversary
loop).

### Rival flavor
- `DialogueDB.gd`: add a `"rival"` pool to both `niran` and `fah`'s entries
  in the `DIALOGUE` dict (2 lines each, matching the existing tone — note
  Niran's existing `"romantic"` line already says "no rivalry this time,"
  so there's already a thematic hook to build on). Example direction:
  someone else has been asking about the player's love interest — light,
  not alarming, no name attached to a real rival NPC (no new character).
- `RomanceNPC.gd`'s `_talk()` (search for `func _talk`): when
  `DialogueDBScript.get_affinity_tier(GameData.get_affinity(npc_id))`
  is `"close"` and the player isn't married to this NPC, substitute the
  `"rival"` pool for the normal `"close"` pool on every 5th talk
  (`_talk_count % 5 == 4`) instead of every time — occasional, not
  constant. Everything else in `_talk()` (talk-count increment, quest
  objective completion, quest offering) stays unchanged; this only swaps
  which line pool `DialogueDBScript.get_line()` reads from for that one
  call.

### Life progression (pregnancy → childbirth → toddler)
- `GameData.gd`: add `var married_year: int = 0` and `var child_stage: int = 0`
  (0 = none, 1 = pregnant, 2 = born, 3 = toddler — terminal, no further
  stages).
- `RomanceNPC.gd`'s `_check_proposal()` (search for `func _check_proposal`):
  when a proposal succeeds, also set `GameData.married_year = ` the
  current year (same `SignalBus.time_manager`/`tm.year()` pattern already
  used in the anniversary block above it in the file).
- `RomanceNPC.gd`'s married branch of `try_interact()` (the block that
  currently does the `key`/`active_quests.has(key)` check and grants
  +30 silver/+10 harmony): on a **new** anniversary (inside the
  `if not GameData.active_quests.has(key):` branch, after the existing
  `add_silver`/`add_harmony`/`festival_triggered.emit` calls, which must
  stay exactly as they are — **do not add or change silver amounts, and
  do not add a new `festival_triggered` event**, both would risk breaking
  `tests/test_anniversary.gd`'s existing exact-silver and event-count
  assertions), compute `years_married = year - GameData.married_year` and
  check for a stage transition:
  - `years_married >= 1 and GameData.child_stage == 0` → `child_stage = 1`
    (pregnant), `GameData.add_harmony(15)` (harmony-only bonus — no
    silver, per the constraint above), dialogue announcing the
    pregnancy **instead of** the standard anniversary line for this call.
  - `years_married >= 2 and GameData.child_stage == 1` → `child_stage = 2`
    (born), `GameData.add_harmony(25)`, dialogue announcing the birth,
    instead of the standard line.
  - `years_married >= 3 and GameData.child_stage == 2` → `child_stage = 3`
    (toddler, terminal), `GameData.add_harmony(15)`, dialogue about the
    child growing, instead of the standard line.
  - Otherwise (no transition this call, including once `child_stage == 3`
    forever after): the standard anniversary line, unchanged from today.
  - Only ever one transition per anniversary call, even if multiple years
    were skipped — the if/elif-style ordering above naturally enforces
    this (each branch checks the *current* `child_stage`, so skipping
    years doesn't cascade multiple stage-ups in one interaction).

## Acceptance Criteria
- Rival lines only ever appear at `"close"` tier, unmarried, on exactly
  every 5th talk (`_talk_count % 5 == 4`) — never at other tiers, never
  when married to this NPC, never on other calls within close tier.
- `married_year` is set at the moment of a successful proposal, not before.
- Anniversary calls at `years_married` 1/2/3 (with `child_stage` at the
  expected prior value) grant the documented harmony bonus and the
  milestone dialogue instead of the standard line; all other anniversary
  calls are unaffected.
- `child_stage` never exceeds 3, and no further harmony bonuses trigger
  once it reaches 3.
- No change to the amount of silver granted per anniversary, and no new
  `SignalBus.festival_triggered` event beyond the existing
  `"anniversary_" + npc_id` — verify by running `tests/test_anniversary.gd`
  unmodified and confirming it still passes (it directly sets
  `gd.married = true` without going through the proposal path, so
  `married_year` will be 0 there — the life-progression math must still
  produce a valid, non-crashing result in that case, just without a
  "real" wedding year to count from).
- `tests/test_wedding.gd` stays green unmodified.
- `run_tests.gd` / `run_engine_tests.gd` stay green.
