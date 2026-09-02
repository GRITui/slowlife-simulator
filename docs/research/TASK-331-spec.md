# TASK-331 — Milestone collectibles across varied activities

Sprint 3 of the "3 sprints, complete pending backlog" run (2026-09-02).

## Scope note (read before implementing)

`GameData.gd` already has a permanent-progression pattern (TASK-326):
`lifetime_items_shipped` + `stamina_tier` + `_check_stamina_milestone()`
(lines ~108-124) — read that first, it's the template to extend, NOT
replace. This task adds a SEPARATE registry (`milestones_earned`) for
achievements across varied activities, reusing the same "permanent,
one-time, idempotent" shape.

**Explicitly OUT OF SCOPE: do not touch `scripts/persistence/SaveManager.gd`
or add any new persisted field.** Save-format changes are an
always-escalate category in this project's pipeline (never auto-merged,
always human-reviewed) — that integration will be done separately by a
human reviewer after this task lands. Milestones earned in a session
that ends without that follow-up will not persist yet; that is a known,
accepted, temporary limitation — say so in a code comment, do not try to
work around it.

## `GameData.gd` additions

```gdscript
# TASK-331 milestone collectibles — permanent, one-time achievements
# across varied activities (distinct from TASK-326's single-axis
# shipping milestones above). Not yet persisted — see SaveManager.gd
# note; a human-reviewed follow-up adds that (save-format changes are
# always-escalate in this project's pipeline).
var milestones_earned: Dictionary = {}

## Idempotent: returns true only the first time an id is earned (and
## grants the reward then); returns false on every later call for the
## same id, with no further mutation.
func earn_milestone(id: String, reward_harmony: int = 10) -> bool:
	if milestones_earned.get(id, false):
		return false
	milestones_earned[id] = true
	add_harmony(reward_harmony)
	return true
```

## Milestone trigger sites (5 total — add exactly these, no more)

For each, call `GameData.earn_milestone(id)` and, only when it returns
`true`, emit `SignalBus.show_dialogue.emit("System", "Milestone: <name>! (+10 harmony)")`
— the milestone's own display line, distinct from whatever dialogue that
code path already emits (additive, do not replace existing dialogue).

1. `"deep_miner"` — in `scripts/interactables/MiningSpot.gd`, when
   `mining_skill` reaches its cap (3) for the first time (find the
   existing skill-up block, same shape as `FishingSpot.gd`'s).
2. `"master_angler"` — in `scripts/interactables/FishingSpot.gd`, when
   `fishing_skill` reaches its cap (4) for the first time.
3. `"inseparable"` — in `scenes/entities/CompanionNPC.gd`, when
   `companion_bond_tier()` reaches its max (4) for the first time
   (existing tier-up block already computes `tier_after`).
4. `"herd_keeper"` — when BOTH `GameData.buffalo_count >= 3` AND
   `GameData.chicken_count >= 3` become true (check after whichever
   breeding call — `Buffalo.gd` or `ChickenCoop.gd` — completes; check
   both conditions together, wherever it's simplest to add without
   duplicating logic in both files. A small shared check called from
   both breeding sites is fine).
5. `"storm_catch"` — in `FishingSpot.cast_line()`, when a catch succeeds
   AND `GameData.current_weather == "rain"` AND
   `GameData.current_season == "monsoon"`.

## Tests

New `tests/test_milestones.gd`:
- `GameData.earn_milestone()` grants harmony once, returns false and
  grants nothing on a repeat call with the same id.
- Each of the 5 trigger sites fires its milestone exactly once when the
  condition is met (drive the condition directly via GameData state +
  the relevant method call, mirroring how `tests/test_mining.gd` /
  `tests/test_fishing.gd` already drive skill-up).
- Repeating the triggering condition a second time does not re-grant
  (mirrors the quest-duplicate-payout regression pattern already fixed
  elsewhere in this codebase — read `tests/test_quest_no_dupe_payout.gd`
  for the shape of that kind of check before writing this one).

## Constraints

- Do not modify `SaveManager.gd` / `test_save_compat.gd`.
- Do not modify `GameData._check_stamina_milestone()` or the TASK-326
  threshold logic — additive only.
- Run `bash scripts/ci/run_gate.sh all` before considering this done;
  must stay green.
- No git/gh actions — stop after code + tests are written and the gate
  is green. Do not commit, push, open a PR, or merge.
