# TASK-326 — Shipping-milestone stamina progression

**Status:** `todo` | **Priority:** low | **Category:** gameplay/economy | **Owner:** OpenCode (AI-ENG-001)
**Files:** `scripts/autoload/GameData.gd`, `tests/test_shipping_stamina.gd` (new)

## Scope note — redesigned from the original backlog description
The original TASK-326 (`ops/backlog-inbox.md`) bundled two ideas: permanent
stamina upgrades, and "ship X crops to unlock a secret seed." The second
half's premise no longer holds after TASK-327: *every* crop with a season
is now purchasable in the market shop, so there's no locked seed left to
unlock via shipping — a genuinely new "secret" reward would need a new
crop resource (new sprites, new art), which is out of scope for a
GDScript-only pass and belongs to the art/UI tier, not this task.

Redesign: merge both halves into one coherent, no-new-art mechanic —
shipping milestones grant permanent stamina, mirroring this repo's
existing `veteran_year`/`veteran_yield_bonus()` pattern (long-term
progression via a simple tier derived from a lifetime counter, not new
content). This is a scoping call made under the project's Designer
tier, not a fresh game-direction decision — documented here for
transparency rather than re-escalated.

## Design
- `GameData.lifetime_items_shipped: int = 0` — incremented by 1 on every
  successful `sell_item()` or `sell_item_premium()` call (any item, matches
  how HM-style shipping bins count all goods, not just crops).
- `GameData.stamina_tier: int = 0` — tracks the highest tier already
  granted, so a threshold only ever grants once.
- Thresholds: `[25, 50, 100, 200]` lifetime items shipped → tiers 1-4.
  Crossing a new threshold: `max_stamina += 15.0`, `current_stamina += 15.0`
  (grant the buffer immediately, don't make the player wait for tomorrow),
  emit `SignalBus.stamina_changed(current_stamina, max_stamina)` (existing
  signal, already consumed by `Player.gd`/`HUD.gd` — no new signal needed).
- Cap at tier 4 (matches the existing `buffalo_hearts()` 4-tier cap
  convention) — max_stamina caps at 100 + 4*15 = 160.

## Acceptance Criteria
- Selling items via `sell_item()` or `sell_item_premium()` increments
  `lifetime_items_shipped` and grants stamina exactly once per threshold
  crossing, never twice.
- `max_stamina`/`current_stamina` and the `stamina_changed` signal reflect
  the new value immediately on the crossing sale, not on next load.
- Existing stamina-consuming tests (planting/harvesting stamina costs)
  still pass unaffected — this only ever raises the ceiling, never touches
  `current_stamina`'s clamp logic itself.
- `run_tests.gd` / `run_engine_tests.gd` stay green.
