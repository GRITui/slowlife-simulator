# TASK-319 — Fishing competition festival event

**Status:** `todo` | **Priority:** low | **Category:** gameplay | **Owner:** backend-automation
**Files:** `scenes/festival/FishingCompetitionTrigger.gd`, `scenes/core/Main.gd`

## Godot 4 Nodes / Scripts / APIs Required
- `FishingSpot` (`scenes/interactables/FishingSpot.gd:1`): Skill-gated fishing with 20 species, rarity-weighted roll, 3 size variants. Requires `fishing_skill` check.
- `SignalBus.time_manager` (`scenes/core/TimeManager.gd:22`): Provides `day`, `hour`, `current_season`, `day_of_season()`, `year()` for festival timing.
- `SignalBus.festival_triggered` (`scripts/autoload/SignalBus.gd:32`): Emitted on festival start, HUD listens for banner.
- `GameData.fishing_skill` (`scripts/autoload/GameData.gd:67`): Gates rare fish, should gate competition entry.

## Expected Behavior
- Fishing competition festival runs in hot season, day 15, 10:00-16:00 window. Triggered once per year via `minute_ticked` hook, similar to Songkran.
- Requires fishing skill >=2 to enter (beginner can't compete). Dialogue: "Fishing competition today at the canal! Skill 2+ to enter."
- Rewards: Rare fish catch during competition grants +2 harmony bonus and competition points. Top 3 placements get silver rewards.

## Technical Constraints
- Use `SignalBus.time_manager` registry pattern, not hard node paths.
- Zero-combat, cozy celebration, no fail state for not entering.
- Headless-safe: Check `SignalBus.time_manager` exists before accessing.

## Acceptance Criteria
- Headless test: FishingCompetitionTrigger instanced in Main, triggers at hot day 15 12:00 with skill 2, not before, not twice.
- Existing run_tests 100/100 and run_engine_tests 50/50 still green.
