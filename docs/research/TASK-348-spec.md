# TASK-348 — 10-level system, phase 2: buffalo, chicken, companion cat

Depends on TASK-346 (the shared `GameData.level_for()` function). No
schema change — `buffalo_affinity`/`chicken_affinity`/`companion_bond`
stay stored exactly as they are (0-100 ints), only the derived
hearts/tier functions and their consumers change.

## The real risk in this task: every consumer threshold assumes the OLD 0-4 scale

Confirmed via a full-repo grep before writing this spec — these are
ALL the places that read `buffalo_hearts()`/`chicken_hearts()`/
`companion_bond_tier()`, and every one of them has a hardcoded
threshold calibrated to the CURRENT 0-4 range (`/25.0` division). If
these functions start returning 0-10 (`/10.0`) without also rescaling
every consumer, the thresholds silently mean something completely
different — reachable 2-3x earlier than intended, or (for the
companion race bonus) unreachable at the old number.

| File | Current check | Old meaning (of 4) | New check (of 10) |
|---|---|---|---|
| `scripts/interactables/BuffaloRace.gd` | `companion_bond_tier() < 2` | < 50% | `< 5` |
| `scenes/entities/ChickenCoop.gd` | `chicken_hearts() >= 3` | 75% | `>= 8` |
| `scenes/entities/ChickenCoop.gd` | `chicken_hearts() >= 2` | 50% | `>= 5` |
| `scenes/entities/Buffalo.gd` | `buffalo_hearts() >= 3` | 75% | `>= 8` |
| `scenes/entities/Buffalo.gd` | `buffalo_hearts() >= 2` | 50% | `>= 5` |
| `scenes/entities/CompanionNPC.gd` (TASK-331 `inseparable` milestone) | `tier_after >= 4` (the max) | 100% (at cap) | `>= 10` (still the max, exact) |

Re-run this exact grep yourself before implementing
(`grep -rn "buffalo_hearts()\|chicken_hearts()\|companion_bond_tier()" scripts/ scenes/ --include="*.gd" | grep -v test`)
to confirm this list hasn't changed since this spec was written, and
update EVERY hit, not just the ones in this table.

## `GameData.gd` changes

```gdscript
func buffalo_hearts() -> int:
	return level_for(buffalo_affinity) # was: int(buffalo_affinity / 25.0)

func chicken_hearts() -> int:
	return level_for(chicken_affinity) # was: int(chicken_affinity / 25.0)

func companion_bond_tier() -> int:
	return level_for(companion_bond) # was: int(companion_bond / 25.0)
```
(`level_for()` is TASK-346's shared function — `clampi(value / 10, 0, 10)`.)

## `scenes/entities/CompanionNPC.gd` — `_tier_line()` needs 10 cases

Current (read the file in full first):
```gdscript
func _tier_line(tier: int) -> String:
	match tier:
		1: return "Your cat rubs against your leg. (Companion bond: 1)"
		2: return "Your cat follows at your heel. (Companion bond: 2)"
		3: return "Your cat purrs on your lap. (Companion bond: 3)"
		4: return "Your cat is your true companion. (Companion bond: 4)"
		_: return "Your cat purrs. (Companion bond: %d)" % tier
```
Expand to 10 distinct milestone lines (1 through 10), each a small step
up in warmth/closeness from the last, ending at 10 with language at
least as strong as the current tier-4 line ("true companion") — this
is the terminal milestone, should read as the peak of the relationship.
Keep the existing `_` fallback for safety.

## `scenes/entities/Buffalo.gd` / `ChickenCoop.gd` — dialogue at each hearts milestone

Currently each has ~3 distinct lines total (a "hearts increased" line
gated on the >=3 threshold, a generic "hearts increased" line
otherwise, and a "no change" line) — NOT a full per-level dialogue
pool. Add a `_hearts_line(hearts: int) -> String` helper (or inline
match) to each with 10 distinct lines, one per hearts value 1-10,
written in that animal's established voice (Buffalo: calm, steady,
milk-and-trust framing; Chicken: brisk, egg-and-flock framing). Called
whenever `hearts_before != hearts_after` (i.e., the level just went up),
replacing the current 2-line "high milk" vs "more milk" branching with
a full 10-line progression. The existing gold-egg/high-milk item-tier
logic (rescaled per the table above) stays as a SEPARATE check from
which dialogue line shows — an item-tier change and a dialogue-line
change don't have to be the same threshold.

## HUD display — a real consideration, don't skip it

`scenes/ui/HUD.gd`'s `_on_buffalo_hearts()` and `_on_farm_hearts_changed()`
currently render hearts as repeated `"♥"` glyphs (`"♥".repeat(hearts)`).
Repeating up to 10 heart glyphs in the existing compact HUD label would
be visually noisy on a small mobile screen — **switch to a numeric
"Lv 7/10" style format instead** for buffalo/chicken/companion in the
HUD (keep whatever look is cleanest given the existing label's
`_BASE_FONT_SIZES` constraints — check `HUD.tscn`'s label widths before
finalizing wording). Read `HUD.gd` in full before changing it — this is
tested, working code (`tests/test_villager_portraits.gd` and others
touch nearby systems); don't regress the existing hearts-display tests.

## Tests

- `GameData.buffalo_hearts()`/`chicken_hearts()`/`companion_bond_tier()`
  unit checks against the new 0-10 range at representative affinity
  values (0, 45, 79, 80, 100).
- Every rescaled threshold in the table above re-tested at its NEW
  boundary (e.g. `chicken_hearts() == 7` does NOT grant a gold egg,
  `== 8` does) — find and update the existing tests that check the OLD
  boundaries (`grep -rn "chicken_hearts\|buffalo_hearts\|companion_bond_tier" tests/`)
  rather than leaving them checking the wrong number.
- `CompanionNPC._tier_line()` returns 10 distinct strings for tiers
  1-10, no two identical.
- Existing `tests/test_milestones.gd`'s `inseparable` check (currently
  asserts `tier_after >= 4`) needs updating to the new `>= 10` — find
  and fix rather than leave it silently checking a now-unreachable-early
  threshold.
- HUD display format test (extend `tests/test_hud_progression.gd` or
  wherever the existing hearts-display checks live) confirming the new
  numeric format renders correctly at a representative level.

## Constraints

- Do not change the underlying `buffalo_affinity`/`chicken_affinity`/
  `companion_bond` storage range or add any new persisted field.
- Do not touch `MiningSpot.gd`/`FishingSpot.gd` or their `mining_skill`/
  `fishing_skill` — those are separate skill-tier systems (1-3/1-4),
  not affinity/hearts, and are explicitly NOT part of this 10-level
  unification (the owner's ask was about romance/friendly-NPC/animal
  AFFILIATION, not skill progression).
- Run `bash scripts/ci/run_gate.sh all` — this touches
  `tests/test_milestones.gd` and HUD tests directly; expect to fix
  existing assertions, not just add new ones.
- No git/gh actions — stop after code + tests are written and the gate
  is green. Do not commit, push, open a PR, or merge.
