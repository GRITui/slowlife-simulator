# TASK-323 split B — Livestock breeding (herd-count sink)

**Status:** `todo` | **Priority:** medium | **Category:** gameplay/economy | **Owner:** OpenCode/Cline
**Files:** `scripts/autoload/GameData.gd`, `scenes/entities/ChickenCoop.gd`, `scenes/entities/Buffalo.gd`, `tests/test_livestock_breeding.gd` (new)

## Scope note — deliberately no new animal entities
The original gap ("Breeding Sinks: incubators... expand livestock without
buying") could mean literally spawning additional `ChickenCoop`/`Buffalo`
nodes into the world. That's a much bigger change — both are currently
hard singletons (`Main.gd`'s `_ensure_chicken_coop()`/`_ensure_buffalo()`
each guard on "does this named node already exist," and each script has
no concept of an instance identity beyond its own node). Refactoring that
is real scope, not warranted for an MVP breeding mechanic.

Redesign: model "herd size" as a capped counter
(`GameData.chicken_count`/`buffalo_count`, both start at 1, cap 3) that
**scales yield** per collection — 1 hen's coop still gives 1 egg, a
3-hen coop gives 3. Breeding grows the counter **automatically as a side
effect of the existing daily interact**, mirroring this repo's own
established idiom for gradual growth (`fishing_skill`/`mining_skill`
leveling up automatically every N successful actions) — no new input
scheme, no new UI, no new scene.

## Design
- `GameData.gd`: add `var chicken_count: int = 1` and
  `var buffalo_count: int = 1`, both capped at 3 (matches the existing
  hearts cap aesthetic, a small "herd" not an unbounded farm).
- `ChickenCoop.collect_egg()`: two changes to the existing function
  (search for `func collect_egg`):
  1. The egg grant becomes `GameData.add_item(egg_id, GameData.chicken_count)`
     instead of a flat `1` — herd size scales output.
  2. After the existing affinity/egg logic, **attempt breeding**: if
     `GameData.chicken_hearts() >= 2` AND `GameData.chicken_count < 3` AND
     `GameData.spend_silver(40)` succeeds (in that order — don't check
     silver before hearts/cap, since spending silver on a check that was
     going to fail anyway is wasted, and don't spend if the cap is already
     hit): increment `chicken_count`, dialogue announcing a new chick
     hatched (mention new coop size). If silver is insufficient, this is
     a **silent skip, no dialogue nag** — breeding is a bonus on top of
     the normal daily collection, not a requirement, matching the
     no-fail-state cozy philosophy (see `TASK-319` precedent).
- `Buffalo.interact()`: identical shape — milk grant scales by
  `GameData.buffalo_count`, breeding attempt uses `buffalo_hearts() >= 2`,
  `buffalo_count < 3`, `spend_silver(60)` (buffalo is the pricier animal,
  matches its already-higher milk value vs. eggs).
- Breeding only ever attempts on a day where the daily interact actually
  succeeds (i.e., inside the `if _last_egg_day == day: return false`
  early-return's *else* path) — never on the soft-fail "already collected
  today" path.

## Acceptance Criteria
- `chicken_count`/`buffalo_count` start at 1, cap at 3, never exceed 3
  regardless of how many successful days pass.
- Egg/milk grant amount equals the current count (1 egg at count 1, up to
  3 at count 3) — tier (`egg`/`egg_gold`, `buffalo_milk`/`_high`) is
  unaffected by count, they're independent axes (quality vs. quantity).
- Breeding only occurs when hearts >= 2 AND count < cap AND enough silver
  — silver is deducted only when breeding actually happens, never
  speculatively (mirror `SluiceGate.gd`'s check-before-deduct pattern
  established in `TASK-322`'s Code Quality Review, not the corrected
  version's speculative-deduct-then-refund mistake).
- Insufficient silver for breeding does not block or alter the normal
  egg/milk collection that triggered the attempt — no dialogue, no
  side effect, silent skip.
- `run_tests.gd` / `run_engine_tests.gd` stay green — in particular
  `tests/test_chicken.gd` and `tests/test_hearts_live.gd`/
  `test_buffalo_hearts.gd`/`test_livestock_quality.gd`, which assert
  exact egg/milk counts granted per collection at count-1 (default);
  those assertions should still hold since count starts at 1 (yield = 1,
  unchanged) unless breeding has already occurred earlier in that test's
  own flow.
