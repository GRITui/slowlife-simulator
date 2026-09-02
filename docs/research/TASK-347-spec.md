# TASK-347 — Schema v5: rival progress meter + rival friendship

**Execute BEFORE TASK-342** (the rivals need `rival_friendship` to
exist for their gift/confession system) but AFTER TASK-341 (no hard
dependency, just keeps the numbering sane). Self-executed, not
delegated — this is a save-schema change, same risk class as TASK-340.
Batches TWO new fields into ONE migration rather than bumping the
version twice for two separate features landing close together.

## Field 1: `rival_progress` (replaces pure day-count for the win/loss clock)

Currently `RivalClock._check_candidate()` computes elapsed time purely
from `day - GameData.npc_first_met_day[candidate_id]`, comparing
against a fixed 90-day `WINDOW_DAYS`. The owner asked for festival wins
to push a specific rival back "slightly," and losses to push them
forward — this needs an actual adjustable value, not a pure day
computation.

New field: `var rival_progress: Dictionary = {}` (`candidate_id ->
float`, 0-100, where 100 = the rival wins). Advances automatically by
`100.0 / RivalClock.WINDOW_DAYS` (~1.11) per day via the existing daily
check — replacing the `elapsed >= WINDOW_DAYS` comparison with
`rival_progress[candidate_id] >= 100.0`. This keeps the DEFAULT pacing
identical to today (still ~90 days to a loss if nothing else touches
it) while making the value externally adjustable.

`RivalClock.gd` changes:
- `_check_candidate()`: instead of computing `elapsed`/`frac` from raw
  days, read/initialize `rival_progress[candidate_id]` (starting at 0.0
  when `npc_first_met_day` is first set — this init can happen in
  `RomanceNPC.try_interact()` alongside the existing
  `npc_first_met_day` set, or lazily in `_check_candidate()` the first
  time it's seen; pick whichever is cleaner and don't duplicate the
  init in both places), advance it by the daily rate, then use ITS
  value (not day-elapsed) for both the warning-threshold checks (25/50/
  75) and the loss check (>= 100).
- New public method: `RivalClock.nudge_progress(candidate_id: String, delta: float) -> void` —
  clamps `rival_progress[candidate_id]` to `[0, 100]` after applying
  `delta`. Does nothing if the candidate has no `first_met_day` yet or
  is already `lost_to_rival`/`married` (nudging a resolved or
  not-yet-started clock is a no-op).

## Field 2: `rival_friendship` (for TASK-342's dilemma quest)

New field: `var rival_friendship: Dictionary = {}` (`rival_id -> int`,
0-100 — same shape and the same `GameData.level_for()` from TASK-346
applies to it, per the owner's instruction that the 10-level system
covers "friendly NPC ... affiliation too"). No behavior in THIS task —
TASK-342 is what reads/writes it. This task only adds the field and its
persistence.

## Field 3: `rival_confessed` (also for TASK-342, same migration)

New field: `var rival_confessed: Dictionary = {}` (`rival_id -> bool`)
— tracks whether a rival's one-time confession dialogue has already
fired, so it never repeats. Same treatment as field 2: add it here so
this is the only schema bump for the whole friendship/confession
system, no behavior in this task.

## Festival tie-in (the actual "push back on win" mechanic)

Per owner decision: **only the thematically-linked rival is affected**,
not all 6.
- Winning the Fishing Competition (`FishingCompetitionTrigger.gd`'s
  `_resolve_competition()`, placement `"first"`) → `RivalClock.nudge_progress("fah", -5.0)`
  (pushes Ohm back). Losing (placement `"participation"`, i.e. the
  rival/field won) → `RivalClock.nudge_progress("fah", +5.0)`. A tie
  does nothing (neither pushed).
- Winning the Songkran Cooking Contest (`SongkranTrigger.gd`'s
  `_resolve_contest()`, same placement shape) →
  `RivalClock.nudge_progress("ploy", -5.0)` on `"first"`,
  `+5.0` on `"participation"`, nothing on `"tie"`.
- Both trigger files need a reference to the `RivalClock` node — use
  `get_tree().get_first_node_in_group(...)` or read it via
  `get_parent()` (Main) `.get_node_or_null("RivalClock")`, guarding for
  null (a headless test that doesn't boot full `Main` shouldn't crash).
  Check how other cross-system lookups in this codebase are done
  (e.g. `SignalBus.grid_manager` is a registered-reference pattern) and
  match the existing convention rather than inventing a new one — if a
  registry-style reference doesn't exist for `RivalClock`, add one to
  `SignalBus.gd` mirroring `grid_manager`'s exact pattern (register in
  `_ready()`, clear in `_exit_tree()`), rather than tree-walking.
- Ek/Chang/Klong/Yaa's rivals (Yai/Note/Fon/Boon) are
  deliberately NOT affected by any mini-game today — this is
  intentional per the owner's explicit choice, not a gap to silently
  patch. A future mini-game tied to farming/crafting/herbalism could
  close this later; out of scope here.

## `SaveManager.gd` — v4 → v5

Same pattern as every prior bump: add `rival_progress`,
`rival_friendship`, and `rival_confessed` to `save_game()`'s dict, add
a `if version < 5:`
block in `migrate()` default-adding all three as `{}`, restore all three in
`load_game()` via `.duplicate(true)`. **Re-verify indentation carefully
against the `if version < N:` block's actual nesting level before
inserting** — TASK-340 shipped a real bug here (the v4 block was
accidentally nested one level too deep inside the v3 block and never
ran for the most common case) caught only by its own test, not by
inspection. Write the "already-v5 payload is a no-op, a v4 payload
advances to v5 with defaults" test pair FIRST, matching
`test_save_compat.gd`'s existing v3/v4 checks, and confirm they fail
before the migration code exists and pass after — that's what would
have caught TASK-340's bug immediately instead of by luck.

## Tests

- `test_save_compat.gd`: v4→v5 migration + round-trip for all three
  fields, mirroring the v3→v4 additions exactly.
- New or extended `tests/test_rival_clock.gd`: `nudge_progress()`
  clamps to [0,100], no-ops on an unmet/already-resolved candidate,
  and the loss/warning checks now key off `rival_progress` instead of
  raw day-elapsed (rewrite the existing day-simulation test to set
  `rival_progress` directly for the boundary checks, and add ONE
  test proving a `nudge_progress(-50)` mid-window meaningfully delays
  the next warning tier / the eventual loss day, so the "slightly"
  framing has a numeric proof it isn't a token gesture).
- `tests/test_fishing_competition_scoring.gd` /
  `tests/test_songkran_cooking_contest.gd`: extend each with a check
  that a `"first"` placement calls `nudge_progress(candidate, -5.0)`
  and `"participation"` calls `nudge_progress(candidate, +5.0)` for
  their specific candidate only (fah / ploy respectively) — mock or
  spy on `RivalClock` however fits this codebase's existing test style
  for cross-system signal checks (see how other tests verify a signal
  fired without needing the full receiving system wired).

## Constraints

- Do not change `WINDOW_DAYS`, the 25/50/75 warning fractions, or the
  25-affinity loss threshold from TASK-340 — this task changes HOW
  progress is tracked and nudged, not the underlying pacing/thresholds.
- Do not implement the confession dilemma logic here — that's TASK-342,
  which depends on `rival_friendship` existing but owns all the
  behavior around it.
- Run `bash scripts/ci/run_gate.sh all` — must stay green, paying
  particular attention to `test_save_compat.gd` and `test_rival_clock.gd`.
- No git/gh actions — stop after code + tests are written and the gate
  is green. Do not commit, push, open a PR, or merge.
