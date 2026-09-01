# TASK-102 — Market stall dedicated art + krathong item icon

**Status:** `proposed` | **Priority:** low | **Category:** art | **Owner:** art-po
**Sprint:** 7 of 10 (Head-of-Art roadmap, 2026-09-01)

## Findings

Two small asset gaps found in the Head-of-Art survey:
- `MarketStall.tscn` (TASK-025, evening barter economy) has no dedicated sprite — it currently reuses `clay_stove_tall.png` as a placeholder.
- `FestivalManager.gd` calls `GameData.add_item("krathong", 1)` (TASK-022) but `assets/items/` has no `krathong.png` — the item exists in data with no visual representation (inventory slot would render blank/missing-texture for it today).

Note: recipe icons (`pandan_sticky_rice.png`, `thai_basil_stirfry.png`, `mango_sticky_rice.png`, `lotus_soup.png`) are already complete — verified present, not part of this task.

## Plan

1. Author `assets/environment/market_stall.png` — 48x96 tall-art canon (matches other tall verticals per `ART_STYLE_GUIDE.md`), Clay Brown/Soil Tan palette, distinct silhouette from the clay stove it's currently borrowing.
2. Author `assets/items/krathong.png` — 48x48 item-icon canon, Lotus Pink/Jasmine Gold (banana-leaf + flower + candle motif consistent with the festival's existing visual language).
3. Wire `market_stall.png` into `MarketStall.tscn`'s sprite (single texture swap); `krathong.png` needs no wiring beyond existing — `GameData.inventory`/HUD slot rendering already looks up by item id, so dropping the PNG at the expected path is sufficient (verify exact lookup path in `HUD.gd:refresh_inventory` / item-icon resolution before assuming zero-code).

## Acceptance

- `MarketStall.tscn` no longer visually duplicates the clay stove.
- Krathong item renders correctly in inventory once picked up during the festival event.

## Risk

Very low — isolated asset + one texture swap, no shared-system touch.
