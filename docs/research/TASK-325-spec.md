# TASK-325 — Companion bond + race tie-in (redesigned from "dog/horse")

**Status:** `todo` | **Priority:** low | **Category:** gameplay | **Owner:** OpenCode/Cline
**Files:** `scripts/autoload/GameData.gd`, `scenes/entities/CompanionNPC.gd`, `scripts/interactables/BuffaloRace.gd`, `tests/test_companion_bond.gd` (new)

## Scope note — most of the original gap is already shipped
The original suggestion was "a dog (trained via whistle/ball for festival
racing) and a horse (ridden for fast transport and racing)." Investigation
found this repo already has both underlying mechanics, just under
different animals:
- **Riding + racing already exists**: `BuffaloRace.gd` (TASK-270, "Wing
  Kwai" checkpoint racing while mounted) + buffalo riding (TASK-272). A
  literal horse would be re-skinning an already-shipped mechanic, not
  filling a real gap.
- **A pet companion already exists**: `CompanionNPC.gd`/`CatCompanion.tscn`
  (TASK-048) — a cat that follows the player, avoids water, catches up
  when left behind. Zero-combat, no schedules, no fail state, no
  interaction beyond ambient presence.

The one genuine remaining gap: **the companion has no progression or tie-in
to anything else** — it's purely decorative movement AI. Redesigned scope:
give it a bond system (mirrors the `buffalo_hearts`/`chicken_hearts`
tiered-affinity idiom already used twice) that grows passively while it's
nearby, and once bonded, a small tie-in to the *existing* race system
(not a new dog/horse race) — "training" pays off through the mechanic
that already exists, rather than a duplicate one.

## Design
- `GameData.gd`: add `var companion_bond: int = 0` (0..100, 25 per tier,
  same shape as `buffalo_affinity`/`buffalo_hearts()` — add
  `add_companion_bond(amount: int)` and `companion_bond_tier() -> int`
  mirroring `add_buffalo_affinity`/`buffalo_hearts()` exactly).
- `CompanionNPC.gd`: connect to `SignalBus.minute_ticked` in `_ready()`
  (mirrors how festival triggers already subscribe to it). Each tick,
  if the companion is within `COMFORT` (56.0, the existing constant) of
  the player, accumulate a nearby-minutes counter; every 60 accumulated
  nearby-minutes (~1 in-game hour of togetherness), grant
  `GameData.add_companion_bond(1)` and reset the counter to 0. This is
  slow, passive growth — no player action required, matching the
  companion's existing zero-interaction design. No dialogue spam per
  tick; only announce (`SignalBus.show_dialogue.emit("Companion", ...)`)
  when `companion_bond_tier()` actually increases.
- `BuffaloRace.gd`: in `start_race()` (search for `func start_race`),
  after the existing mount check passes, check whether the companion is
  within some reasonable radius of the player (e.g. 200px — comfortably
  larger than `COMFORT` so it doesn't need to be glued to the player, but
  still "present") AND `GameData.companion_bond_tier() >= 2`. If both
  true, on a **won** race (inside `_finish(true)`, search for that
  function) grant one extra small bonus on top of the existing harmony +
  sticky_rice reward — e.g. `GameData.add_item("sticky_rice", 1)` (one
  more, not a new item type) with a dialogue line crediting the companion
  ("Your companion cheered you on! +1 extra sticky rice."). No bonus, no
  extra dialogue, if the companion isn't present or isn't bonded enough
  — this is a bonus layer on an already-working system, not a new
  requirement to win.

## Acceptance Criteria
- `companion_bond` starts at 0, grows only while the companion is within
  `COMFORT` of the player, at the documented rate (1 per 60 nearby-minute
  ticks), and caps at 100 (tier 4) — mirror `buffalo_hearts()`'s existing
  clamp behavior exactly.
- No growth at all while the companion is not nearby (test by forcing
  distance beyond `COMFORT` and ticking `minute_ticked` — bond must not
  increase).
- `BuffaloRace._finish(true)` grants the companion bonus only when both
  conditions hold (nearby + bond tier >= 2); grants the normal reward
  unchanged (no regression) when either condition fails.
- Existing `tests/test_companion.gd` and any `BuffaloRace`-related test
  (check for one; if none exists, that's fine — just don't break
  `test_companion.gd`'s existing assertions) stay green.
- `run_tests.gd` / `run_engine_tests.gd` stay green.
