# TASK-350 — Active-seed selection for planting

Owner found via actual play: pressing interact on an empty plot always
plants whichever `seed_*` item happens to come first in
`GameData.inventory`'s Dictionary iteration order — there is no way to
choose a different held seed. Root cause is
`scenes/entities/Player.gd`'s `_find_crop_for_held_seed()`
(`scenes/entities/Player.gd:158-178`), called from both
`_try_grid_interact()` (single-cell plant, line 136) and
`_mounted_interact_3x3()` (buffalo-plow plant, line 94).

Both the input binding and the no-seed fallback are already decided by
the owner (2026-09-02) — this spec is the build-ready scope, do not
relitigate either decision:

- **Input**: one shared Godot `InputMap` action, `cycle_seed` — a
  single underlying function so future controller support is "add a
  binding," not "build a second cycle system." Bind it to `Q` for
  keyboard now (add to `project.godot`'s `[input]` section, same style
  as the existing `interact` action). Do NOT bind a gamepad joypad
  button yet — this project has no gamepad testing capability right
  now and an untested binding is worse than no binding; leave a
  one-line comment in `project.godot` next to the action noting `L1`/
  `LB` is the intended future gamepad binding (mirrors Harvest Moon:
  Back to Nature's R1 tool-cycle) so whoever adds controller support
  later doesn't have to rediscover this decision.
- **Mobile**: tapping the new HUD seed-indicator widget (built below)
  cycles the seed, mirroring `scenes/ui/InteractTap.gd`'s exact
  pattern (a `Control._gui_input()` that fires on
  `InputEventScreenTouch` and synthesizes the `cycle_seed` action via
  `Input.parse_input_event()` — do not just call a cycle function
  directly from the touch handler, keep the same
  touch-becomes-a-real-action-event indirection `InteractTap.gd` uses,
  so anything that already listens for the action keeps working
  identically regardless of input source).
- **No-seed fallback**: when no seed is primed (player owns none),
  planting still falls back to jasmine_rice — preserves the
  no-fail-state guarantee that interact always does something — but
  emits a distinct dialogue line ("No seed selected — planted rice
  instead.") instead of the current silent fallback that gives no
  signal a substitution happened.

## Scope, precisely

### 1. New session-only (NOT saved) state: the "primed" seed

Add a plain instance var directly on `Player.gd`, alongside the
existing `_seed_lookup` static cache (line 180):

```gdscript
var _primed_seed_id: String = "" # TASK-350 — session-only, not persisted
```

Do not add this to `GameData` and do not touch
`scripts/persistence/SaveManager.gd`'s `save_game()`/`load_game()` —
this is UI-only state, not save data, and putting it on `Player.gd`
rather than the `GameData` autoload makes that non-persistence obvious
by construction rather than relying on someone remembering not to
serialize it later.

### 2. `Player.gd` — cycle function + rewritten seed lookup

Add:

```gdscript
## TASK-350: cycle which held seed_* item is "primed" for planting.
## Wraps around; falls back to "" (no seed) if the player holds none.
func cycle_primed_seed() -> void:
	var held: Array[String] = []
	for item_id: String in GameData.inventory.keys():
		if String(item_id).begins_with("seed_") and int(GameData.inventory[item_id]) > 0:
			held.append(String(item_id))
	if held.is_empty():
		_primed_seed_id = ""
		SignalBus.show_dialogue.emit("Farmer", "No seeds to select.")
		return
	held.sort() # deterministic order, not Dictionary iteration order
	var idx: int = held.find(_primed_seed_id)
	_primed_seed_id = held[(idx + 1) % held.size()]
	var crop: Resource = _seed_lookup.get(_primed_seed_id)
	var crop_name: String = String(crop.get("display_name")) if crop != null and "display_name" in crop else _primed_seed_id
	SignalBus.show_dialogue.emit("Farmer", "Seed selected: %s." % crop_name)
```

Wire into `_unhandled_input()` alongside the existing `interact`/mount
checks:

```gdscript
if event.is_action_pressed("cycle_seed"):
	cycle_primed_seed()
```

Rewrite `_find_crop_for_held_seed()` to prefer the primed seed, falling
back to the OLD "first held seed_* item" behavior only if nothing is
primed AND the player holds at least one seed (covers the case where a
seed is picked up but `cycle_primed_seed()` was never pressed — still
useful default behavior, not a regression for players who never touch
the new feature):

```gdscript
func _find_crop_for_held_seed() -> Resource:
	# ... existing _seed_lookup population block, UNCHANGED ...
	if _primed_seed_id != "" and int(GameData.inventory.get(_primed_seed_id, 0)) > 0 \
			and _seed_lookup.has(_primed_seed_id):
		return _seed_lookup[_primed_seed_id] as Resource
	for item_id: String in GameData.inventory.keys():
		if String(item_id).begins_with("seed_") and _seed_lookup.has(String(item_id)):
			return _seed_lookup[String(item_id)] as Resource
	return null
```

If the primed seed's item count hits 0 (player ran out), the function
above already silently falls through to the "first held" behavior on
the next call — no explicit "un-prime on empty" bookkeeping needed,
but DO reset `_primed_seed_id = ""` inside `cycle_primed_seed()` itself
whenever the currently-primed id is no longer in `held` (already
covered by `held.find(_primed_seed_id)` returning `-1`, which wraps to
`held[0]` on the next cycle press — verify this is the behavior you
want with a test, see below).

### 3. No-seed-primed planting fallback dialogue

In `_try_grid_interact()`'s plant branch (line 136) and
`_mounted_interact_3x3()` (line 94), when `_find_crop_for_held_seed()`
returns `null` (no seed held at all — the pre-existing fallback path,
distinct from "a seed exists but isn't primed", which is handled by
section 2 above), keep falling back to `jasmine_rice.tres` but change
the dialogue: replace the existing generic "Planted %s." line for this
specific null-crop case with "No seed selected — planted rice
instead." Only for the truly-no-seeds-held case — a player who DOES
hold seeds (primed or not) still gets the normal "Planted %s." line
using whichever seed the section-2 logic picked.

### 4. HUD seed-indicator widget

New child control under `HUD.tscn`'s root, alongside the existing
`VirtualJoystick`/`InteractTap` mobile controls (same
`anchors_preset`/`grow_*` idiom, positioned clear of both — check
`HUD.tscn`'s current layout before picking a corner). Must:

- Show the currently-primed seed's display name (or "No seed" when
  none primed) as a small label, always visible (not mobile-only —
  desktop/keyboard players benefit from the glanceable state too, only
  the TAP-to-cycle behavior is mobile-only).
- Meet the project's 44x44pt minimum touch-target rule for its
  tappable region (reuse `InteractTap.gd`'s `custom_minimum_size =
  Vector2(88, 88)` sizing precedent, or at minimum 44x44).
- New script `scenes/ui/SeedIndicator.gd`, mirroring
  `InteractTap.gd`'s `_gui_input()`/`Input.parse_input_event()`
  pattern exactly but synthesizing `cycle_seed` instead of `interact`,
  gated to mobile-only for the tap-to-cycle input path (desktop players
  use the `Q` key instead; the label itself stays visible for both).
- `HUD.gd` needs a small update to refresh this label's text — hook
  into whatever the cleanest existing signal path is (check if
  `GameData`/`SignalBus` already has an inventory-changed signal
  `HUD.gd` listens to; if not, poll it the same way
  `HUD.gd`'s existing per-frame/per-tick refresh works — read `HUD.gd`
  in full first, don't add a new signal if an existing update path
  already runs often enough to keep this in sync).
- Follow `ART_STYLE_GUIDE.md`'s established HUD visual spec (Clay
  Brown border, Rice White backing) from TASK-351 — read
  `scenes/ui/HUD.tscn`'s newly-added `StatPanel`
  `StyleBoxFlat_statpanel` sub-resource and reuse the SAME
  `StyleBoxFlat` resource (not a duplicate) for this new widget's
  background, for visual consistency.

## Tests

New `tests/test_seed_selection.gd`:
- Holding 2+ different seeds, `cycle_primed_seed()` advances through
  them in a deterministic (sorted) order and wraps around.
- Planting with a seed primed plants THAT crop, not the
  first-in-inventory one (construct inventory with 2 seed types,
  prime the second, assert the planted crop matches the primed one —
  this is the actual bug fix, the one assertion that matters most).
- Holding zero seeds: `cycle_primed_seed()` leaves `_primed_seed_id`
  empty and shows the "No seeds to select." line; planting still
  succeeds with jasmine_rice AND shows the NEW "No seed selected —
  planted rice instead." line (not the old generic line).
- A seed IS held but never primed (`_primed_seed_id == ""`): planting
  falls back to "first held seed_*" behavior (regression check —
  players who never touch the new feature see unchanged behavior) and
  gets the normal "Planted %s." line, NOT the no-seed-selected line.
- Primed seed runs out (count hits 0): next `cycle_primed_seed()` call
  no longer offers it (moves on to another held seed, or empties out
  and shows "No seeds to select." if it was the only one).
- `SeedIndicator.gd`'s tap synthesizes the `cycle_seed` action
  (mirror however `tests/` already tests `InteractTap.gd`, if such a
  test exists — `grep -rn "InteractTap" tests/` first).

Extend `tests/ui/test_touch_targets.gd` to include the new HUD widget
in its 44x44pt sweep (it should already pass automatically since that
test walks `HUD.tscn`'s interactive controls generically — verify,
don't assume).

## Constraints

- Do not add `primed_seed_id` (or equivalent) to `SaveManager.gd`'s
  serialized payload — this is session-only state, not save data.
- Do not change `_find_crop_for_held_seed()`'s existing `_seed_lookup`
  population logic (lines 161-174) — only the selection logic after it.
- Do not bind a gamepad button for `cycle_seed` yet (see Input section
  above) — leave a comment marking the intended future binding instead.
- Do not touch `_mounted_interact_3x3()`'s per-cell plant/water/harvest
  branching logic beyond swapping in the new crop-selection call it
  already makes via `_find_crop_for_held_seed()`.
- Run `bash scripts/ci/run_gate.sh all` — regression-check any existing
  test that plants via `_find_crop_for_held_seed()`'s old behavior
  (`grep -rn "_find_crop_for_held_seed\|Planted " tests/`) since the
  no-seed dialogue line text changes for one specific case.
- No git/gh actions — stop after code + tests are written and the gate
  is green. Do not commit, push, open a PR, or merge.
