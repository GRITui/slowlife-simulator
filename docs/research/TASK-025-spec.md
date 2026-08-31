# TASK-025 — Evening Market Stall & Barter Economy (Cozy Gameplay)

**Status:** `proposed` | **Priority:** medium | **Category:** gameplay | **Owner:** narrative-lead
**Files:** `scenes/market/`, `scripts/autoload/GameData.gd`, `scenes/ui/HUD.gd`, `scripts/narrative/DialogueDB.gd`

## @scout Findings
- `GameData.inventory` already supports barter (has_item/remove_item/add_item), but only `SluiceGate` uses it (rice → pandan). No player-to-villager trade loop.
- `HUD` `InventoryRow` 4 slots displays inventory but no barter UI; `SignalBus.show_dialogue` used for all NPCs (VillagerNPC, MonkNPC, Buffalo) — extensible to market.
- `PROJECT_VISION.md:4` "village goodwill, seasonal festivals, serene interaction" — market stall extends goodwill without combat/economy stress (no gold, no fail).

## Godot 4 Nodes / APIs
- `MarketStall.tscn` (`StaticBody2D` + `Area2D` `InteractArea` radius 48, `Sprite2D` `market_stall_tall.png` reuse) at village center `Vector2(480,320)` (home zone, plantable_soil adjacent).
- `MarketManager.gd`: `func get_offers(season:String) -> Array[Dictionary]` (seasonal: cool → sticky_rice, hot → mango, monsoon → lotus), `func barter(have_id:String, want_id:String) -> bool` (1:1, no gold).
- `GameData.barter(have_id, want_id)` → inventory swap, `SignalBus.barter_completed.emit(have_id,want_id)` (new) + `show_dialogue` cozy line.

## Zero-Combat / Cozy
- 1:1 barter only, no pricing, no debt, no timer. Villager line via `DialogueDB` seasonal: "Trade? Lotus for sticky rice — share the harvest."
- Failure is soft: `show_dialogue` "Not enough to trade" — no penalty.

## Acceptance (for future `todo`)
- Stall at `(480,320)` visible, prompts `[E] to barter` via `HUD.update_prompt_for_proximity`.
- Seasonal offers rotate via `TimeManager.season`; barter 1:1 updates `inventory` and emits `barter_completed`.
- `gdlint` clean, `godot --headless` 54/54 + 50/50; no direct UI coupling.
