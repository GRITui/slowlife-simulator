# TASK-318 — Seasonal crop growth balancing and stamina tuning

**Status:** `todo` | **Priority:** medium | **Category:** gameplay | **Owner:** backend-automation
**Files:** `scripts/resource_types/CropData.gd`, `scenes/core/GridManager.gd`, `data/crops/*.tres`

## Godot 4 Nodes / Scripts / APIs Required
- `CropData` (`scripts/resource_types/CropData.gd:11`): `growth_minutes_per_stage: Array[int]`, `total_stages`, `season_yield_multiplier`, `is_plantable_in(season)`, `get_growth_minutes(stage, season)` etc.
- `GridManager` (`scenes/core/GridManager.gd:49`): `plant(cell, crop)` checks `is_plantable`, `is_plantable_in`, `required_infrastructure`, `stamina_cost_plant`, seed consumption, and creates `PlotState` with `stage=0`.
- `GameData` (`scripts/autoload/GameData.gd:8`): `current_stamina`, `max_stamina`, `stamina_cost_plant` handling.
- `TimeManager` (`scenes/core/TimeManager.gd:22`): `current_season`, `season_duration_days` (10 days per season), `stamina_drain_multiplier` per season.

## Expected Behavior
- After 22 crops unlocked via `Player._find_crop_for_held_seed()` (TASK-043), some crops have growth times that are too fast/slow relative to season lengths (10 days = 14400 minutes per season at 1 minute per real second? Actually 6.0 minutes per real second, but balancing is about in-game minutes).
- Growth balancing: Ensure each crop's total growth time is proportional to its season's yield multiplier and intended difficulty. Faster crops should be more common, slower crops more rewarding.
- Stamina tuning: Planting stamina cost should be balanced so player can plant 5-8 crops per day without exhausting, but not unlimited.

## Technical Constraints
- Keep `total_stages` at 4 for all crops (consistent with `TASK-310` stage rendering).
- Ensure `growth_minutes_per_stage` arrays have 4 entries, last is 0 (harvest stage).
- Balance so that total growth time per crop is between 3-6 days (4320-8640 minutes), with faster crops for common items and slower for rare.
- Stamina costs: Planting should cost 5-8 stamina per crop, allowing 12-20 plants per full stamina bar (100/5=20).

## Acceptance Criteria
- Headless test: Verify all 22 crops have `total_stages==4` and `growth_minutes_per_stage.size()==4`.
- Verify each crop's total growth time is within 3-6 days and `season_yield_multiplier` values are 0.6-1.8 range.
- Verify `GridManager.plant` still respects `is_plantable_in` and `stamina_cost_plant`.
- Existing `run_tests.gd` 100/100 and `run_engine_tests.gd` 50/50 still green.
