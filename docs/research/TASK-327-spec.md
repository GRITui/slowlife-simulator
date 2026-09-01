# TASK-327 — Market shop UI: seed purchasing + wire dead BUY_OFFERS code

**Status:** `in_progress` | **Priority:** high | **Category:** gameplay/economy | **Owner:** orchestrator (Claude Code)
**Files:** `scripts/market/MarketManager.gd`, `scenes/entities/MarketStallNPC.gd`, `scenes/ui/MarketShop.tscn` (new), `scenes/ui/MarketShop.gd` (new), `tests/test_market_shop.gd` (new)

## Discovery (AI-ENG-001-adjacent, found while scoping TASK-326)
Only `jasmine_rice` is actually plantable in real play. All 23 other crop
resources in `data/crops/` have a `seed_item_id`, but nothing sells that
item: harvest never returns seeds (`GridManager.harvest()` only grants
`yield_item_id`), and no seed is in `MarketManager.BUY_OFFERS`.

Correction to an earlier read of this: `get_buy_offers()` is not dead code
— `MarketStallNPC._try_barter()` (bound to `interact`) already cascades
barter → sell-cheapest-held → buy-first-affordable-offer. That cascade
works fine for the 3 existing buy items (fish_sauce/shrimp_paste/tools)
but breaks down completely for a 24-crop seed catalog: one `interact`
press would silently buy whichever seed happens to be first in list order
and affordable, with zero player control over which one. A real
selectable shop UI is the fix, not just adding BUY_OFFERS entries — filed
ahead of TASK-321..326 per owner decision 2026-09-01 since it's more
foundational.

## Design
Single coherent shop panel, opened by the existing `interact` action at
the market stall (no new keybind — this project targets iOS, a keybind
like Settings.tscn's F10 isn't touch-appropriate):
- `MarketStallNPC.interact()` now opens `MarketShop` (a `CanvasLayer`
  panel, pattern mirrors `Settings.tscn`) instead of auto-bartering.
- The panel shows: (a) today's barter offer with a confirm button (moves
  the existing barter logic behind an explicit button instead of
  auto-triggering on interact), and (b) a scrollable list of silver-buy
  offers — seeds for every crop plantable in the current season (except
  `jasmine_rice`, which stays free per the existing exception) plus the
  already-defined `fish_sauce`/`shrimp_paste`/tool entries.
- Each buy row: name, price, a Buy button sized to the project's 44x44pt
  minimum touch target (`CLAUDE.md` constraint). Buying calls
  `GameData.spend_silver()` + `GameData.add_item()`, disabled/greyed if
  silver is insufficient — no fail dialogue needed, just non-interactive.
- Close via the same interact button when the panel is open, or a close
  button in-panel (touch-first, don't rely on a desktop-only Escape key).

## Seed price table (added to `MarketManager.BUY_OFFERS`, per season)
Priced by rough tier: quick/simple crops cheaper, perennial fruit trees
and specialty crops pricier. Not exhaustive game-balance tuning — a
reasonable first pass, adjustable later without any structural change.

| Crop | Season(s) | Price |
|---|---|---|
| cabbage, garlic, lettuce | cool | 8 |
| tomato | cool | 10 |
| chili, sesame, peanut | hot | 9 |
| banana | hot | 15 |
| durian, mango | hot | 30 |
| sugarcane, watermelon | hot | 18 |
| ginger, taro, water_spinach | monsoon | 10 |
| lotus_root | monsoon | 12 |
| coconut, eggplant, papaya, soybean, thai_basil, yardlong_bean, sticky_rice, pandan | all 3 | 12–20 (coconut/papaya 20, others 12–15) |

`jasmine_rice` intentionally excluded — stays free via the existing
`GridManager.plant()` exception, not duplicated as a purchase.

## Acceptance Criteria
- Every crop in `data/crops/` (except `jasmine_rice`) is purchasable via
  the market shop when its season is active.
- Existing barter flow (`test_market_multi.gd` and any barter-dependent
  test) still passes — barter moved behind a button, not removed.
- New test (`test_market_shop.gd`) verifies: shop opens on interact, a
  seasonal seed purchase deducts correct silver and grants the item,
  insufficient silver blocks purchase without deducting.
- `run_tests.gd` / `run_engine_tests.gd` stay green.
- Touch targets meet 44x44pt per `CLAUDE.md`.
