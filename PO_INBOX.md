# PO Inbox — directive from Head of Art (2026-09-01, round 12)

## 1. PRIORITY BUG — Issue #158 — quest system unreachable at two levels

Ran a systematic check of every `GameData.gd` state-mutator against real (non-test) callers. Two independent breaks: (a) the 9 richly-authored `QuestData` `.tres` resources in `data/quests/` are a different format from what `QuestLog.gd` actually loads (`data/quests/quests.json`, which only has 2 quests) — nothing reads the `.tres` files at all; (b) even those 2 `quests.json` quests can never start — `QuestLog.offer_quest()` has zero callers anywhere. A player cannot receive a quest right now, full stop. Full write-up and recommendation (migrate the 9 `.tres` quests' content into `quests.json`'s schema, wire `offer_quest()` to each `giver_npc_id`'s interact) is in the issue. Not claiming — trigger/pipeline wiring.

## 2. PRIORITY BUG — Issue #159 — buffalo affinity/hearts fully disconnected

`GameData.add_buffalo_affinity()` has zero callers; `Buffalo.gd`'s interact grants unlimited uncapped milk and never touches affinity. `GameData.buffalo_hearts()` also has zero callers — nothing reads it to display. The hearts UI (issue #129/TASK-271, already shipped art-lane) has no live data behind it. Recommend: daily-cap the interact (mirror `last_offering_day` pattern), call `add_buffalo_affinity()` on it, wire `buffalo_hearts()` into HUD or an interact display. Not claiming — gameplay-loop wiring.

## 3. Issue #160 — tool tiers: owner decision + fix needed

`GameData.upgrade_tool()` has zero callers — same dead-code pattern, a full tier-cost system nobody can trigger. **Owner decision:** keep and fix tool tiers (don't retire in favor of the mount). Framing: hoe/watering-can/sickle tiers are the permanent solo-farming upgrade path; the Wing Kwai mount's 3x3 auto-plow is a separate situational "riding tool," available only while mounted — complementary tracks, not competing ones, document that framing wherever tool tiers get exposed. Recommend wiring `upgrade_tool()` to Handler's interact (closest thematic fit, no blacksmith NPC exists). Not claiming — trigger wiring.

## 4. Issue #161 — new: 3-channel sell economy (owner-directed, full spec in issue)

Three sell channels, each on a different axis, none redundant: **Cart Trader** (the `trader` NPC's cart visits the farm each evening, base `SELL_PRICES`, silver-only, no travel cost — convenience). **Market Stall** (existing `MarketStallNPC`, +15% price premium on top of what's already there — barter, seasonal dialogue — rewards travel time with both price and flavor). **Specialty Buyer** (affinity-gated at "close" tier via `GameData.get_affinity()` — already live, deliberately NOT the broken quest system — Fah buys rare fish, Niran buys durian/mango at +45% premium, capped 3/week on a Binthabat-style reset). Full numbers in the issue. Not claiming the economy logic (SELL_PRICES multipliers, weekly-cap tracking, evening-visit trigger) — core script. **Claiming and building now, art-lane:** the Trader's visual — no character art exists for `trader` at all yet, despite the id being referenced in `GIFT_PREFERENCES` since early in the project. Building an idle sprite + cart prop now so it's ready the moment the visit-trigger lands.

## 5. Prior round — fully resolved

Issue #155 (Wing Kwai unreachable) — you fixed this (`fix(TASK-303): race reachable — RaceStarter official stand + flag course live`, PR #157) and it looks like `WingKwaiCourse.tscn` got wired in too. Nothing outstanding from round 11.
