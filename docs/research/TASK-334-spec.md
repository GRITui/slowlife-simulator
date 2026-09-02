# TASK-334 — Extend mounted 3x3 interact to water/harvest (not just plant)

Sprint 3 of the "3 sprints, complete pending backlog" run (2026-09-02).

## Scope correction (read before implementing — this differs from the
## original backlog ticket text)

The original TASK-334 ticket (filed after the Gemini gap-analysis
research pass) proposed a brand-new "tool tier AoE/charge" mechanic
(hold-to-charge gesture, 1x3/3x3 clears unlocked by upgrading tools).
**Code audit found that's not quite the real gap**: `Player.gd` already
has a working mounted 3x3 mechanic (`_mounted_plant_3x3()`, wired via
`toggle_mount()` / `_try_grid_interact()`, TASK-272) — but it ONLY
handles planting. Standing on an already-planted 3x3 patch while
mounted does nothing useful for watering or harvesting; the player has
to dismount to do either. That inconsistency — not the absence of any
AoE mechanic at all — is the real, tightly-scoped gap.

**This task extends the existing mount-based 3x3 mechanic to also cover
water and harvest, mirroring the exact branch logic `_try_grid_interact()`
already uses for the single-cell unmounted case.** This is NOT a new
touch-gesture/charge system — do not add one. Read `Player.gd`'s
`_try_grid_interact()` and `_mounted_plant_3x3()` in full before writing
anything.

## Implementation

Rename/generalize `_mounted_plant_3x3(gm, center)` into a single
`_mounted_interact_3x3(gm, center)` that, for each of the 9 cells in the
3x3 area centered on `center`:

1. Read `gm.get_plot(cell)` (same as the unmounted branch already does).
2. If the plot is `null`: attempt to plant (same crop-selection logic as
   today's `_mounted_plant_3x3` — `_find_crop_for_held_seed()` falling
   back to jasmine_rice).
3. If the plot exists and `plot.stage >= plot.crop.total_stages - 1`
   (harvest-ready): call `gm.harvest(cell)`.
4. Otherwise (planted, not yet ready): call `gm.water(cell)`.

Accumulate simple counts (planted / harvested / watered) across the 9
cells and summarize in ONE `SignalBus.show_dialogue.emit("Farmer", ...)`
line at the end (mirroring the existing "Buffalo plow: %d/9 plots
planted." style, but reporting whichever actions actually happened this
pass — e.g. "Buffalo plow: 3 planted, 2 harvested, 4 watered." — omit a
category from the string if its count is 0, to avoid "0 harvested"
noise on every call).

Update the call site in `_try_grid_interact()`:
```gdscript
if mounted:
	_mounted_interact_3x3(gm, cell)
	return
```

**Do not change any of `GridManager.gd`'s `plant()`/`water()`/`harvest()`
signatures or internal logic** — this task only changes how `Player.gd`
calls them in a loop, exactly as the existing mounted-plant code already
does for `plant()`. Do not change unmounted (single-cell) behavior at
all — `_try_grid_interact()`'s `else` branch (not mounted) must be
byte-for-byte unchanged.

## Tests

`tests/test_riding.gd` (line ~42) calls `player._mounted_plant_3x3(gm, Vector2i(6, 6))`
directly and asserts all 9 cells got planted — update that call site to
the new `_mounted_interact_3x3` name (the assertion itself, "9 planted
on an empty 3x3 patch," still holds unchanged since all 9 cells start
empty in that test). This is the one existing test file you ARE
expected to touch, for the rename only — do not change its other
assertions.

Also add a new `tests/test_mounted_interact_3x3.gd` covering:
- Mounted interact on a 3x3 area with a mix of empty/growing/harvest-ready
  plots correctly plants the empty ones, waters the growing ones, and
  harvests the ready ones, in one call.
- The summary dialogue line reflects the actual per-category counts.
- Unmounted behavior is unaffected (existing single-cell tests for
  plant/water/harvest must still pass unchanged — do not edit those
  test files).

## Constraints

- Do not touch `GridManager.gd`.
- Do not add any new input action, touch gesture, or "charge" mechanic.
- Do not change the unmounted branch of `_try_grid_interact()`.
- Run `bash scripts/ci/run_gate.sh all` before considering this done;
  must stay green.
- No git/gh actions — stop after code + tests are written and the gate
  is green. Do not commit, push, open a PR, or merge.
