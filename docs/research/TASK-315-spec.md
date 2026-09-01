# TASK-315 — Trader cart evening visit trigger and animation

**Status:** `todo` | **Priority:** medium | **Category:** gameplay | **Owner:** backend-automation
**Files:** `scenes/entities/TraderNPC.gd`, `scenes/core/Main.gd`, `scenes/entities/TraderNPC.tscn`

## Godot 4 Nodes / Scripts / APIs Required
- `TraderNPC` (`scenes/entities/TraderNPC.tscn`, `scenes/entities/VillagerNPC.gd` with `npc_id="trader"`): Inherits VillagerNPC generic logic. Uses `Area2D` `InteractArea` radius 48, `Sprite2D` + `CartProp` child, `ScheduleDB` not used (trader has fixed farm position, not schedule drift). Requires evening visibility check via `SignalBus.time_manager` (`hour` 18-21 window).
- `SignalBus.time_manager` (`scenes/core/TimeManager.gd:22`): Provides `hour` and `day` for time window checks. Must be accessed via `SignalBus.time_manager` registry (ENGINE-006 pattern), not hard node path.
- `SignalBus.show_dialogue` (`scripts/autoload/SignalBus.gd:7`): For "Cart's gone" vs sell dialogue.
- `GameData.cheapest_sellable()` / `sell_item()` (`scripts/autoload/GameData.gd:120`): For base-price sell logic (Channel A).
- `Main.gd` `y_sort_enabled` sorting: Trader at farm position `Vector2(2*48+24, 4*48+24)` must be Y-sorted with player.

## Expected Behavior
- Trader appears at farm (near home, cell 2,4) only during 18:00-21:00. Outside window, `visible = false` and `CollisionShape2D.disabled = true`, CartProp moves with trader (sibling sprite, not separate node).
- Interact during window: sells cheapest held item at base `SELL_PRICES` (no premium), shows dialogue "Cart deal: sold X for Y silver. (base price)".
- Interact outside window: shows "Cart's gone for the day — catch me evenings at the farm (6-9pm)."

## Technical Constraints
- Use `DisplayServer.get_display_safe_area()` pattern for mobile? No, farm position is world-space, not UI.
- Do not use desktop-only `Spatial` features; keep to `CharacterBody2D` + `Sprite2D` + `Area2D` (GLES3/Metal compatible).
- Ensure `visible` and collision are synced, and `global_position` is set correctly for Y-sort.

## Acceptance Criteria
- Headless test: `TraderNPC` instance at Main, `visible` true at 19:00, false at 10:00, `_try_trader_sell()` sells at base price.
- Existing `run_tests.gd` 100/100 and `run_engine_tests.gd` 50/50 still green.
