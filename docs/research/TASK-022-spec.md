# TASK-022 — Loi Krathong Seasonal Festival (Cozy Gameplay)

**Status:** `todo` | **Priority:** medium | **Category:** gameplay | **Owner:** narrative-lead
**Files:** `scenes/festival/`, `scripts/autoload/GameData.gd`, `scenes/core/TimeManager.gd`, `scripts/narrative/DialogueDB.gd`

## Godot 4 Nodes / APIs Required
- `TimeManager` (`scenes/core/TimeManager.gd:22` seasons `["hot","monsoon","cool"]`, `season_changed` signal) — add `cool` seasonal festival trigger on day 7 cool season (Loy Krathong).
- `SignalBus` (`scripts/autoload/SignalBus.gd:12` `show_dialogue`, new `festival_triggered(festival_name: String)`) — emit on festival start, HUD listens for banner.
- `Main.tscn` `YSort` + `WorldRender` pond area (`water_lotuspond` at `Vector2i(2,1)`) — spawn floating krathong instances (Sprite2D + Area2D).
- `GameData` `harmony`, `inventory` — reward: `krathong` craft = `lotus_root` + `banana_leaf` (existing items), +5 harmony on release.

## Script Interfaces
- `FestivalManager.gd` (autoload or Main child): `func try_trigger_festival(day:int, season:String) -> bool`, `func craft_krathong() -> bool`, `func release_krathong() -> void`
- `GameData.add_item("krathong",1)`, `add_harmony(5)`, `SignalBus.festival_triggered.emit("loy_krathong")`
- Strict typing: `func craft_krathong() -> bool`, `func release_krathong() -> void`, `@export var festival_day: int = 7`

## Zero-Combat / Cozy Constraints
- No fail state: festival is ambient, krathongs drift and fade, no timers or penalties.
- Dialogue via `DialogueDB` (seasonal, no exposition): Elder/Child alternate lines on festival night.
- Visual only: pond shader tint + lantern glow, no combat.

## Acceptance
- Festival triggers once per cool season day 7, banner via `show_dialogue` + `festival_triggered`.
- Player can craft krathong if has lotus, release at pond (proximity Area2D) → +5 harmony, item consumed.
- Headless: `TimeManager.set_time(7,19,0)` + `set_season("cool")` → `festival_triggered` emitted; `gdlint` clean, 54/54 + 50/50 green.
