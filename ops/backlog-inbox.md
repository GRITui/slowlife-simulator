# Backlog-Inbox — append-only ledger

> State-driven only. Squads pull READY_FOR_PM items; never direct PM-to-PM contact.
> Sprint 1 = "Match Draft B" (3/4 canon). Sprint 2 starts only after Sprint 1 exit sign-off.

<task_item>
  <id>TASK-005</id>
  <source>OWNER_POPUP</source>
  <status>NEEDS_OWNER_REVIEW</status>
  <priority>HIGH</priority>
  <title>Define 3/4 art rules in ART_STYLE_GUIDE (tile metrics, Y-sort, zoom 2.2 provisional)</title>
  <description>Update ART_STYLE_GUIDE.md with the 3/4 perspective canon per issue #5 REV 2. Ground stays flat 32x32; verticals get tall art; Y-sort origin at feet; zoom 2.2 provisional.</description>
  <researcher_notes>Owner: @visual-inspector. Issue #6. No deps. Refs: docs/art_direction/canon_34_draft_B.png, zoom_framing_comparison.png.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-006</id>
  <source>OWNER_POPUP</source>
  <status>READY_FOR_PM</status>
  <priority>HIGH</priority>
  <title>Generate tall art assets for 3/4 canon (16-color palette)</title>
  <description>Bamboo wall 32x48, structure wall 32x48 front + 32x16 cap, mango 32x64, banana/sluice 32x48, stove 32x40. Dock stays flat. Strict 16-color palette.</description>
  <researcher_notes>Owner: @data-pipeline. Issue #7. Depends: TASK-005 rules (metrics already fixed in issue #5 REV 2 - may start in parallel if rules draft is stable).</researcher_notes>
</task_item>

<task_item>
  <id>TASK-007</id>
  <source>OWNER_POPUP</source>
  <status>READY_FOR_PM</status>
  <priority>HIGH</priority>
  <title>World render: 20x16 tilemap matrix + Y-sort layers + bounds + edge dressing</title>
  <description>Render locked Hybrid A/B layout in Main.tscn: tilemap matrix, Y-sorted prop/character layer, bounds colliders, bamboo ring + Deep Pond backdrop.</description>
  <researcher_notes>Owner: @spatial-architect. Issue #8. Depends: TASK-006 tall art (can scaffold with flat tiles first).</researcher_notes>
</task_item>

<task_item>
  <id>TASK-008</id>
  <source>OWNER_POPUP</source>
  <status>READY_FOR_PM</status>
  <priority>HIGH</priority>
  <title>Camera center-lock in-engine + zoom tune (3/4 canon)</title>
  <description>Player.tscn Camera2D: drag margins off, smoothing off, zoom 2.2 provisional (tune with real art). NOTE: Camera2D 'current' property is gone in Godot 4.7 - use 'enabled'.</description>
  <researcher_notes>Owner: @visual-inspector. Issue #5 (REV 2). Depends: TASK-007 world render for meaningful tuning.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-009</id>
  <source>OWNER_POPUP</source>
  <status>READY_FOR_PM</status>
  <priority>MEDIUM</priority>
  <title>Player walk 8-frame / idle 4-frame animation wiring</title>
  <description>Wire AnimatedSprite2D states. Existing: idle 1 frame, walk_down/right 4 frames. Generate walk_up; left mirrors right if Pha Khao Ma reads OK mirrored.</description>
  <researcher_notes>Owner: @data-pipeline. Issue #9. No hard deps.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-010</id>
  <source>OWNER_POPUP</source>
  <status>NEEDS_OWNER_REVIEW</status>
  <priority>MEDIUM</priority>
  <title>HUD QA + seasonal tint + screenshot capture hook</title>
  <description>Verify HUD anchors + tints per ART_STYLE_GUIDE; add screenshot hook (F12) saving 1600x900 PNG to user:// for director review.</description>
  <researcher_notes>Owner: @visual-inspector. Issue #10. No hard deps.</researcher_notes>
</task_item>

<!-- PO LEDGER: 2026-08-31 TASK-005 -> PR #11 merged (squash), issue #6 auto-closed. Tests 40/40 green. -->
<!-- PO LEDGER: 2026-08-31 hygiene: pruned stale task-005-art-rules ref, visual-inspector handshake synced. Owner locked: repo squad names unchanged (parallel design team), multi-sprint auto-continue after exit gates. -->
<!-- PO LEDGER: 2026-08-31 Sprint1 wave1: TASK-006 PR #14 merged (issue #7), TASK-009 PR #13 merged (issue #9, rebased to strip design team's unpushed 51cfd2b), TASK-010 PR #12 merged (issue #10, design team delivery). Merged main 40/40 green. Remaining Sprint 1: TASK-007 -> TASK-008. -->
<!-- PO NOTE: parallel design team works in /Users/grit/slowlife-game shared checkout; PO loop runs isolated worktrees under /Users/grit/slowlife-game-loop*. TASK-010 was claimed by design team (branch task-010-screenshot-hook) — respected, not duplicated. -->
<!-- SQUAD REPORT: 2026-08-31 TASK-007 spatial-architect done — WorldRender.gd zone matrix + Y-sort + bounds + bamboo ring + Deep Pond backdrop; monk to temple lane; tests 54/54 green (14 new worldrender checks); PR opened for PO gate. Note: headless screenshot hook null-texture under dummy renderer — windowed capture needed for TASK-008 visual evidence. -->

