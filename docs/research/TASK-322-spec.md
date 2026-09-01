# TASK-322 — House upgrade (kitchen extension) via existing infrastructure pattern

**Status:** `todo` | **Priority:** high | **Category:** gameplay/economy | **Owner:** OpenCode (script+data) + Claude (scene, per CLAUDE.md UI tier)
**Files:** `scenes/interactables/CarpenterUpgrade.tscn` (new, Claude), `scripts/interactables/CarpenterUpgrade.gd` (new, OpenCode), `data/recipes/recipes.json` (OpenCode), `tests/test_carpenter_upgrade.gd` (new, OpenCode)

## Design
Reuses this repo's existing `infrastructure: Dictionary` registry
(`GameData.repair_infrastructure`/`is_repaired`) exactly as
`SluiceGate.gd` already does — no new mechanic invented, same pattern
extended to a new structure. `CropData`/`RecipeData` already support a
`required_infrastructure` gate (`SluiceGate` uses this for pandan/lotus
crops); this task uses the same field on two new recipes instead.

- New interactable `CarpenterUpgrade` (`structure_id = "house_kitchen"`),
  scene built by Claude mirroring `scenes/interactables/SluiceGate.tscn`
  node-for-node (StaticBody2D + Sprite2D + Area2D InteractArea +
  PromptLabel), reusing `res://assets/environment/structure_wall_front.png`
  — no new art needed.
- Script `CarpenterUpgrade.gd` mirrors `SluiceGate.gd`'s `_try_repair()`
  contract closely, with a silver cost added (this is meant to be a
  genuine cash sink per the original TASK-322 gap, not just another
  material barter like the sluice gate):
  - Cost: 50 silver + 5 wood + 20.0 stamina.
  - On success: `GameData.spend_silver(50)`, `GameData.remove_item("wood", 5)`,
    stamina deducted, `GameData.repair_infrastructure("house_kitchen")`,
    `GameData.add_harmony(5)`, dialogue announcing the unlock.
  - Soft-fail dialogue per missing requirement (silver / wood / stamina),
    matching `SluiceGate.gd`'s pattern — no hard fail state.
- Two new recipes in `data/recipes/recipes.json` with
  `"requires_infrastructure": "house_kitchen"` — pick two ingredient
  combinations from *already-existing* inventory items only (no new items),
  priced/rewarded consistent with the existing recipe table's ranges (see
  existing entries for scale, e.g. `thai_basil_stirfry` harmony 14,
  `tom_yum` sell price 18).

## Acceptance Criteria
- Before `house_kitchen` is repaired, the two new recipes never appear in
  `CookingStation.get_all_craftable()`/`get_craftable()` regardless of
  held ingredients (mirrors how `SluiceGate`-gated crops behave).
- After repair, they do appear (given ingredients + season match) and are
  craftable.
- Repair costs exactly 50 silver + 5 wood + 20.0 stamina once; a second
  interact after repair is a no-op dialogue, not a double-charge (mirrors
  `SluiceGate.gd`'s `is_repaired` early-return).
- `run_tests.gd` / `run_engine_tests.gd` stay green.
