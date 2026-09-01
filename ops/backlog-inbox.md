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
  <status>COMPLETED</status>
  <priority>HIGH</priority>
  <title>Mining/ore resource loop (MVP scope, redesigned from floor-gen concept)</title>
  <description>Deliberately smaller than the original "multi-floor mines with ladder digging" idea (that's a full traversal/floor-gen subsystem — highest scope-creep risk on the list). Mirrors FishingSpot.gd's existing pattern instead: single interactable, rarity-weighted roll against data/ore/ore.json (copper/iron/silver), skill gating that grows with use, stamina-gated. GameData.upgrade_tool() now requires ore per tier as the tool-upgrade sink. No new .tscn — dynamically instanced like FishingSpot. Merged f1b9f87, pushed.</description>
  <researcher_notes>Implemented by Cline (minimax-m3:free) after switching from slow OpenCode/GLM-5.3-Flash mid-task. Code Quality Review caught and fixed a line-offset editing corruption in test_mining.gd (session then hit an OpenRouter rate-limit mid-self-repair) — GameData.gd/MiningSpot.gd themselves were clean. Also fixed a latent FishingSpot.gd bug (proximity Area2D never wired) in MiningSpot.gd without touching FishingSpot itself. Full record: ops/ai-eng-log.md run 10. Spec: docs/research/TASK-321-spec.md.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-322</id>
  <source>AI-LOOP</source>
  <status>COMPLETED</status>
  <priority>HIGH</priority>
  <title>Farm/house building upgrades (carpenter-equivalent sink)</title>
  <description>Implemented as a carpenter house-kitchen upgrade (50 silver + 5 wood + 20 stamina), reusing the existing infrastructure registry (GameData.repair_infrastructure/is_repaired, same pattern as SluiceGate) rather than a new mechanic. Unlocks two new house_kitchen-gated recipes (khao_soi, massaman_curry). Scene built by Claude (UI tier), script/data/test by OpenCode. Merged 7df45e8, pushed.</description>
  <researcher_notes>Code Quality Review caught a speculative-deduct-then-refund pattern that double-fired SignalBus.silver_changed — fixed to check-then-deduct matching SluiceGate.gd. Also surfaced and fixed an unrelated regression in tests/test_silver.gd from TASK-327 (commit 9679f23). Full record: ops/ai-eng-log.md run 8. Spec: docs/research/TASK-322-spec.md.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-323</id>
  <source>AI-LOOP</source>
  <status>COMPLETED</status>
  <priority>MEDIUM</priority>
  <title>Livestock depth: quality tiers (split A) + breeding (split B) — both done</title>
  <description>Split A: quality-tier items (buffalo_milk_high/egg_gold) at 3+ hearts (76f922c). Split B (Sprint 1): herd-count sink (chicken_count/buffalo_count, 1..3) scaling egg/milk yield, grown automatically via breeding on the daily interact once hearts>=2 + silver available — no new animal entities, mirrors the existing skill-growth idiom. Merged 9aa8f59, pushed.</description>
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
  <status>COMPLETED</status>
  <priority>LOW</priority>
  <title>Working pets/mounts (redesigned: companion bond + race tie-in)</title>
  <description>Investigation found riding+racing already shipped (BuffaloRace.gd/TASK-270, buffalo mount/TASK-272) — a literal horse would re-skin an existing mechanic. Real gap: the existing cat companion (CompanionNPC.gd/TASK-048) had no progression. Added GameData.companion_bond mirroring buffalo_hearts, passive accrual via minute_ticked while nearby, and a bonus tie-in to the existing race system at bond tier 2+. Merged f5cb512, pushed.</description>
  <researcher_notes>Source: Gemini gap analysis, AI-ENG-001. Lowest priority on Gemini's own ranking; flagging for completeness.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-326</id>
  <source>AI-LOOP</source>
  <status>COMPLETED</status>
  <priority>LOW</priority>
  <title>Shipping-milestone stamina progression (redesigned from: stamina upgrades + shipping-triggered seed unlocks)</title>
  <description>Redesigned before implementation: the seed-unlock half no longer made sense after TASK-327 made every seed purchasable. Merged into one mechanic — lifetime_items_shipped crossing [25,50,100,200] permanently grants +15 max_stamina each, capped at 160.0, mirroring the existing veteran_year pattern. Implemented by OpenCode (openrouter/minimax-m3:free), PR #178 merged to main (72c03d1). One code-quality bug found post-merge and fixed forward (redundant SignalBus.stamina_changed emission, commit 8e3adff) — see process-incident note below.</description>
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



<!-- AI-LOOP INCIDENT: 2026-09-01 TASK-326 — OpenCode self-merged via gh (PR #178) before Claude's Code Quality Review ran, reading the AI-ENG-001 standing authorization as license for its own actions. A redundant SignalBus.stamina_changed emission that review would have caught pre-merge was found and fixed forward instead (commit 8e3adff). AI-ENG-001 spec updated: every future OpenCode prompt must now explicitly forbid push/PR/merge, not assume it's understood. Full record: ops/ai-eng-log.md run 7. -->

<!-- PO LEDGER: 2026-09-01 3-sprint plan set for remaining approved backlog (TASK-323 split B, 324, 325) — see docs/SHIP_PLAN.md "Remaining sprint plan". Order: Sprint 1 = TASK-323 split B (smallest, builds on shipped split A), Sprint 2 = TASK-325 (self-contained, lower priority), Sprint 3 = TASK-324 (biggest, most design-sensitive, saved for last deliberately). -->

<!-- AI-LOOP: 2026-09-01 TASK-323 split B (breeding) merged to main, commit 9aa8f59. Sprint 1 of 3-sprint plan complete. Implemented by Cline (minimax-m3:free) for GameData.gd/ChickenCoop.gd before hitting the same OpenRouter rate limit seen in runs 7/10 — both files were clean on review, Claude completed Buffalo.gd (mirroring the reviewed pattern) and wrote the test file directly rather than re-running the task. Verified: test_livestock_breeding.gd 23/23 (new) + 4 existing regression-checked tests + run_tests 100/100 + run_engine_tests 50/50. Full record: ops/ai-eng-log.md run 11. Next: Sprint 2 (TASK-325, pets/mounts). -->

<!-- AI-LOOP: 2026-09-01 TASK-325 (companion bond, redesigned from dog/horse) merged to main, commit f5cb512. Sprint 2 of 3-sprint plan complete. Implemented by Cline (minimax-m3:free) — 4th hit this session on the same OpenRouter rate limit (runs 7/10/11/12), this time right after finishing all 4 files mid final self-verification. Code Quality Review found the 3 implementation files clean; the new test file had 2 real authoring bugs (bare SignalBus identifier unresolvable in a standalone SceneTree script, a tier-math error expecting tier 1 after a single 60-tick grant when a tier needs 25 points) plus a force_finish()-bypasses-start_race() gap leaving _player unset — all fixed directly. Verified: test_companion_bond.gd 33/33 (new) + test_companion.gd 7/7 + test_race.gd 13/13 (regression) + run_tests 100/100 + run_engine_tests 50/50. Full record: ops/ai-eng-log.md run 12. Next: Sprint 3 (TASK-324, rivals + life progression) — final item, closes Phase 2. -->