<!-- AI-LOOP: 2026-09-01 AI-ENG-001 run — QA/Balance role. Question: HM:BtN feature-gap comparison against current systems (farming, fishing, festivals, quests, hearts, crafting/cooking, seasons). Gemini's raw list cross-checked against actual code (rg over scripts/, scenes/) before proposing anything below — several claimed gaps were already implemented and are NOT proposed as tasks: stamina system (GameData.gd, fixed cap), basic livestock care (ChickenCoop.gd, Buffalo.gd/TASK-020), marriage as an anniversary-loop ceiling (RomanceNPC.gd/TASK-282). One item is deliberately NOT proposed: a strict multi-year evaluation/deadline score — conflicts with this project's established no-fail-state cozy design philosophy (see TASK-319 spec). Confirmed real gaps below, filed NEEDS_OWNER_REVIEW per AI-ENG-001 since Phase 1 scope (SHIP_PLAN.md) is an owner call, not a default-yes. Full run record: ops/ai-eng-log.md. -->

<task_item>
  <id>TASK-321</id>
  <source>AI-LOOP</source>
  <status>READY_FOR_PM</status>
  <priority>HIGH</priority>
  <title>Mining/ore resource loop</title>
  <description>Zero presence in codebase today (confirmed via rg, no mine/ore/mining matches anywhere). HM:BtN-genre games commonly use a mine as a secondary resource + tool-upgrade-material loop. Would need: node/floor generation, stamina cost, ore drop table, and a sink (tool upgrades) to matter.</description>
  <researcher_notes>Source: Gemini gap analysis, AI-ENG-001. Owner call: is a mining subsystem in MVP scope or stretch (SHIP_PLAN.md Phase 1)? Largest single addition on this list.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-322</id>
  <source>AI-LOOP</source>
  <status>READY_FOR_PM</status>
  <priority>HIGH</priority>
  <title>Farm/house building upgrades (carpenter-equivalent sink)</title>
  <description>Zero presence in codebase (confirmed via rg — no house_upgrade/carpenter/lumber matches). No cash/material sink currently expands house, barn, or coop capacity. This is a core mid-game progression pillar in the genre.</description>
  <researcher_notes>Source: Gemini gap analysis, AI-ENG-001. Owner call: needed for MVP or stretch? Depends on Phase 1 scope decision.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-323</id>
  <source>AI-LOOP</source>
  <status>READY_FOR_PM</status>
  <priority>MEDIUM</priority>
  <title>Livestock depth: quality tiers (DONE, split A) + breeding (split B, open)</title>
  <description>ChickenCoop.gd and Buffalo.gd (TASK-020) already cover basic feed/pet care — that part is NOT a gap. Missing: produce quality scaling with care/heart level, and a breeding/incubator sink to grow the herd without buying. Confirmed absent via rg on ChickenCoop.gd.</description>
  <researcher_notes>Source: Gemini gap analysis, AI-ENG-001. Builds on existing systems rather than new ones — likely lower-cost than TASK-321/322.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-324</id>
  <source>AI-LOOP</source>
  <status>READY_FOR_PM</status>
  <priority>MEDIUM</priority>
  <title>Life-progression events beyond current marriage ceiling</title>
  <description>RomanceNPC.gd (TASK-282) already ships marriage as an annual-anniversary cozy loop — that's NOT a gap. Missing: rival events (a competing suitor if courtship drags on) and pregnancy/childbirth/toddler stages. Rival events specifically may cut against this project's cozy/no-pressure design philosophy — flagging for an explicit owner call rather than assuming it should be built.</description>
  <researcher_notes>Source: Gemini gap analysis, AI-ENG-001. Design-philosophy tension noted, not just a scope question — see TASK-319 spec's no-fail-state precedent.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-325</id>
  <source>AI-LOOP</source>
  <status>READY_FOR_PM</status>
  <priority>LOW</priority>
  <title>Working pets/mounts (dog training, horse riding/racing)</title>
  <description>Confirmed absent (rg found only an unrelated "pet via interact" verb usage in Buffalo.gd, not a pet/mount system). HM:BtN has a trainable dog (festival racing) and a horse (transport + racing).</description>
  <researcher_notes>Source: Gemini gap analysis, AI-ENG-001. Lowest priority on Gemini's own ranking; flagging for completeness.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-326</id>
  <source>AI-LOOP</source>
  <status>READY_FOR_PM</status>
  <priority>LOW</priority>
  <title>Permanent stamina upgrades + shipping-triggered seed unlocks</title>
  <description>Two smaller items bundled: (1) max_stamina is a fixed 100.0 constant in GameData.gd today — no collectible/upgrade path exists to raise it. (2) No system ships crops toward a cumulative threshold that unlocks new seeds — confirmed absent via rg.</description>
  <researcher_notes>Source: Gemini gap analysis, AI-ENG-001. Both are additive to existing systems (stamina, shipping bin) rather than new ones.</researcher_notes>
