# TASK-029 — Crafting UI wiring: Mortar & Pestle + Clay Stove recipes (Gameplay)

**Status:** `proposed` | **Priority:** medium | **Category:** mechanics | **Owner:** data-pipeline
**Files:** `scenes/interactables/CookingStation.tscn`, `scripts/resource_types/RecipeData.gd`, `data/recipes/recipes.json`, `scenes/ui/HUD.gd`

## @qa-auditor Findings (technical-debt / dead-content scan)
- `data/recipes/recipes.json` defines 4 recipe outputs and `assets/items/` has their icons (TASK-019, PR #48), but **no scene consumes them** — `scripts/interactables/` contains only `SluiceGate.gd`. TASK-013's crafting is data-only: dead content.
- `RecipeData.gd` exposes `can_craft(inventory, infrastructure)` + `craft(inventory)` with full typing — ready to consume; nothing calls them outside tests.
- Clay stove (32x40) + mortar art exist in `assets/environment/` (TASK-006) — same dead-art pattern TASK-020 fixed for buffalo.

## Plan
- `CookingStation.gd` (StaticBody2D mirror of SluiceGate contract): proximity + interact opens the first craftable recipe; multi-step: mortar (basil → paste) then stove (paste + sticky_rice → thai_basil_stirfry / pandan_sticky_rice).
- Emits via `SignalBus.show_dialogue` + reuse `SignalBus.barter_completed`-style signal `craft_completed(item_id, qty)` (new, in SignalBus).
- HUD `refresh_inventory()` (TASK-018) already picks up inventory changes — no UI coupling.

## Acceptance
- Station at home zone; crafting consumes inputs, adds output icon to inventory row; gates green (content suite extended with a crafting section).

## Risk
- Low — mirrors SluiceGate; recipes validated by `RecipeData.can_craft` before mutation.