</task_item>

<!-- AI-LOOP: 2026-09-01 Producer-role pass — cost/impact sequencing for TASK-321..326. Not a Gemini call: engineering cost requires codebase knowledge Gemini doesn't have, so this synthesis is Claude's own. This is a SEQUENCING RECOMMENDATION only — none of TASK-321..326 change out of NEEDS_OWNER_REVIEW; scope inclusion is still the owner's call (SHIP_PLAN.md Phase 1).

Recommended order if approved, best cost/impact ratio first:
1. TASK-323 (livestock depth) — LOW cost, extends existing ChickenCoop.gd/Buffalo.gd, no new subsystem. MEDIUM-HIGH impact.
2. TASK-326 (stamina upgrade + shipping unlock) — LOW cost, additive to existing stamina/shipping-bin code. MEDIUM impact. Bundles well with #1.
3. TASK-322 (house/building upgrades) — HIGH cost (new economy sink, carpenter NPC, multi-stage unlock). HIGH impact, core genre pillar.
4. TASK-321 (mining/ore) — HIGHEST cost (new subsystem: floor gen, stamina interaction, drop tables, tool-upgrade sink). HIGH impact but highest scope-creep risk of the six.
5. TASK-324 (rival events + pregnancy/toddler) — cost unknown until the design-philosophy question is resolved; sequenced after the others since it's blocked on a decision, not on capacity.
6. TASK-325 (working pets/mounts) — MEDIUM cost, LOW-MEDIUM impact. Correctly ranked lowest by Gemini's own analysis too; last unless cut entirely. -->

<!-- PO LEDGER: 2026-09-01 Owner scope decision — TASK-321..326 all approved for MVP scope, status flipped NEEDS_OWNER_REVIEW -> READY_FOR_PM. TASK-324 approved in FULL scope (rivals + pregnancy/childbirth/toddler), explicitly accepting the tension with the no-fail-state precedent (TASK-319) rather than avoiding it — implementation should still aim to build rival "pressure" without a hard fail-state where possible, since those aren't mutually exclusive, but the scope inclusion itself is decided. SHIP_PLAN.md Phase 1 exit criteria now clear. Sequencing recommendation from the earlier Producer-role note stands unless re-prioritized at pull time. -->

<!-- AI-LOOP: 2026-09-01 TASK-323 split A (quality tiers) merged to main, commit 76f922c. buffalo_milk_high/egg_gold at 3+ hearts, mirrors existing buffalo_affinity pattern exactly (now added for chickens too). Implemented by OpenCode (openrouter/minimax-m3:free), worktree-isolated, verified run_tests 100/100 + run_engine_tests 50/50 + new test_livestock_quality.gd 16/16 before merge, per AI-ENG-001 judgment gate + standing auto-merge authorization. Split B (breeding/incubator sink) intentionally deferred — bigger scope, needs its own design pass before delegating. TASK-323 status stays READY_FOR_PM until split B is picked up. Full record: ops/ai-eng-log.md. -->

<task_item>
  <id>TASK-327</id>
  <source>CLAUDE</source>
  <status>COMPLETED</status>
  <priority>high</priority>
  <title>Seed purchasing + market shop UI (blocker found while scoping TASK-326)</title>
  <description>Only jasmine_rice was actually plantable in real play — the other 23 crops had seed_item_id but nothing sold that item, and interact() at the market stall only auto-cascaded barter-&gt;sell-&gt;buy-first-affordable, unusable for a 24-crop catalog. Added seed entries to MarketManager.BUY_OFFERS per crop season, built a new selectable MarketShop.tscn/.gd panel (registered via SignalBus.market_shop), rewired MarketStallNPC.interact() to open it, removed the now-dead old cascade code.</description>
  <researcher_notes>Self-built (UI/.tscn is Claude's own tier per CLAUDE.md), not delegated to OpenCode. Filed and built ahead of TASK-321..326 per owner decision 2026-09-01 — more foundational. Merged commit 11d734e, pushed. Verified run_tests 100/100, run_engine_tests 50/50, test_market_multi.gd 6/6 (regression), new test_market_shop.gd 9/9, test_touch_targets.gd 10/10 (MarketShop.tscn added to its scan list). Spec: docs/research/TASK-327-spec.md. Full record: ops/ai-eng-log.md.</researcher_notes>
</task_item>


