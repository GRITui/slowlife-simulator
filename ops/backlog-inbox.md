# Backlog-Inbox — append-only ledger

> State-driven only. Squads pull READY_FOR_PM items; never direct PM-to-PM contact.
> Sprint 1 = "Match Draft B" (3/4 canon). Sprint 2 starts only after Sprint 1 exit sign-off.

<task_item>
  <id>TASK-005</id>
  <source>OWNER_POPUP</source>
  <status>COMPLETED</status>
  <priority>HIGH</priority>
  <title>Define 3/4 art rules in ART_STYLE_GUIDE (tile metrics, Y-sort, zoom 2.2 provisional)</title>
  <description>Update ART_STYLE_GUIDE.md with the 3/4 perspective canon per issue #5 REV 2. Ground stays flat 32x32; verticals get tall art; Y-sort origin at feet; zoom 2.2 provisional.</description>
  <researcher_notes>Owner: @visual-inspector. Issue #6. No deps. Refs: docs/art_direction/canon_34_draft_B.png, zoom_framing_comparison.png.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-006</id>
  <source>OWNER_POPUP</source>
  <status>COMPLETED</status>
  <priority>HIGH</priority>
  <title>Generate tall art assets for 3/4 canon (16-color palette)</title>
  <description>Bamboo wall 32x48, structure wall 32x48 front + 32x16 cap, mango 32x64, banana/sluice 32x48, stove 32x40. Dock stays flat. Strict 16-color palette.</description>
  <researcher_notes>Owner: @data-pipeline. Issue #7. Depends: TASK-005 rules (metrics already fixed in issue #5 REV 2 - may start in parallel if rules draft is stable).</researcher_notes>
</task_item>

<task_item>
  <id>TASK-007</id>
  <source>OWNER_POPUP</source>
  <status>COMPLETED</status>
  <priority>HIGH</priority>
  <title>World render: 20x16 tilemap matrix + Y-sort layers + bounds + edge dressing</title>
  <description>Render locked Hybrid A/B layout in Main.tscn: tilemap matrix, Y-sorted prop/character layer, bounds colliders, bamboo ring + Deep Pond backdrop.</description>
  <researcher_notes>Owner: @spatial-architect. Issue #8. Depends: TASK-006 tall art (can scaffold with flat tiles first).</researcher_notes>
</task_item>

<task_item>
  <id>TASK-008</id>
  <source>OWNER_POPUP</source>
  <status>COMPLETED</status>
  <priority>HIGH</priority>
  <title>Camera center-lock in-engine + zoom tune (3/4 canon)</title>
  <description>Player.tscn Camera2D: drag margins off, smoothing off, zoom 2.2 provisional (tune with real art). NOTE: Camera2D 'current' property is gone in Godot 4.7 - use 'enabled'.</description>
  <researcher_notes>Owner: @visual-inspector. Issue #5 (REV 2). Depends: TASK-007 world render for meaningful tuning.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-009</id>
  <source>OWNER_POPUP</source>
  <status>COMPLETED</status>
  <priority>MEDIUM</priority>
  <title>Player walk 8-frame / idle 4-frame animation wiring</title>
  <description>Wire AnimatedSprite2D states. Existing: idle 1 frame, walk_down/right 4 frames. Generate walk_up; left mirrors right if Pha Khao Ma reads OK mirrored.</description>
  <researcher_notes>Owner: @data-pipeline. Issue #9. No hard deps.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-010</id>
  <source>OWNER_POPUP</source>
  <status>COMPLETED</status>
  <priority>MEDIUM</priority>
  <title>HUD QA + seasonal tint + screenshot capture hook</title>
  <description>Verify HUD anchors + tints per ART_STYLE_GUIDE; add screenshot hook (F12) saving 1600x900 PNG to user:// for director review.</description>
  <researcher_notes>Owner: @visual-inspector. Issue #10. No hard deps.</researcher_notes>
</task_item>

<!-- HYGIENE: 2026-09-02 TASK-005..010's <status> tags here had never been flipped past
     NEEDS_OWNER_REVIEW/READY_FOR_PM despite being merged back in the project's founding
     sprint (confirmed COMPLETED in backlog.json with PR links for all 6, e.g. TASK-008
     PR #30). Corrected to COMPLETED to match backlog.json — pure doc-lag fix, no new work. -->
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
  <status>COMPLETED</status>
  <priority>MEDIUM</priority>
  <title>Life-progression events beyond current marriage ceiling — done, final backlog item</title>
  <description>Implemented as flavor-only, zero-mechanical-effect additions on top of the existing marriage/anniversary loop (RomanceNPC.gd/TASK-282): rival dialogue (vague "someone" pressure, occasional, never blocks proposal or costs affinity) and a 3-stage life-progression arc (pregnant/born/toddler) tied to years-married, granting harmony-only bonuses and milestone dialogue on top of the existing anniversary payoff — silver amount and event count left exactly unchanged. Merged 1cd8088, pushed. Closes Phase 2 — all 6 approved backlog items now complete.</description>
  <researcher_notes>Owner's explicit acceptance of the no-fail-state tension honored: rivals are pure flavor, no risk mechanic. Full record: ops/ai-eng-log.md run 13. Spec: docs/research/TASK-324-spec.md.</researcher_notes>
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

<!-- AI-LOOP: 2026-09-01 TASK-324 (rival flavor + life progression) merged to main, commit 1cd8088. Sprint 3 of 3-sprint plan complete — PHASE 2 CLOSED, all 6 approved backlog items (321/322/323A+B/324/325/326) done. Cline hit its 5th and 6th rate-limit-class failures of the session on this one task (stealth/ox-alpha: out of credits; minimax-m3:free: OpenRouter rate limit, but only after ~5min unusual pure-reasoning then rapid correct progress including self-detected recovery from a benign concurrent-edit race). All 3 implementation files clean on review; Claude wrote the test file directly and fixed 2 of its own authoring bugs (year-sequencing math, active_quests key reuse) before merge. Verified: test_life_progression.gd 26/26 + test_anniversary.gd 6/6 + test_wedding.gd 6/6 (regression) + run_tests 100/100 + run_engine_tests 50/50. Full record: ops/ai-eng-log.md run 13. Next: Phase 3 (Polish/QA/Performance) per SHIP_PLAN.md, or address remaining SHIP_PLAN gaps (monetization, analytics, Apple Developer [HOLD] items). -->

<!-- AI-LOOP: 2026-09-02 AI-ENG-001 run — Gemini QA/Balance role, follow-up to run 1's broad checklist. Question this time: deep gap analysis on 3 dimensions HM:BtN is known for — gameplay depth, content range, NPC engagement/social balance — with concrete, effort-ranked mechanics rather than a feature checklist. Gemini's raw list cross-checked against actual code (rg over scripts/, scenes/, data/) before proposing anything below, per the loop's integrate-don't-trust-blindly rule. Two of Gemini's claimed gaps were WRONG (already implemented): monsoon-season auto-watering + hot-season wilt tracking already exist (GridManager.gd _on_minute_ticked); gift-giving with per-NPC preference tiers (loved/liked/neutral) already exists (DialogueDB.gd GIFT_PREFERENCES + RomanceNPC.gd) — though verifying that one surfaced a REAL gap Gemini didn't even ask about: the preference table already listed elder/child/handler/trader, but only the two romance candidates ever called the gifting mechanic. Fixed directly (see run 16, ai-eng-log.md) rather than filed as a ticket, along with a real pre-existing bug the fix surfaced: quest talk-tracking only ran inside each NPC's dialogue-fallback branch, so holding any food item (near-universal in a farming sim) silently skipped talk_to_<npc_id> quest objectives on that interact. Confirmed real gaps below, filed NEEDS_OWNER_REVIEW with priority labels per the user's explicit instruction (2026-09-02: "may label as non P0/P1 to prioritize... to do later" — labels are a sequencing recommendation, scope inclusion is still an owner call per SHIP_PLAN.md Phase 1 precedent). Full run record: ops/ai-eng-log.md run 16. -->

<task_item>
  <id>TASK-328</id>
  <source>AI_LOOP_GEMINI</source>
  <status>COMPLETED</status>
  <priority>P1</priority>
  <title>Weather-reactive NPC schedules (rain routes NPCs indoors)</title>
  <description>ScheduleDB.gd already drives 7 NPCs' hour-based waypoints, polled every physics frame with SignalBus.time_manager already available; GameData.current_weather already varies (clear/rain/fog/overcast) via TimeManager but nothing consumes it for NPC positioning — Main.gd's own weather_changed handler is a no-op (`pass`). Add a rain-variant waypoint per NPC (reusing each NPC's existing "home" slot where one exists) so villagers visibly react to weather, matching HM:BtN's rain-reroutes-schedules pattern. Confirmed real gap.</description>
  <researcher_notes>Impact: high (town "feels alive") / Effort: low — infra exists, this is data + one weather param threaded through waypoint_for(). Owner: TBD. GitHub issue: #179.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-329</id>
  <source>AI_LOOP_GEMINI</source>
  <status>COMPLETED</status>
  <priority>P1</priority>
  <title>Weather/festival-aware dialogue priority tier</title>
  <description>DialogueDB.get_seasonal_line() already has a priority-branch structure (binthabat_done > binthabat_hint > season pool) — extend it with a weather branch (e.g. a "rain" pool per NPC) ahead of the season fallback, so daily dialogue occasionally reacts to current weather without a large new line count. Confirmed real gap: current_weather is tracked but never read by any dialogue path.</description>
  <researcher_notes>Impact: high / Effort: low — same data-driven pattern already used for season/binthabat branches, just one more Dictionary key per NPC. Owner: TBD. GitHub issue: #180.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-330</id>
  <source>AI_LOOP_GEMINI</source>
  <status>COMPLETED</status>
  <priority>P2</priority>
  <title>Festival density expansion (2-4 more lightweight festivals)</title>
  <description>Confirmed: exactly 4 festival triggers exist (Loy Krathong, Songkran, Wan Sart, Fishing Competition) across a 90-day year (30 days/season x 3 seasons) — HM:BtN-class density is closer to 1 every 1-2 weeks. FestivalManager.gd's pattern (minute_ticked subscription, year-season dedupe key, dialogue + optional mechanic) is proven and cheap to replicate. Candidates: a second cool-season event, a second hot-season event beyond Songkran/fishing comp, a monsoon-season event (currently zero monsoon festivals).</description>
  <researcher_notes>Impact: high (breaks up the daily grind across ~112 in-game days) / Effort: low-medium per festival — reuses an existing, well-tested pattern; scope is "how many, which flavor" not "build the system." Owner: TBD. GitHub issue: #181.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-331</id>
  <source>AI_LOOP_GEMINI</source>
  <status>COMPLETED</status>
  <priority>P2</priority>
  <title>Milestone collectibles across varied activities (not just shipping)</title>
  <description>TASK-326 already added permanent stamina-tier progression, but it's gated on a single axis (lifetime_items_shipped). Gemini's "Sacred Amulet" idea — 8-10 permanent milestones tied to varied achievements (max companion bond, storm-day fishing catch, deep mining tier, festival attendance streak) — would be a genuine expansion of an existing single-axis system into completionist breadth, reusing stamina_tier's existing plumbing rather than inventing a new one. Correct against Gemini's framing: this is an EXTENSION of an existing mechanic, not a net-new gap.</description>
  <researcher_notes>Impact: high (completionist depth without new gameplay loops) / Effort: medium — needs a milestone-tracking registry distinct from active_quests (these are permanent, not repeatable/removable). Owner: TBD. GitHub issue: #182.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-332</id>
  <source>AI_LOOP_GEMINI</source>
  <status>COMPLETED</status>
  <priority>P2</priority>
  <title>Repeatable side-quest noticeboard</title>
  <description>Confirmed: no repeatable/cycling quest source exists anywhere — the 22-objective quest chain (QuestLog.gd) is entirely one-shot narrative content. A noticeboard cycling simple fetch/delivery requests (e.g. "3 herbs for the monk") would give the item economy an ongoing sink and NPC affinity an outlet outside daily gifting, complementing rather than replacing the main chain.</description>
  <researcher_notes>Impact: medium-high (content range, repeat-play value) / Effort: medium — needs a new lightweight repeatable-quest data shape distinct from QuestData's one-shot objectives array. Owner: TBD. GitHub issue: #183.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-333</id>
  <source>AI_LOOP_GEMINI</source>
  <status>COMPLETED</status>
  <priority>P3 (design-philosophy conflict — resolved 2026-09-02)</priority>
  <title>Affinity decay for ignored NPCs -> weekly interaction streak bonus (owner-directed alternative)</title>
  <description>Original ask (decay on neglect) confirmed to conflict with the no-fail-state precedent per the discussion below. Owner reviewed 3 options (skip entirely / implement decay anyway / non-punishing alternative) and picked the non-punishing alternative: GameData.record_weekly_engagement() grants a small bonus (+1 affinity per consecutive week interacted with an NPC, capped at +5) instead of ever reducing affinity. Missing a week only forfeits that week's bonus and resets the streak to restart — no value ever goes down. Wired into both VillagerNPC.talk() and RomanceNPC.try_interact(), unconditional on every interact (excluding the transactional trader), granted silently (show_dialogue has no queue, so a dedicated line would just be overwritten by whichever branch's own line fires next).</description>
  <researcher_notes>Resolved via owner discussion 2026-09-02 (see chat transcript / ops/ai-eng-log.md run 18): decay rejected, weekly-streak bonus chosen instead. tests/test_weekly_engagement.gd (18/18). GitHub issue: #184 (closed).</researcher_notes>
</task_item>

<task_item>
  <id>TASK-334</id>
  <source>AI_LOOP_GEMINI</source>
  <status>COMPLETED</status>
  <priority>P3</priority>
  <title>Tool tier AoE/charge mechanic (multi-tile clear at max tier)</title>
  <description>Confirmed: GridManager.plant/water/harvest all take a single Vector2i cell — no multi-tile operation exists at any tool tier. HM:BtN's charged AoE swings (1x3, 3x3 at max tier) are a real strategic-depth gap for the late game. Larger scope than the other items here: touches the core 1:1-tile interaction model GridManager and the player controller are both built around, plus input handling for a "hold to charge" gesture on iOS touch — needs its own design pass, not a quick data addition like TASK-328/329.</description>
  <researcher_notes>Impact: high (real late-game depth) / Effort: medium-high — foundational interaction model change, not additive. Owner: TBD. GitHub issue: #185.</researcher_notes>
</task_item>

<!-- AI-LOOP: 2026-09-02 3-sprint autonomous run (ops/ai-eng-log.md run 17) closed TASK-328/329/330/331/332/334 -> COMPLETED. TASK-333 (affinity decay) deliberately excluded per owner instruction — it was filed as a no-fail-state design-philosophy conflict needing an explicit decision, and a blanket "complete all pending backlog" instruction didn't clearly cover that specific tension; still NEEDS_OWNER_REVIEW, not silently dropped. Commits: TASK-328/329 ada73e3, TASK-330 7c7f637, TASK-332 5e155b6, TASK-331 136b04e, TASK-334 31f10d4. All pushed to origin/main. GitHub issues #179/#180/#181/#182/#183/#185 can be closed; #184 (TASK-333) stays open pending the owner decision. -->

<task_item>
  <id>TASK-335</id>
  <source>OWNER</source>
  <status>COMPLETED</status>
  <priority>P1</priority>
  <title>Third romance candidate (Ploy)</title>
  <description>Part of the "broaden to compete with HM:BtN" plan (2026-09-02 quality/stickiness verdict) — only 2 marriage candidates existed against HM:BtN's 5. Added Ploy, a warm sociable market dessert-maker filling the personality gap between Niran (competitive) and Fah (introspective), tying the cooking recipe tree into romance content via her specialty-sell channel. Self-executed (narrative content). Commit 6ed128e.</description>
  <researcher_notes>tests/test_peer_npcs.gd 11->20 checks. Placeholder portrait pending a real art pass. Full record: ops/ai-eng-log.md run 19.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-336</id>
  <source>OWNER</source>
  <status>COMPLETED</status>
  <priority>P1</priority>
  <title>Real scored Fishing Competition (first competitive mini-game)</title>
  <description>Part of the "broaden to compete with HM:BtN" plan — confirmed zero scored competitions existed anywhere in the game. Extended FishingCompetitionTrigger.gd: catches during the window score points, a rival score is rolled at window close, placement grants a strictly-positive reward every tier (no fail state). Delegated to OpenCode (minimax-m3:free). Commit 6606a1f.</description>
  <researcher_notes>New tests/test_fishing_competition_scoring.gd 26/26 — tie tier tested via an extracted pure _placement_for() helper. Full record: ops/ai-eng-log.md run 19.</researcher_notes>
</task_item>

<!-- AI-LOOP: 2026-09-02 "Broaden to compete with HM:BtN" plan, Sprint 1 (TASK-335, TASK-336) complete per ops/ai-eng-log.md run 19. Sprint 2 (secondary unlockable area, additional named NPCs) and Sprint 3 (second scored mini-game) queued next. -->

<task_item>
  <id>TASK-337</id>
  <source>OWNER</source>
  <status>COMPLETED</status>
  <priority>P2</priority>
  <title>Secondary unlockable area (Mountain Cave)</title>
  <description>Part of the "broaden to compete with HM:BtN" plan. NOT a map/grid expansion (too risky given the Y-sort budget and GridManager's load-bearing 20x16 size) -- one new interactable (MountainCaveSpot.gd) in an already-empty map corner, gated behind mining_skill reaching cap 3. No new persisted field (unlock derived live from the already-persisted mining_skill), no new item (reuses ore.json's 3 ores with inverted rarity weighting). Delegated to OpenCode (minimax-m3:free). Commit 73c3c3e.</description>
  <researcher_notes>New tests/test_mountain_cave.gd 16/16 including a seeded statistical check on the rarity inversion. Full record: ops/ai-eng-log.md run 19.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-338</id>
  <source>OWNER</source>
  <status>COMPLETED</status>
  <priority>P2</priority>
  <title>Grow the named NPC roster (Nok)</title>
  <description>Part of the "broaden to compete with HM:BtN" plan. Recounted the roster before scoping (12 named NPCs, not ~9 as first estimated). Added exactly one new villager: Nok, a veteran farmer contrasting Niran's rivalry with cooperative wisdom. Self-executed (narrative content on existing data-driven infrastructure). Commit 480b790.</description>
  <researcher_notes>Surfaced and separately fixed a real pre-existing bug while scoping: headman/vet had dedicated portraits that were never wired up and silently rendered as Elder (commit d876154, new tests/test_villager_portraits.gd 15/15). Full record: ops/ai-eng-log.md run 19.</researcher_notes>
</task_item>

<!-- AI-LOOP: 2026-09-02 "Broaden to compete with HM:BtN" plan, Sprint 2 (TASK-337, TASK-338) complete per ops/ai-eng-log.md run 19, plus a bonus pre-existing bug fix (headman/vet portrait fallback, commit d876154). Sprint 3 (second scored mini-game) queued next, pending owner check-in. -->

<task_item>
  <id>TASK-339</id>
  <source>OWNER</source>
  <status>COMPLETED</status>
  <priority>P3</priority>
  <title>Songkran Cooking Contest (second scored mini-game)</title>
  <description>Part of the "broaden to compete with HM:BtN" plan. Reuses Songkran's existing 12:00-18:00 window rather than adding a new festival day (would have undone TASK-330's 2-per-season balance). Recipes cooked during the window score their harmony_reward; a rival is rolled at window close; every placement tier grants a strictly-positive reward. Ties the 36-recipe cooking system into competition for the first time. Delegated to OpenCode (minimax-m3:free). Commit 3fc026b.</description>
  <researcher_notes>Specced explicitly around the shared-signal risk (SignalBus.craft_completed is also emitted by FishingSpot/MiningSpot) via a recipes.json membership check, not a prefix match -- delegate implemented and tested this correctly on the first pass. New tests/test_songkran_cooking_contest.gd 32/32. Full record: ops/ai-eng-log.md run 19.</researcher_notes>
</task_item>

<!-- AI-LOOP: 2026-09-02 "Broaden to compete with HM:BtN" plan CLOSED. All 3 sprints complete (TASK-335..339 + bonus headman/vet portrait fix, commit d876154). Full record: ops/ai-eng-log.md run 19. Remaining open item, unchanged: no human has played this game end-to-end yet -- still the single highest-leverage gap per the original quality verdict. -->

<task_item>
  <id>TASK-340</id>
  <source>OWNER</source>
  <status>COMPLETED</status>
  <priority>P1</priority>
  <title>Rival win/loss save schema + RivalClock mechanism (Sprint 1 of 5)</title>
  <description>Part of the "6 romance + 6 rivals + 5 unlockable areas" plan. Owner-confirmed deliberate reversal of the no-fail-state precedent: a candidate's rival wins permanently if affinity stays below 25 for 90 days after first meeting (3 telegraphed warnings, no other consequence on loss). SaveManager v3->v4 (npc_first_met_day, lost_to_rival, rival_warning_shown, plus closes TASK-331's deferred milestones_earned persistence gap). RivalClock.gd ships with empty PAIRS -- pure mechanism, no content yet. Self-executed given the save-schema stakes. Commit 6549931.</description>
  <researcher_notes>Real bug caught by test_save_compat.gd, not inspection: the v3->v4 migration block was nested one level too deep and never ran for the most common real case (a payload already at v3). New tests/test_rival_clock.gd 17/17. Full record: ops/ai-eng-log.md run 20.</researcher_notes>
</task_item>

<!-- AI-LOOP: 2026-09-02 "6 romance + 6 rivals + 5 areas" plan, Sprint 1 (TASK-340) complete per ops/ai-eng-log.md run 20. Sprints 2-5 (TASK-341..344, specs already written) queued next, pending owner check-in. -->

<task_item>
  <id>TASK-345</id>
  <source>OWNER</source>
  <status>RESOLVED</status>
  <priority>P1 (fairness gap in an already-approved mechanic — should land before or alongside Sprint 3)</priority>
  <title>Early rival-awareness — fix a real fairness gap in the TASK-340/341/342 warning system</title>
  <description>Found while discussing Sprint 2/3: the existing candidate "rival" flavor-dialogue tier (built for Niran/Fah/Ploy under TASK-324, planned for Kiet/Malee/Kanya under TASK-341) only surfaces at close tier (affinity >= 60) — but the loss condition fires when affinity NEVER reaches 25. A player actually at risk of losing a candidate would never see that hint at all; the rival NPC's own tier-0 dialogue (as specced in TASK-342) was also written deliberately soft ("casual, no pressure yet"), revealing nothing. As specced, an at-risk player could go the full 90 days with zero warning and learn what happened only from the single ambient "X has married Y" message after the fact — directly contradicting the fairness goal the whole mechanic was designed around.</description>
  <researcher_notes>Half 1 of the fix (the candidate's own warning) landed in TASK-341, commit 64850e7: a "1_warned" dialogue pool per candidate, checked in RomanceNPC._talk() at level 1 once GameData.rival_warning_shown >= 1 — applied to all 6 candidates (Niran/Fah/Ploy retroactively, Kiet/Malee/Kanya from the start). Half 2 (the rival NPC's own tier-0 dialogue revealing the competing interest immediately) is still TASK-342's to implement, not yet built.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-346</id>
  <source>OWNER</source>
  <status>COMPLETED</status>
  <priority>P1</priority>
  <title>10-level system, phase 1: shared scale + romance dialogue retrofit</title>
  <description>Owner asked romantic affinity be expressed as a 10-level scale (also to be applied to friendly-NPC/animal affiliation in later phases, TASK-348/349). Adds GameData.level_for(value) = clampi(value/10, 0, 10) as the one shared derived function -- no schema change, affinity stays stored 0-100. Retrofits Niran/Fah/Ploy's dialogue from the old 4-tier (stranger/friendly/close/romantic, 8 lines each) to 10 numbered pools (20 lines each, redistributing the originals as anchors and writing new lines for the expanded resolution). RomanceNPC._talk() now selects by GameData.level_for() instead of the removed DialogueDB.get_affinity_tier(); the TASK-324 rival-flavor override now fires on levels 6-8 (the level-equivalent of the old "close" tier, 60-89 affinity under floor(affinity/10)). _check_proposal()'s affinity>=90 gate is unchanged. Self-executed (narrative content). Commit c70f90a.</description>
  <researcher_notes>Level-0 fallback (affinity < 10, before any dialogue pool exists) resolved by falling back to level 1's pool -- no separate "level 0" content needed since the first-meeting lines already live there. tests/test_affinity.gd rewritten from tier-string checks to level-number checks (43/43); tests/test_peer_npcs.gd, test_anniversary.gd, test_wedding.gd regression-checked green, unaffected (none hardcode dialogue-pool keys). Phases 2 (animals, TASK-348) and 3 (villagers, TASK-349) are specced and queued next, not yet built.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-341</id>
  <source>OWNER</source>
  <status>COMPLETED</status>
  <priority>P1</priority>
  <title>3 more romance candidates (Kiet, Malee, Kanya) — Sprint 2 of the 6+6+5 plan</title>
  <description>Brings the romance-candidate count from 3 to 6: Kiet (apprentice woodcarver, meticulous/understated), Malee (festival drummer, bold/expressive), Kanya (herbalist, gentle/nature-connected). Authored directly in TASK-346's 10-level dialogue shape (no old 4-tier draft ever existed for these) — full DialogueDB entry (20 level lines + "1_warned" + "rival" per candidate), GIFT_PREFERENCES, RomanceNPC._try_specialty_sell() branch, placeholder portrait (hue-shifted from an existing sprite), .tscn + Main.gd wiring. Also folds in TASK-345's early-warning fix for ALL 6 candidates (not just the 3 new ones), closing that gap. Self-executed (narrative content). Commit 64850e7.</description>
  <researcher_notes>Y-sort perf budget bumped 51->54. Real bug caught during test-writing, not inspection: a GDScript closure gotcha — a lambda capturing a local var by value silently never updated the outer scope, making the "1_warned" line assertion falsely fail; fixed by using a class-member field + bound method instead of a lambda for the signal spy. tests/test_peer_npcs.gd extended to 73/73; test_affinity.gd (43/43), test_anniversary.gd/test_wedding.gd regression-checked green.</researcher_notes>
</task_item>

<!-- HYGIENE: 2026-09-02 Kiet/Malee/Kanya renamed to Chang/Klong/Yaa (and Niran->Ek) per owner
     request — Thai nicknames instead of formal-sounding names. Applied throughout code, tests,
     and pending specs (TASK-342/347/349, SHIP_PLAN.md). See commits 15b69ca/ad8cddf. Planned
     rivals also renamed: Decha->Yai, Chai->Ohm, Anon->Note, Siri->Fon (Rung/Boon unchanged). -->

<task_item>
  <id>TASK-347</id>
  <source>OWNER</source>
  <status>COMPLETED</status>
  <priority>P1</priority>
  <title>Schema v5 — rival progress meter + rival friendship/confession fields</title>
  <description>SaveManager v4->v5: rival_progress (float 0-100, replaces pure day-elapsed tracking for the win/loss clock, advances ~1.11/day, nudgeable), rival_friendship + rival_confessed (both for TASK-342, no behavior here). RivalClock.nudge_progress() added. Festival tie-in: Fishing Competition win/loss nudges fah's rival -5/+5, Songkran Cooking Contest nudges ploy's rival the same way — only the thematically-linked rival, per owner decision from the original design discussion. New SignalBus.rival_clock registry slot (mirrors grid_manager/time_manager). Self-executed (schema change, always-escalate tier). Commit 98a9887.</description>
  <researcher_notes>Real bug avoided by following the spec's explicit warning: rewriting test_rival_clock.gd's boundary checks to set rival_progress directly, rather than keeping the old day-loop simulation — confirmed by running the original day-loop against the new code first and watching it fail (a day-68 gap in the loop meant 67 calls landed at 74.4% instead of the elapsed-day math's 75.6%, missing the tier-3 threshold). Also added a nudge-vs-no-nudge counterfactual pair proving the "slightly" framing is a real numeric effect. tests/test_save_compat.gd (59/59), test_rival_clock.gd (23/23), test_fishing_competition_scoring.gd (28/28), test_songkran_cooking_contest.gd (34/34) all green.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-342</id>
  <source>OWNER</source>
  <status>COMPLETED</status>
  <priority>P1</priority>
  <title>6 rival NPCs, wired-up win/loss clock, friendship + confession dilemma</title>
  <description>RivalNPC.gd (talk + gift-giving), RivalClock.PAIRS populated with all 6 real pairings (ek/yai, fah/ohm, ploy/rung, chang/note, klong/fon, yaa/boon), 6 .tscn scenes + placeholder portraits, Main.gd wiring, Y-sort budget 54->60. Rival gift-giving builds rival_friendship (mirrors RomanceNPC._give_gift() exactly); crossing level 6 fires a one-time confession (+25 silver/+15 harmony); conceding via krathong afterward permanently sets lost_to_rival and grants the matchmaker_&lt;rival_id&gt; milestone; continuing to court the romance candidate normally is completely unaffected. Dialogue content + gift preferences self-executed (narrative tier); mechanical implementation (RivalNPC.gd, scenes, Main.gd wiring, tests) delegated to OpenCode (minimax-m3:free) per the delegate-first policy. Commit f73be42.</description>
  <researcher_notes>First test of the new delegate-first policy on a genuinely large task. Delegate produced substantial, well-structured, working output (91/91 in the new test file it authored, including good state-isolation between phases) — but Code Quality Review caught one real bug before merge: its portrait hue-shift script round-tripped through PIL's HSV image mode, which has no alpha channel, so merging back to RGBA reconstructed every pixel fully opaque (255) — every rival's transparent sprite background became a solid black rectangle. Regenerated all 6 portraits with a per-pixel colorsys-based shift (same technique used for TASK-341's placeholders) that preserves alpha explicitly, and fixed the tool script itself. Also caught and fixed one stale test assertion (test_rival_clock.gd asserted PAIRS was empty, no longer true once this task populates it) that the delegate's own test suite didn't touch since it wasn't told to. One prior attempt on the same model produced zero file changes (ran out of steps mid-exploration, no error) before this successful run.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-350</id>
  <source>OWNER</source>
  <status>COMPLETED</status>
  <priority>P1 (blocks meaningful crop variety the moment a player owns 2+ seed types)</priority>
  <title>Active-seed selection for planting — first real gap in the "no menu UI" philosophy</title>
  <description>Owner found via actual play (first human playthrough this project has had): pressing interact on an empty tile always plants rice, with no way to choose a different crop. Root cause confirmed in code: `Player._find_crop_for_held_seed()` auto-picks "the first seed_* item found in GameData.inventory" (Dictionary iteration order, not player-controlled), falling back to jasmine_rice if no seeds held at all. This is the SAME "auto-pick first matching held item" pattern this whole game deliberately uses everywhere (gift-giving, specialty-selling) to avoid any menu/choice UI — it just breaks down specifically for planting once a player owns more than one seed type, since there's no way to express "no, THIS one."</description>
  <researcher_notes>Researched how the genre handles this (verified via web search, not assumed): Harvest Moon: Back to Nature uses R1 to CYCLE the currently-equipped tool/item one at a time (lightweight, no popup) and a separate R2 to open the full rucksack for less-common digging (https://www.skyrender.net/hmbtn_manual.html, https://gamefaqs.gamespot.com/ps/446412-harvest-moon-back-to-nature/faqs/54991). Stardew Valley uses an always-visible 12-slot hotbar selected via number keys or scroll wheel, no popup either (https://stardewvalleywiki.com/Controls). Both genre precedents resolve this WITHOUT a modal choice screen. Recommendation: a lightweight "active seed cycle" — cycling which seed_id is currently "primed" for planting, with a small always-visible HUD indicator showing the primed seed name (glanceable, not a menu). Do NOT build a full inventory grid/popup; that breaks the established interaction paradigm for the rest of the game.

  **INPUT BINDING DECIDED (owner, 2026-09-02):** one shared Godot InputMap action (`cycle_seed`), bound per-platform so there's a single underlying function, not three separate mechanics — future controller support becomes "add a binding," not "build a second cycle system":
  - Keyboard: `Q` (or `Tab`) — fits the existing minimal WASD+E scheme, no mouse dependency.
  - Gamepad (future): `L1`/`LB` shoulder button — exact HM:BtN precedent (their R1 tool-cycle), doesn't compete with the movement stick.
  - Mobile touch: tap the HUD seed-indicator widget directly — the only real option on touch (no spare physical button); matches this project's existing on-screen-control precedent (`VirtualJoystick`/`InteractTap` already in `HUD.tscn`), and must meet the project's 44x44pt minimum touch-target rule.

  **NO-SEED FALLBACK DECIDED (owner, 2026-09-02):** when no seed is primed (owns none), planting still falls back to jasmine_rice (preserves the no-fail-state guarantee — interact always does something) but emits a distinct dialogue line ("No seed selected — planted rice instead.") instead of silently planting rice with no signal. Both open questions now resolved — ready to spec/build.

  **SHIPPED (2026-09-02):** spec written (`docs/research/TASK-350-spec.md`), delegated to Cline (minimax-m3:free) alongside TASK-348/349, Code Quality Review + merge self-executed. Commit 5acae24 (merge -&gt; main), GitHub issue #196 closed. `Player._find_crop_for_held_seed()` now prefers a session-only `_primed_seed_id` (not persisted to save data) set by the new shared `cycle_seed` InputMap action (Q on keyboard; gamepad L1/LB left intentionally unbound — no controller testing rig exists yet), falling back to the legacy first-held pick only when nothing is primed. New HUD `SeedIndicator.gd` widget mirrors `InteractTap.gd`'s touch-to-action pattern for mobile tap-to-cycle, label visible for desktop players too. Delegate run hit the same tool-hook timeout TASK-348's run hit, but only after finishing all substantive work (caught mid a self-inflicted `project.godot` formatting slip it was correctly cleaning up). Code Quality Review found zero defects in the finished work. Independently re-verified: 19/19 new seed-selection tests (including the actual end-to-end bug-fix case — priming a non-first-inventory seed and confirming THAT crop gets planted), full gate (225 tests) green.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-351</id>
  <source>OWNER</source>
  <status>COMPLETED</status>
  <priority>P2</priority>
  <title>HUD visual polish pass</title>
  <description>Owner feedback from the first real playthrough: "UI/HUD look so bad." Applied ART_STYLE_GUIDE.md's already-specified but never-implemented visual spec: Clay Brown (#6A4A30) 1px rounded border, Rice White (#F2E6C4) 90%-opacity backing panel, warm gradient fills. Wrapped the stat row in a PanelContainer for visual cohesion; replaced the unspecified purple header labels with the guide's own "Mo Maroon" heading color. New tools/gen_hud_assets.py generates all 5 UI textures programmatically at their exact existing pixel dimensions. Self-executed (UI/.tscn tier per CLAUDE.md). Commit 345a7db.</description>
  <researcher_notes>Scope note: a separately-reported "big blue rectangle covering most of the screen" could NOT be reproduced deterministically (tried fresh boot, and simulating the owner's exact reported actions — planting, watering, advancing to the same in-game time — neither shows it; the color doesn't match any known UI/shader asset in this codebase). Excluded from this ticket, filed separately if it recurs.

  **Two real, pre-existing bugs found and fixed while investigating the layout (neither introduced today):** (1) StaminaBar/HarmonyBar's TextureProgressBar nodes set `under_texture`/`progress_texture` in HUD.tscn, but Godot 4's actual property names are `texture_under`/`texture_progress` — scene files silently ignore unknown properties, so these bars have NEVER rendered their fill graphic in this project's history, confirmed by testing the untouched original HUD.tscn in isolation before concluding this wasn't a regression. (2) SeasonBg/PromptBg used `stretch_mode = 1` (STRETCH_TILE, verified against Godot's actual enum) instead of STRETCH_SCALE(0) — harmless at their original small heights, tiled visibly once the true (already-tall, due to TimeBox's 7 stacked labels) row height became visible behind a solid panel background. Verified via the game's own `--screenshot` CLI hook (TASK-010) at dawn and noon. run_gate.sh all green, test_hud_progression.gd (10/10) and test_touch_targets.gd (10/10) regression-checked.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-343</id>
  <source>OWNER</source>
  <status>COMPLETED</status>
  <priority>P2</priority>
  <title>Unlockable areas 4-5: Deep Canal Bend, Sacred Grove</title>
  <description>Two of the 5 planned unlockable-area sprint's spots: Deep Canal Bend (fishing variant, gated fishing_skill&gt;=4, position (600,672), inverted rarity weights 0.4/1.2/2.5/4.0 for common/uncommon/rare/legendary so the richer vein favors big/legendary catches, no fishing_skill bump or milestone re-trigger) and Sacred Grove (wood-gathering variant, gated companion_bond_tier()&gt;=4, position (936,288), 3 base wood + axe bonus vs ForestTree's 1 base, daily-gated, no "inseparable" milestone re-trigger). Both dynamically instanced from Main.gd (_ensure_deep_canal/_ensure_sacred_grove, called from _ready() and the minute_ticked unlock handler), mirroring MountainCaveSpot.gd's established script.new()-instancing pattern. Delegated to OpenCode per the delegate-first policy; Code Quality Review + merge self-executed. Commit 29eac36 (merge 999fe74 -&gt; main), GitHub issue #188 closed.</description>
  <researcher_notes>Two real bugs found and fixed in the delegated diff before merge, both documented in-code with BUGFIX comments: (1) SacredGroveSpot.gd copied ForestTree.gd's `@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null` pattern — invalid for a script.new()-instanced spot (no .tscn backing means `$InteractArea` is always null), so chop() could only ever fire from a direct test method call, never a real player pressing interact. This exact failure class has now shipped at least once before in this project (per MountainCaveSpot.gd/DeepCanalSpot.gd's own precedent-avoidance comments) — worth flagging to whichever future spec drafts a 6th unlockable spot: explicitly call out "no @onready $NodeName on a script.new()-instanced node" as a checklist item, not just something the reviewer catches after the fact. (2) test_deep_canal.gd's statistical legendary-rarity check (canal weight 4.0 vs FishingSpot's 0.4) silently compared 0 rolls to 0 rolls: both legendary fish species are season-gated (pla_buk=monsoon, pla_sai_rung=hot) but the test ran at GameData's default boot season ("cool"), and `_current_season()` reads from SignalBus.time_manager.current_season first (not GameData's, which only wins as a fallback) — the test's initial fix of setting `gd.current_season` alone didn't take effect until TimeManager's own field was also set. Fixed by forcing `sb.time_manager.current_season = "monsoon"` before rolling; 16/16 deep-canal + 17/17 sacred-grove tests pass, full gate (175 tests) stays green. Remaining sprint work: TASK-344 (final 2 of the 5 unlockable areas), TASK-348 (10-level animals), TASK-349 (10-level villagers).</researcher_notes>
</task_item>

<task_item>
  <id>TASK-344</id>
  <source>OWNER</source>
  <status>COMPLETED</status>
  <priority>P2</priority>
  <title>Unlockable areas 6-7 (final 2 of 5): Lotus Maze Shore, Coastal Trading Post</title>
  <description>Final sprint of the "6 romance + 6 rivals + 5 unlockable areas" plan. Lotus Maze Shore (fishing variant on the walkable edge of the 3x3 lotus maze, gated on all 5 TASK-331 milestones earned — the "completionist" capstone — rarity weights biased toward legendary even harder than Deep Canal Bend, ties into the elder's previously-unused "fishing_hint" flavor line about lights near the maze) and Coastal Trading Post (economy variant, NOT a gather spot, gated lifetime_items_shipped&gt;=200, sells the priciest held item via a new "coastal" +25% sell-price tier between market/+15% and specialty/+45%). Both dynamically instanced from Main.gd, mirroring the established pattern from TASK-337/343. Delegated to Cline (minimax-m3:free); Code Quality Review + merge self-executed. Commit 2a7ad58 (merge -&gt; main), GitHub issue #189 closed.</description>
  <researcher_notes>First delegated task this session where Code Quality Review found ZERO defects — the delegate correctly self-applied both lessons from the two prior tasks' bugs without being told to: built the InteractArea programmatically from the start (avoiding the @onready $InteractArea null-bug fixed twice before), and proactively forced the test season to "monsoon" before the legendary-rarity statistical check (the exact fix TASK-343's test needed after failing once). Read as a positive signal for the delegate-first policy: the free-model worker is generalizing from patterns already present in the codebase (its own context included the just-merged DeepCanalSpot.gd/SacredGroveSpot.gd as reference), not just pattern-matching the immediate spec. Independently re-verified (not just trusting the delegate's self-reported gate pass): 16/16 lotus-maze-shore + 26/26 coastal-trading-post new tests, full gate (225 tests) green, re-checked again post-merge on the main checkout. This completes the entire 5-area unlockable-areas plan (Mountain Cave, Deep Canal Bend, Sacred Grove, Lotus Maze Shore, Coastal Trading Post). Remaining work: TASK-348 (10-level animals), TASK-349 (10-level villagers), TASK-350 (active-seed selection for planting, now fully specced).</researcher_notes>
</task_item>

<task_item>
  <id>TASK-348</id>
  <source>OWNER</source>
  <status>COMPLETED</status>
  <priority>P2</priority>
  <title>10-level system, phase 2: buffalo, chicken, companion cat</title>
  <description>Rescales GameData.buffalo_hearts()/chicken_hearts()/companion_bond_tier() from the legacy /25.0 (0-4) scale to TASK-346's level_for() 0-10 scale, and rescales every downstream consumer threshold to the same percentage of the new ceiling: BuffaloRace's companion-bonus gate (50%: 2/4 -&gt; 5/10), Buffalo/ChickenCoop's gold-tier gate (80%: 3/4 -&gt; 8/10, calibrated slightly above the literal 75% since 7.5 isn't an integer boundary), breeding gates (50%: 2/4 -&gt; 5/10), and CompanionNPC's inseparable-milestone cap (100%: 4/4 -&gt; 10/10). Buffalo/ChickenCoop/CompanionNPC each get a full 10-line dialogue progression replacing 2-3-line branching. HUD hearts display switches from repeating "♥" glyphs to a compact "Lv N/10" format. Delegated to Cline (minimax-m3:free); Code Quality Review + merge self-executed. Commit 3550aa7 (merge -&gt; main), GitHub issue #190 closed.</description>
  <researcher_notes>The delegate's run hit a tool-hook timeout mid-way through fixing pre-existing tests calibrated to the old scale, leaving test_companion_bond.gd partially fixed and test_milestones.gd/test_hud_progression.gd untouched entirely — its self-reported "gate green" was accurate for what it actually ran (run_gate.sh all), but test_hud_progression.gd isn't wired into that aggregator (same standalone-test convention as test_deep_canal.gd etc.), so a stale "♥" glyph assertion there would have shipped undetected if Code Quality Review had just trusted the gate-green claim rather than independently sweeping every test file the spec named. Also worth noting on the positive side: the delegate independently found and fixed a real consumer the spec's own grep had missed — SacredGroveSpot.gd's Main.gd gate (companion_bond_tier()&gt;=4), added by TASK-343 which merged AFTER this spec was written, so the spec's pre-written consumer table couldn't have listed it. General lesson for future specs in fast-moving areas of this codebase: a spec's "grep this list yourself to confirm it's current" instruction is doing real work, not just boilerplate caution. Independently re-verified every touched test file individually plus the full gate (225 tests) green, both pre-merge and post-merge on main.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-349</id>
  <source>OWNER</source>
  <status>COMPLETED</status>
  <priority>P2</priority>
  <title>10-level system, phase 3: villagers (combined with season)</title>
  <description>Adds a bounded "high_affiliation" priority branch to DialogueDB.get_seasonal_line() for general villagers (Elder, Child, Handler, Headman, Vet, Nok) — season stays the primary axis, level 6+ (affinity 60+) is a ~40%-chance secondary flavor layer, inserted lowest-priority (below binthabat_done/binthabat_hint/rain, above the season fallback). 12 new lines total (2 per villager), season-agnostic, warmer than normal seasonal lines. VillagerNPC.talk() threads GameData.level_for(affinity) through; MonkNPC.gd's call is untouched (still defaults level to 0, no high_affiliation pool). Delegated to Cline (minimax-m3:free); Code Quality Review + merge self-executed. Commit 5271c17 (merge -&gt; main), GitHub issue #191 closed.</description>
  <researcher_notes>Clean delegate run, no defects found in Code Quality Review — priority order, level gating, and the graceful no-pool fallback (monk) all matched the spec exactly, including precise roll-value reasoning in the new tests' comments for each priority-branch interaction case (e.g. which hint_roll values isolate "hint outranks high_affiliation" from "high_affiliation never fires" without relying on RNG). Independently re-verified: 25/25 weather-dialogue, 14/14 gift-prefs, 14/14 schedules, full gate (225 tests) green. This is phase 3 of 3 for the 10-level unification (TASK-346 romance candidates, TASK-348 animals/companion, TASK-349 villagers) — all three now complete. Remaining backlog: TASK-350 (active-seed selection for planting).</researcher_notes>
</task_item>

<task_item>
  <id>TASK-352</id>
  <source>OWNER</source>
  <status>COMPLETED</status>
  <priority>P1 (foundational — every future interior/building feature depends on this)</priority>
  <title>Building interiors + map transitions (foundation)</title>
  <description>Owner-identified gap: the entire game lived in exactly one scene (scenes/core/Main.tscn) — no interior buildings, no doors, no map/scene transitions existed at all. Shipped per spec (docs/research/TASK-352-spec.md): SceneLoader autoload (single change_scene_to_file() call site, driven by SignalBus.scene_transition_requested), Door.gd/tscn warp convention, TimeManager promoted to a true project autoload (its clock state was previously a Main.tscn child node, never mirrored to GameData — would have silently reset to day 1 06:00 on every building entry), Main-&gt;World rename (~85 files, mechanical), and FarmHouse.tscn as the one proof-of-concept interior. Delegated to Cline (minimax-m3:free, 4 dispatch attempts — see researcher_notes for the stale-hub-daemon lesson); Code Quality Review + merge self-executed. Commits 4201c52 (feature, closes #198) + 272339a (post-merge tolerance fix) on main, pushed. Converting other buildings (market, temple, trader stall) into enterable interiors remains explicit follow-up work, not in this task.</description>
  <researcher_notes>Researched via direct codebase reading (Main.tscn/gd, GridManager.gd, SignalBus.gd, project.godot's autoload list, test_mobile_budget.gd) plus a free-model second opinion (Cline/minimax-m3, read-only consultation, no file edits) for cross-validation, per the owner's explicit "consult with gemini or free model" request (Gemini's browser tab had two typing permissions denied by the owner earlier the same session, so this used a direct non-interactive Cline -p-less call instead — the working invocation pattern for this project omits the --print flag entirely, which errors as "unknown option" despite appearing in `agy --help`/`cline --help`'s own listed flags; the bare positional prompt argument alone is sufficient to trigger non-interactive mode).

  The free model's answer converged strongly with independent findings (change_scene_to_file + SceneLoader autoload + the existing SignalBus.grid_manager self-registration pattern extended to a new Door/interior convention is the right fit; a toggle-visibility mega-scene is actively hostile to this codebase's existing exit-cleanup and Y-sort-budget conventions) and surfaced genuinely useful specifics from actually reading the files (Main.gd's hard-snapped (480,384) player spawn, WorldRender's hardcoded outdoor ZONES/PROPS constants, three interactables' get_parent().get_node("WorldRender") lookups that should migrate to a registry slot).

  **However, the free model's answer contained one confirmed factual error, caught only by independently re-checking project.godot myself rather than trusting the claim**: it asserted "TimeManager and autoloads are genuinely global," but TimeManager does NOT appear anywhere in project.godot's [autoload] section (verified: the list is exactly SignalBus/GameData/FrameCap/AudioManager) — it's a regular child node instanced inside Main.tscn, and its actual clock state (day/hour/minute) is never mirrored to GameData. This is the single most load-bearing finding for the whole task: a naive scene swap would silently reset the in-game clock to day 1, 06:00 on every building entry, and the free model missed it entirely despite it being independently verifiable in under a minute via grep. Filed as Step 1 in the spec, ahead of every other change, specifically because it's the one fix that would silently corrupt gameplay state if skipped. General lesson, consistent with this project's existing Gemini-research policy: a free/cheap model's codebase read is a genuinely useful second opinion and caught real specifics worth having, but every concrete claim still needs independent verification before being written into a spec as fact — "the model said so" is not the same evidentiary bar as "I checked the file myself."

  **Build/review update:** delegated to Cline (minimax-m3:free). First dispatch hit the known tool-infra timeout mid-Step-1 (resumed via a precise continuation prompt naming exactly what was already done); the 2nd and 3rd dispatches failed near-instantly with garbled/truncated output after ~7h of continuous session uptime — root cause was a stale `cline-hub-daemon` background process (new finding this session: kill it and it cleanly auto-respawns; check this whenever a fresh Cline dispatch fails instantly after a long session). 4th dispatch succeeded and produced a full, substantial pass. Code Quality Review caught three real defects the delegate's own "gate green" self-report didn't surface: (1) FarmHouse.gd implemented only is_plantable()/ground_at() from the GridManager contract, but Player.gd calls gm.plant()/water()/harvest() directly with NO has_method() guard (only get_plot() is guarded) — pressing interact anywhere inside the new farmhouse would have thrown a runtime script error on the very first try; added soft-fail stand-ins. (2) test_mobile_budget.gd's Y-sort ceiling was bumped 60-&gt;61 alongside adding the new door to the exclusion list, which is self-contradictory (correctly excluding it means the count doesn't change); reverted to 60. (3) The new test_scene_transitions.gd was never wired into scripts/ci/run_gate.sh and would have silently never run in CI; added a `scenes` gate target. Also found, only on re-running the gate on `main` post-merge (not caught by the same gate passing repeatedly in the worktree): an intermittent spawn-position assertion failure, root-caused to a transient double-CharacterBody2D overlap during the deferred scene swap (outgoing and incoming Player briefly coexist at the same fallback spawn point; Godot's own depenetration separates them along X by a real-time-dependent amount) — not a bug in the warp/door logic itself, fixed by widening the test's distance tolerance with the root cause documented inline rather than chasing single observed pixel values.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-353</id>
  <source>OWNER</source>
  <status>COMPLETED</status>
  <priority>P1 (blocked #203's EdgeTransition merge per owner-confirmed sequencing)</priority>
  <title>Fix scene-transition spawn drift + prevent instant re-trigger loops</title>
  <description>Root cause of the spawn drift TASK-352 could only tolerate (a widened test tolerance): change_scene_to_file() defers the outgoing scene's teardown, so for a frame or two the outgoing and incoming Player both exist as CharacterBody2Ds, sometimes exactly coincident, and Godot's own move_and_slide depenetration pushes them apart along X by up to ~60px. Fix 1: SceneLoader strips the outgoing Player's collision_layer/mask to 0 immediately before calling change_scene_to_file() (it's about to be freed anyway) — eliminates the depenetration race at the source. Fix 2: SceneLoader debounces repeat transition requests within 400ms at the single choke point every transition source already uses — protects against any instant re-trigger regardless of cause, including TASK-357's planned walk-through EdgeTransition which has no interact-press gate. Delegated to Cline (minimax-m3:free); Code Quality Review + merge self-executed. Commits c364ceb (feature) / d478ad7 (merge -&gt; main), GitHub issue #199 closed.</description>
  <researcher_notes>Scope note caught before dispatch, not after: the original issue framing asked for "spawn facing away from the door," but Player.gd has exactly one idle animation with no directional variants (verified by grepping Player.tscn's SpriteFrames before writing the delegate prompt) — there's nothing to visually orient with current assets, so that half of the original ask was dropped rather than faked with a no-op. The 400ms debounce is the practical substitute: can't visually face away, but can't loop back through the same transition either. Clean, tightly-scoped delegate run — only the two intended files touched (SceneLoader.gd, test_scene_transitions.gd), no scope creep into Door.gd/Player.gd/FarmHouse.gd/World.gd as instructed. Independently re-verified: spawn-position tolerance tightened from &lt;100px to &lt;5px, stable across 5+ runs both in the worktree and on main post-merge (not just trusted from the delegate's self-report); full gate green (303 checks) on both.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-357</id>
  <source>OWNER</source>
  <status>COMPLETED</status>
  <priority>P1 (architecture decision every future world-expansion task builds on)</priority>
  <title>Multi-scene world topology framework (screen-graph)</title>
  <description>Spec: docs/research/TASK-357-spec.md. Follow-up from TASK-352 and a HM:BTN world-map gap analysis. Shipped: EdgeTransition.gd (walk-through area transitions, distinct from interact-required Door.gd) + SignalBus.edge_carry_value, InteriorBase.gd (shared interior/area skeleton, FarmHouse.gd refactored onto it as proof), CoastalArea.tscn/gd (first proof-of-concept split — CoastalTradingPost + SacredGrove + CarpenterUpgrade, NOT DeepCanalSpot, see researcher_notes correction), warp-id uniqueness gate check, and a required save-schema fix (SAVE_VERSION 5-&gt;6, real scene_path + player_pos persistence replacing a prior hardcoded-literal placeholder). Delegated to Cline (minimax-m3:free, 4 dispatch attempts across the implementation phase); save-schema piece + Code Quality Review + merge self-executed. Commits e4f6b51 (save-schema)/0f07c2f, cbeb3bb, c7f999b, b5eab2f (implementation checkpoints)/b3ec13e (merge -&gt; main), GitHub issue #203 closed.</description>
  <researcher_notes>Owner decisions locked in via sequential AskUserQuestion verification (not assumed): (1) sequencing — #199 and #203 ran in parallel, EdgeTransition.gd's merge held until #199 landed; (2) Phase-1 slice confirmed as CoastalArea with CarpenterUpgrade added to the move; (3) SAVE_VERSION bump stayed in scope, migration test written first; (4) sprint order #199 -&gt; #203 -&gt; #201 -&gt; #200 -&gt; #202.

  **Real spec error caught mid-implementation, not before dispatch:** the original spec swapped DeepCanalSpot's and SacredGrove's actual positions (claimed DeepCanalSpot (19,6) was adjacent to CoastalTradingPost; it's actually at (12,14), nowhere near it — SacredGrove is the thing at (19,6)). A Cline delegate caught this itself by checking the actual code rather than trusting the spec, but then hit an unrelated tool-syntax bug mid-diagnosis and aborted with zero files changed. Verified the correction directly (precise per-function parsing of World.gd), then asked the owner: include SacredGrove in the slice despite the theme mismatch (wood-gathering/companion-cat, not coastal)? Owner: yes, for a spatially clean cut. This is the concrete incident that motivated CLAUDE.md's new "free-worker consult" pattern (2026-09-03) — a cheap pre-dispatch fact-check pass would have caught this before burning an implementation cycle, not just during one.

  **Delegate execution hit the documented Cline tool-infra timeout ("hook dispatch failed" / "Provider returned error" / "operation timed out") FOUR separate times across this task's implementation phase** — each time with real partial progress on disk, not a stuck/no-action run. Resumed each time via a precise continuation prompt naming exactly what was done vs. remaining, per this project's established pattern, rather than blind full retries. Two of the four interruptions left genuine bugs in the partial state that Code Quality Review caught and fixed directly rather than trusting the next dispatch to notice: (1) an interrupted file-insert spliced new content into the middle of InteriorBase.gd's `_register_self()`, orphaning `SignalBus.world_render = self` onto the end of `_place_player()` instead — meaning world_render would only ever get set on a fresh-boot-no-warp spawn, never on a warp/door/edge spawn; (2) FarmHouse.gd's refactor onto InteriorBase failed to parse twice in a row for reasons the delegate's own doc-comment update didn't anticipate — `class_name InteriorBase` was missing entirely (so `extends InteriorBase` couldn't resolve at all), and separately GDScript doesn't allow a subclass to redeclare an inherited `@export var` (the `default_spawn` override had to move into `_init()` instead). Both fixed directly, independently re-verified via the two tests that actually exercise FarmHouse's spawn behavior before trusting the full gate. A third timeout left a trivial leftover (`main2.queue_free()` after a variable rename to `coastal2`) in a test file that was otherwise a complete, well-reasoned rewrite (real item-price domain knowledge in the coastal-rate math, not superficial renaming) — fixed with a one-line edit. Full gate independently re-verified green (349 checks + 74 standalone-test checks) on both the worktree and main post-merge, not trusted from any single delegate self-report.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-355</id>
  <source>OWNER</source>
  <status>COMPLETED</status>
  <priority>High (makes the TASK-352 transition system actually worth using)</priority>
  <title>Give the farmhouse interior real function (bed, weather source)</title>
  <description>Follow-up from TASK-352. FarmHouse was a bare tile room with nothing to do. Shipped: FarmHouseBed.gd/.tscn (sleep interactable -- advances the day via a new TimeManager.advance_to_next_day(target_hour), NOT the side-effect-free set_time() setter, so the same season-check + weather-roll sequence the passive rollover runs still fires; restores full stamina via GameData.reset_stamina(); persists via the existing SaveManager child-of-caller pattern World.gd's pause menu already uses), FarmHouseShrine.gd/.tscn (a household spirit-house, not a TV/radio -- avoids the anachronism in a rural Thai farmhouse -- reports TimeManager.next_weather), a real one-day-ahead weather forecast mechanism in TimeManager.gd (extracted the existing per-season odds into a pure _roll_daily_weather(season) helper, added next_weather populated on boot and every rollover, with the season-boundary edge case explicitly handled: a stale pre-rotation forecast is rerolled under the new season rather than leaking through), and basic FarmHouse decoration. Delegated to Cline (minimax-m3:free); Code Quality Review + merge self-executed. Commits 30ffd16 (implementation) / 9fd8b34 (merge -&gt; main), GitHub issue #201 closed.</description>
  <researcher_notes>**Free-worker consult applied before dispatch (first use of the pattern documented in CLAUDE.md this session):** a read-only Cline pass answered two open questions from the issue before any implementation prompt was written. Found: (1) no sleep/advance-day flow existed anywhere -- day rolls over passively at midnight, no stamina restore, no save, no UI trigger; (2) "surface tomorrow's weather" as originally scoped was unbuildable -- there was no forecast concept at all, only a `SignalBus.weather_changed(String)` signal carrying the CURRENT value, with tomorrow's weather generated lazily the instant the day actually rolls over. This directly changed the task's scope from "wire up an existing system" to "build new forecast plumbing," confirmed with the owner (build a real forecast, carry the existing per-season odds forward unchanged, no retuning) before dispatching. This is the first task where the consult step demonstrably prevented dispatching a delegate against a false premise, rather than discovering the gap mid-implementation as happened on TASK-357.

  **Delegate execution hit the same documented Cline tool-infra timeout** mid-write on the new test file (tests/test_farmhouse_content.gd), this time with the file left syntactically complete (all four sections of test logic written) but missing three helper functions it called (_tick_one_minute, _get_nodes_in_group, _is_consistent_with_season) -- a compile-time-obvious gap, quickly finished directly. Running the completed file surfaced three real, independent bugs the delegate's own code had (none related to the missing helpers): (1) a rollover-timing off-by-one -- the test parked the clock at :58 and ticked once, but a single minute-tick from :58 only reaches :59, never crossing the 60-minute rollover threshold (the delegate's OWN second rollover test correctly used two ticks from :58, just not the first one -- an internal inconsistency, not a design gap); (2) a classic GDScript closure trap -- a lambda assigning to an outer-scope String variable to capture a signal's emitted text silently mutates a captured-by-value copy, invisible to the outer scope, worked around with a one-element Array as a mutable reference box; (3) a flaky exact-equality stamina check racing against FarmHouse's own live Player node's per-physics-frame stamina drain, fixed by capturing the value immediately after the action instead of after an intervening `await process_frame`. All three fixed and independently re-verified stable across 5 runs (the test involves randomized weather rolls, so single-run passes aren't sufficient evidence). Full gate green: 370 checks, re-verified on both the worktree and main post-merge.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-354</id>
  <source>OWNER</source>
  <status>COMPLETED</status>
  <priority>High (cheap relative to payoff)</priority>
  <title>Scene-transition fade + door SFX (transition juice)</title>
  <description>Follow-up from TASK-352. The scene swap was an instant hard cut with no fade, no sound cue. Shipped: a ~200ms fade-to-black overlay wrapping every SceneLoader transition (owned by SceneLoader itself, so every current and future transition source gets it for free -- built as a persistent CanvasLayer+ColorRect parented to the autoload, time-budget-based polling rather than frame-count so it self-tunes if the fade duration is ever retuned), and a door-open SFX on Door.gd's interact trigger via the existing AudioManager autoload's synthesized SFX (a TODO tag marks where an authored door-creak sample would slot in once the audio art lane has one). This was the first task started under the new autonomous-sprint-start standing authorization (CLAUDE.md, 2026-09-03) -- qualified because its issue had no unresolved owner-decision point. Delegated to Cline (minimax-m3:free); Code Quality Review + merge self-executed. Commits c2afaac (implementation) / 0ee4d73 (merge -&gt; main), GitHub issue #200 closed.</description>
  <researcher_notes>The delegate caught its own regression before finishing, via genuinely disciplined debugging rather than luck: after implementing the fade, it independently ran the area-edges suite 10x, saw failures, stashed its own changes to get a clean baseline (5/5 pass), unstashed and re-ran (6/10 fail), and correctly concluded the new fade delay was exposing a pre-existing race -- test_area_edges.gd was reading the player's clamped position before its CharacterBody2D's first _physics_process tick had actually run, previously masked because the pre-fade transition completed fast enough that several frames always elapsed before the read. Fixed by widening the shared _wait_for_current_scene-style helper's post-detection grace period across every affected test file, then re-verified 10/10 stable.

  Code Quality Review found two more issues the delegate's own "100% green" self-report didn't surface: (1) Door.gd built a dedicated AudioStreamPlayer child in _ready() that was never actually played -- the real SFX call goes through AudioManager.play_sfx() instead, leaving the AudioStreamPlayer as pure dead code; removed directly. (2) Removing that dead code exposed a SEPARATE, genuinely real intermittent flake (~1-in-6, confirmed via 8+ repeated runs, not a one-off) in tests/test_scene_transitions.gd: SceneLoader now stamps its TASK-353 debounce timestamp only after its ~100ms fade-out tween completes, not immediately on emit as before -- this tightened three pre-existing 500ms test waits (tuned against the 400ms debounce window with only a 100ms margin) to a near-zero safety margin under the fade's added latency. Root-caused by tracing the exact stale pending_warp_id value the flaking check received back to which door's position it matched, not by pattern-matching on "another timing test, widen something." Widened all three waits to 1.0s with the cause documented inline. Independently re-verified: all four timing-sensitive suites (scene-transitions, area-edges, save-scene-restore, transition-fade) stress-tested 5-10x each with zero failures, both pre-merge and on main post-merge. Full gate green: 382 checks.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-358</id>
  <source>AI-LOOP</source>
  <status>COMPLETED</status>
  <priority>P3 (cheap, additive, no dependency on other in-flight work)</priority>
  <title>Fish Almanac — first-catch collection log for FishingSpot</title>
  <description>Gap-analysis finding (AI-ENG-001 loop, 2026-09-04): FishingSpot.gd's catch mechanic (single interact -> instant rarity-weighted roll against 20 species x 3 sizes, gated by season + a 1-4 skill level, verified directly in scripts/interactables/FishingSpot.gd) is intentionally zero-fail/zero-minigame, consistent with this project's broader no-fail-state design. Gemini genre research (Harvest Moon: Back to Nature, Stardew Valley, Animal Crossing) surfaced several ways cozy sims add fishing depth without a fail state -- most involve either a real casting mechanic (charge/distance -> water-tier/quality) or fish-pond husbandry, both genuine scope/direction calls flagged separately below as NEEDS_OWNER_REVIEW, not decided here. The one idea that's purely additive, reuses this repo's own existing milestone pattern exactly (GameData.milestones_earned / earn_milestone(), already used by ChickenCoop.gd's herd_keeper and FishingSpot.gd's own master_angler/storm_catch), and touches zero existing roll/skill logic: a "Fish Almanac" -- track every unique (species, size) ever caught in a new GameData dictionary, show a small completion-count UI entry, and fire a one-time "first catch of this species/size" dialogue + small harmony bonus via the same SignalBus.show_dialogue path FishingSpot.gd already uses. Shipped: `GameData.fish_almanac` + `record_catch()` (mirrors `earn_milestone()`'s idempotent shape exactly), wired into `FishingSpot.cast_line()` post-catch, a HUD "Almanac: X/60" readout (60 = 20 species x 3 sizes, independently verified against `data/fish/fish.json`), and `SaveManager` v6->v7 migration. Delegated to Cline (minimax-m3:free); Code Quality Review + merge self-executed. Commit 5316e3f (merge -> main), full gate green (409 checks, 27 new).</description>
  <researcher_notes>Gemini's full answer (genre research, not independently fact-checked claim-by-claim against the actual games -- treated as external genre knowledge per AI-ENG-001's Gemini role, not as verified fact) named several other mechanics not adopted here because each is a bigger scope/direction call, not a bounded engineering task -- flagged as NEEDS_OWNER_REVIEW rather than silently dropped or decided unilaterally: (1) cast-distance/charge mechanic gating water depth-tier and catch quality (Stardew-style) -- would change the core single-press interact contract every other interactable in this repo (MiningSpot, SluiceGate, CarpenterUpgrade) also uses, a real convention-wide decision; (2) fish-pond breeding/husbandry (HM:BtN-style) -- would be a genuinely good fit for this repo's existing chicken/buffalo hearts-and-breeding pattern, but is a new persistent structure + UI, not a small addition; (3) bait/tackle system with Thai-specific ingredients (chumming with sticky rice, cast nets) -- flavorful and on-theme but needs a real itemization/economy pass, not just a data table.  Only the Fish Almanac was scoped and filed directly since it has no open design question and cleanly mirrors an existing, already-reviewed pattern in this codebase. Run details: ops/ai-eng-log.md (2026-09-04 entry).

  **Code Quality Review note:** initially suspected `species.get("id", "")` in the delegate's FishingSpot.gd hook was referencing a non-existent field (no `"id"` literal anywhere in that .gd file) -- traced it fully before flagging anything: the species dict is loaded at runtime from `data/fish/fish.json`, which genuinely has an `"id"` field per entry. False alarm, verified rather than assumed. Delegate had also left its own changes uncommitted in the worktree (committed directly as part of merge prep, commit cc97ed6).</researcher_notes>
</task_item>

<task_item>
  <id>TASK-359</id>
  <source>AI-LOOP</source>
  <status>RESOLVED_NO_ACTION</status>
  <priority>N/A (resolved)</priority>
  <title>Fishing depth beyond a single-roll: cast-mechanic vs. fish-pond husbandry?</title>
  <description>Companion finding to TASK-358, filed separately per AI-ENG-001's escalation rule (this is a genuine scope/direction call, not something Claude should decide unilaterally). Gemini's HM:BtN/Stardew genre research named two substantially deeper fishing mechanics beyond the additive Fish Almanac: (1) a cast-distance/charge mechanic where casting farther from shore reaches a deeper water tier with a better catch pool (Stardew Valley's model) -- this would change the single-press interact contract every other interactable in this codebase currently shares (MiningSpot.gd, SluiceGate.gd, CarpenterUpgrade.gd, FishingSpot.gd itself), a repo-wide convention decision, not a local one; (2) fish-pond breeding/husbandry mirroring this repo's existing chicken/buffalo hearts-and-breeding pattern (ChickenCoop.gd/Buffalo.gd) but as a new persistent farm structure with its own UI, matching HM:BtN's actual fish-pond mechanic (feed daily, fish grow through size tiers, multiply every ~20 days). Both are real, scoped-later options, not vague suggestions -- but both are bigger investments than the current sprint pace, and only the owner can weigh them against the rest of the roadmap (crafting/economy depth, more NPCs, etc. per TASK-338's own acknowledged gap) and this project's "compete on depth" goal. Question for the owner: pursue either of these as a real task (and if so, which, and at what priority relative to other open work), or leave fishing as-is (Fish Almanac only) for now?</description>
  <researcher_notes>Filed per the AI-ENG-001 spec's Human decision escalation section -- does not block other independent work; TASK-358 (Fish Almanac) already covers the zero-cost slice of this gap and can proceed regardless of how this is resolved. No GitHub issue opened (GitHub MCP server currently failing to connect, bad auth header, per this repo's own CLAUDE.md/AI-ENG-001 Open items) -- create one once that's fixed.

  **Owner decision (2026-09-04):** skip both cast-distance and fish-pond husbandry. TASK-358 (Fish Almanac) ships as the only fishing-depth work for now; neither option is cheap enough relative to the NPC/economy gaps still open elsewhere. No further action on this item unless reopened later.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-360</id>
  <source>AI-LOOP</source>
  <status>COMPLETED</status>
  <priority>P3 (cheap, additive, no dependency on other in-flight work)</priority>
  <title>Farmhouse decor anchor-slots -- swappable shrine/bed/rug/wall-hanging</title>
  <description>Gap-analysis finding (AI-ENG-001 loop, 2026-09-04): FarmHouse.gd's interior (verified directly in scenes/interiors/FarmHouse.gd) has zero player-facing customization -- the bed (FarmHouseBed), the shrine (FarmHouseShrine), and 4 decoration sprites (water_jar, clay_stove, pha_khao_ma, mohom_cloth from DECOR_PATHS) are all placed at hardcoded tile positions with no interact-to-change path; the player can never choose, buy, or swap any of it. Gemini genre research (HM:BtN, Stardew Valley, Animal Crossing) on house-customization mechanics recommended, for a codebase without an existing grid/collision furniture-placement system, an "anchor slot" model over a full drag-and-drop editor: keep each decor position fixed, but make it an interactable with a `slot_type`, and let the player select any owned item matching that slot from a small list -- the same shape as an inventory pick, not a new placement system. Shipped for the shrine slot: `GameData.decor_choices` + `DECOR_CATALOGUE` (mirrors `tool_tiers`' shape), a new `FarmHouseShrineStylePicker` interactable that cycles owned styles via interact, a purchasable "ornate_shrine_blueprint" market item, and live re-skinning via a new `SignalBus.decor_style_changed` signal. Additive persistence, no SAVE_VERSION bump needed. Delegated to Cline; hit 3 provider failures across 2 different free models (documented rate limit, an NVIDIA overload, and a model no longer listed on OpenRouter) before a 4th dispatch (minimax-m3:free, retried after its own rate limit cleared) completed the work. Code Quality Review + merge self-executed, including resolving a real merge conflict against TASK-358 (both touched `run_gate.sh`/`SaveManager.gd`, non-overlapping additive fields, merged by hand) and recovering an orphaned git stash the delegate left behind mid-debugging. Commit f062696 (merge -> main), full gate green (445 checks, 36 new). No change to FarmHouseBed/FarmHouseShrine's existing gameplay function (sleep, weather forecast) -- purely a visual-choice layer on top.</description>
  <researcher_notes>Gemini's full answer (genre research on HM:BtN/Stardew/Animal Crossing furniture systems, not independently fact-checked claim-by-claim against those games -- treated as external genre knowledge per AI-ENG-001's Gemini role) named three tiers of implementation cost: (A) "themed set swap" -- buy a full theme, swap all room sprites/palette at once, cheapest but least granular; (B) "anchor slot" -- fixed positions become interactive, player picks per-slot from owned items, Gemini's own recommended middle ground; (C) full Stardew/Animal-Crossing-style free placement with inventory-carried furniture, collision, and layering -- filed separately below as NEEDS_OWNER_REVIEW (TASK-361) since it's a real new system, not a bounded task. Only option (B) was scoped and filed directly here since it has no open design question, needs no new placement/collision system, and cleanly mirrors two patterns already in this codebase (tool_tiers-style dict, Market buy list). Run details: ops/ai-eng-log.md (2026-09-04 entry, gap-analysis run following TASK-358/359).</researcher_notes>
</task_item>

<task_item>
  <id>TASK-361</id>
  <source>AI-LOOP</source>
  <status>NEEDS_OWNER_REVIEW</status>
  <priority>N/A (owner scope/direction call, not yet actionable)</priority>
  <title>Full furniture placement system (Stardew/Animal-Crossing style) -- worth building?</title>
  <description>Companion finding to TASK-360, filed separately per AI-ENG-001's escalation rule (this is a genuine scope/direction call, not something Claude should decide unilaterally). Gemini's genre research on house customization also named the deeper option both Stardew Valley and modern Animal Crossing entries use: furniture carried as inventory items, freely placed/rotated on a tile grid with real collision and layering (rugs on the floor layer, wall items on wall-collision tiles, tables accepting sub-items placed on top). This is a substantially bigger investment than TASK-360's anchor-slot model -- it needs a new grid-placement UI, collision handling distinct from the existing plant/water/harvest grid contract, and a "carried furniture" inventory concept that doesn't exist today. It would give the farmhouse real expressive depth matching the genre's strongest comparison points, but is a multi-task feature on its own, not a small addition, and competes for sprint slots against the NPC/economy gaps TASK-338 already flagged as a bigger acknowledged gap than house decor. Question for the owner: pursue this as a real future task (and at what priority relative to other open work), or is TASK-360's lighter anchor-slot model enough for this game's scope?</description>
  <researcher_notes>Filed per the AI-ENG-001 spec's Human decision escalation section -- does not block other independent work; TASK-360 (anchor slots) already covers the low-cost slice of this gap and can proceed regardless of how this is resolved. No GitHub issue opened (GitHub MCP server currently failing to connect, bad auth header, per this repo's own CLAUDE.md/AI-ENG-001 Open items) -- create one once that's fixed.

  **Owner decision (2026-09-04):** keep open, don't decide now. TASK-360's anchor-slot model is enough for now; revisit full free-placement after the bigger NPC/economy gaps (TASK-338's own acknowledged gap) are addressed.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-362</id>
  <source>AI-LOOP</source>
  <status>COMPLETED</status>
  <priority>P3 (cheap, additive, no dependency on other in-flight work)</priority>
  <title>Silver ore material sink -- consume it in the carpenter kitchen upgrade</title>
  <description>Gap-analysis finding (AI-ENG-001 loop, 2026-09-04), narrowed after verification against the actual code (the original premise -- "mined ore has zero downstream use" -- was WRONG on first check and corrected before filing anything, see researcher_notes). Confirmed via direct code read: `GameData.upgrade_tool()` (scripts/autoload/GameData.gd) already consumes ore as a TASK-321 material sink -- copper_ore for tier 1->2, iron_ore for tier 2->3. But `silver_ore` (the rarest, most valuable of the 3 ore tiers in data/ore/ore.json) is NEVER consumed anywhere in scripts/ -- confirmed via a repo-wide grep, the only other reference is a comment in MountainCaveSpot.gd describing it as a likely drop there, not a consumption site. `CarpenterUpgrade.gd`'s one-time kitchen-extension upgrade (structure_id "house_kitchen") requires silver + wood + stamina only, zero ore. Gemini's genre research (HM:BtN, Stardew Valley) confirmed the standard pattern -- mined ore gates BOTH tool upgrades (already implemented here) AND building/infrastructure upgrades (not implemented here) -- and recommended exactly this as the simplest additive fix, with no new fail state or crafting minigame needed. Scope: add `@export var repair_cost_silver_ore: int = 3` (or similar small amount) to CarpenterUpgrade.gd, following the exact same has_item()-check-before-any-deduction / remove_item()-on-success pattern the file already uses for `repair_cost_wood`, and update the interact-prompt text + soft-fail dialogue to mention it (mirrors the existing wood/stamina dialogue lines exactly). Update `tests/test_carpenter_upgrade.gd` to cover the new requirement (a repair attempt without silver_ore fails with the existing soft-fail pattern, not a crash; a repair with all three requirements met succeeds and consumes silver_ore). No change to GameData.upgrade_tool()'s existing copper/iron ore sink, no change to MiningSpot.gd's roll logic, no new UI screen. Shipped: `repair_cost_silver_ore: int = 3` on CarpenterUpgrade.gd, wired into the existing soft-fail check sequence and deduct/rollback chain. Delegated to Cline; also fixed a latent pre-existing bug found along the way (the wood-deduction-failure rollback refunded silver but was missing a `return false`, silently falling through to grant the upgrade anyway). Code Quality Review also found and fixed test_carpenter_upgrade.gd itself was an orphaned test since TASK-322 (never wired into run_gate.sh) -- wired in now. Commit cdee411, full gate green across 3 runs (481 checks, 36 covered for the first time).</description>
  <researcher_notes>**Verification correction, logged per the loop's own discipline:** the very first premise drafted for this run ("ore is never consumed as an input to any crafting recipe, tool upgrade, or building upgrade anywhere in the game") was checked against `data/` JSON files only and NOT against `scripts/` GDScript consumption sites -- this was WRONG, caught before the Gemini dispatch even completed being useful, by reading `GameData.upgrade_tool()` directly afterward. The corrected, narrower, still-real gap (silver_ore specifically, and only the carpenter building-upgrade path) is what's filed here. This is exactly the "verify every concrete claim before acting" discipline AI-ENG-001 requires, applied to a mistake of my own drafting, not just Gemini's answer.

  Gemini's full answer (genre research on HM:BtN/Stardew Valley ore-utility design, not independently fact-checked claim-by-claim against those games) also suggested: (1) smelting/refining as an intermediate step (Stardew's Bars) -- not adopted, this codebase has no smelting concept and inventing one would be a new system, not a small addition; (2) a Thai-flavored temple-offering/amulet-crafting use for ore -- interesting but a genuine new content system (a shrine-offering mechanic), not filed here, could be a future NEEDS_OWNER_REVIEW candidate if the owner wants more Thai-cultural depth beyond the existing festival/NPC content, but not raised as a formal item since it's speculative flavor, not a verified gap. Run details: ops/ai-eng-log.md (2026-09-04 entry, gap-analysis run following TASK-358/359 and TASK-360/361).</researcher_notes>
</task_item>

<task_item>
  <id>TASK-363</id>
  <source>AI-LOOP</source>
  <status>COMPLETED</status>
  <priority>P2 (owner-confirmed direction, next sprint slot)</priority>
  <title>Recipe discovery via villager friendship (gift-based unlocks)</title>
  <description>Owner decision (2026-09-04): pursue a villager-gift/friendship-based recipe-unlock mechanism (HM:BtN-style), scoping the NEEDS_OWNER_REVIEW finding below now that the mechanism is chosen. Design: a curated subset of recipes.json's 36 recipes (recommend 6-10 -- the more "special"/festive ones, e.g. durian_sticky_rice, mango_sticky_rice, lotus_soup, are good fits; leave staple/ingredient-prep recipes like rice_flour, coconut_milk, palm_sugar known-by-default so early cooking isn't gated on relationships) become locked until the player reaches a specific affinity LEVEL (the existing GameData.level_for()/affinity Dictionary 0-10 scale from TASK-346, not raw 0-100 affinity) with a specific NPC. Mechanism: new GameData.recipe_unlocks: Dictionary (recipe_id -> true once unlocked, mirrors milestones_earned's idempotent shape) + a RECIPE_UNLOCKS_BY_NPC: Dictionary const (npc_id -> {recipe_id: required_level}) as the single source of truth for which NPC unlocks which recipe at which level -- informed by DialogueDB.GIFT_PREFERENCES' existing NPC-food associations where a sensible match exists (e.g. an NPC who already likes a food in GIFT_PREFERENCES is a natural fit to be the one who "teaches" a related recipe), delegate's own judgment otherwise. CookingStation.gd's get_all_craftable()/get_craftable() gain one more filter: a recipe in RECIPE_UNLOCKS_BY_NPC must also be in GameData.recipe_unlocks to be craftable (recipes NOT in the unlock table remain always-craftable, exactly matching current behavior -- fully backward compatible with existing saves, since recipe_unlocks defaults empty and only the curated subset is ever gated). Unlock trigger: fires automatically the moment GameData.affinity[npc_id] crosses the required level (check wherever affinity is currently incremented, e.g. GameData.add_affinity()-style setter) with a "New recipe unlocked!" dialogue naming the recipe, not a separate interact step. Additive persistence (recipe_unlocks Dictionary, same SAVE_VERSION-bump-or-not judgment call as recent similar additions -- TASK-358/360/362 all reasoned through this, follow the same discipline). New test file covering: a gated recipe is NOT in get_all_craftable() below the required level, appears exactly at the level, un-gated recipes are unaffected, unlock fires exactly once and persists through save/load. No change to CookingStation.gd's actual crafting logic, no change to the affinity system's own increment logic beyond adding the unlock-check hook, no new UI screen (the existing show_dialogue path carries the unlock announcement). Shipped for 8 (npc, recipe, level) triples cross-referenced against GIFT_PREFERENCES (ploy/mango_sticky_rice+banana_rice_cake, fah/lotus_soup, elder/kluay_buat_chi, klong/pandan_sticky_rice, child/durian_sticky_rice, nok/khao_tan, handler/tom_yum). Delegated to Cline; hit provider failures across the entire 4-model fallback chain during this task -- motivated building scripts/ci/dispatch_cline.sh this session to automate that retry loop. Code Quality Review fixed a real test bug (missing required "hot" season on a gated recipe, unrelated to the unlock logic itself, caused a false failure). Commit 0c29d23 (merge -> main), full gate green across 3 runs (511 checks, 18 new).</description>
  <researcher_notes>**Verification correction (same discipline as Run 34, applied to my own premise before drafting anything):** originally intended to ask Gemini "how do genre games handle cooking skill progression, since ours has none" on the assumption this was a clear asymmetry vs. fishing_skill/mining_skill. Gemini's answer directly contradicted that framing -- a cooking skill stat is NOT standard in the genre, so building one would have been adding an unwanted mechanic, not filling a real gap. Read the actual answer in full before deciding what (if anything) to file, rather than forcing the original premise through.

  Gemini's 4 suggested lightweight gating mechanisms were each checked against actual code before deciding what to do with them: (1) infrastructure gating -- ALREADY SHIPPED (`requires_infrastructure` check in CookingStation.gd), nothing to file; (2) recipe acquisition via relationships -- the genuine gap, filed above as NEEDS_OWNER_REVIEW since it's a real new system touching the core recipe-availability model, not a bounded fix; (3) ingredient-quality-based output scaling -- checked for an existing "quality" concept to hook into via `grep -rn "quality" scripts/` and found NONE anywhere in this codebase, so adopting this would mean inventing an entirely new ingredient-quality system from scratch, an even bigger scope call than (2), not raised as a separate item since (2) already covers the "is cooking progression worth investing in" question at a lower cost; (4) pantry/storage slot limits -- explicitly NOT adopted, this adds player-facing friction/restriction, which risks conflicting with this project's established no-fail-state, non-punishing design philosophy (the same category of tension the owner already resolved once, rejecting affinity decay for a non-punishing streak-bonus alternative instead) -- a philosophy call for the owner if ever raised, not filed as its own item since it's speculative not verified-needed. No SPECCED companion task filed this run (unlike TASK-358/359 and TASK-360/361) because no small, bounded, no-open-question slice was found -- every real option here is a genuine new-system scope call. Run details: ops/ai-eng-log.md (2026-09-04 entry, gap-analysis run following TASK-358/359, TASK-360/361, and TASK-362).

  **Owner decision (2026-09-04):** pursue villager-gift/friendship-based unlocks specifically (not TV-style or skill-tied). Status flipped SPECCED with the mechanism designed above -- see the description field for the actual scope now that the direction is chosen.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-365</id>
  <source>OWNER</source>
  <status>COMPLETED</status>
  <priority>P3 (cosmetic, additive, no dependency on other in-flight work)</priority>
  <title>Fog weather visual effect (currently unused data)</title>
  <description>Owner request (2026-09-04): environment/atmosphere enhancement pass. Confirmed via grep: "fog" is a real weather value TimeManager rolls (~20-25% of cool-season days, forecastable a day ahead per TASK-355) but has zero consumers anywhere in the codebase -- no visual overlay, no gameplay effect. Originally surfaced as GitHub issue #205 (renumbered to avoid a TASK-number collision with this session's TASK-358/359/360, see TASK-364/ops/ai-eng-log.md). Scope: a new FogDriver.gd following RainDriver.gd's exact established pattern (CanvasLayer, SignalBus.weather_changed listener, toggles a visual effect on weather=="fog", no new signals). Visual approach: a semi-transparent screen-space overlay or a GPUParticles2D drift effect -- delegate's call on which reads better, consistent with this project's existing "subtle, not opaque" tint precedent (see DayNightTintDriver.gd's own bugfix history). Purely cosmetic for this task -- no gameplay tie-in (reduced fishing rate, etc.) unless the owner asks for one later. Instance the new driver in World.tscn (a real node, not just a script -- see researcher_notes for why this matters). Shipped: FogDriver (CanvasLayer) + sibling FogLayer/FogRect ColorRect overlay (pale haze, alpha 0.12) instanced as real nodes in World.tscn, toggling on SignalBus.weather_changed("fog"). New test_fog_driver.gd (15 checks: scene-tree wiring incl. script-not-orphaned, signal-flow incl. cross-fire with rain/overcast and re-arm after clear, color/mouse-filter hygiene), wired into run_gate.sh. Delegated via the 4-model fallback chain; all 4 hit provider failures but left complete, high-quality work reviewed and shipped directly. Code Quality Review caught and fixed a real bug in the delegate's own test file: a top-level `preload()` const forced FogDriver.gd (and its SignalBus autoload reference) to compile before autoloads register under the `--script` entrypoint, causing a false "Identifier not found: SignalBus" compile failure that made all 4 signal-flow checks fail -- fixed by switching to a runtime `load()` inside the test body. Merge with TASK-366 (already on main) required manual resolution of World.tscn/run_gate.sh conflicts (both tasks added sibling driver nodes near DayNightTintDriver) -- resolved by keeping both driver's nodes/functions side by side. Commit 6d410d5 (feat) + 9bd71a9 (merge -> main), full gate green across 3 runs both pre- and post-merge-resolution (543 checks, 15 new).</description>
  <researcher_notes>Found while scoping this: RainDriver.gd and HeatHazeDriver.gd both exist as complete, recently-bugfixed scripts (RainDriver has an owner-confirmed 2026-09-03 fix) but NEITHER is actually instanced anywhere in World.tscn or any other scene -- confirmed via repo-wide grep for both class names outside their own script files. They are dead code: the rain particle effect has never actually played in a real game session despite the script being correct and "fixed." This is a separate, real bug -- filed as TASK-366 alongside the new leaf-particle ambiance work, since both are "wire a particle driver into World.tscn" tasks. Do not fold TASK-366's fix into this task; keep the new FogDriver and the RainDriver/HeatHazeDriver wiring fix as separate, independently reviewable diffs.

  **Compile-order lesson for future test-writing guidance:** a top-level `const X: GDScript = preload("res://some/autoload-referencing/Script.gd")` in a `--script`-entrypoint SceneTree test forces that script to compile before MainLoop/autoload registration completes, producing a misleading "Identifier not found: <Autoload>" compile error that looks like a missing-autoload bug but is actually a load-order artifact. Any test needing a reference to a script that uses an autoload should `load()` it at runtime (inside `_run_all()`/`_initialize()`), not `preload()` it as a class-level const.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-366</id>
  <source>OWNER</source>
  <status>COMPLETED</status>
  <priority>P2 (real bug: an existing, "fixed" feature has never actually run)</priority>
  <title>Wire up orphaned RainDriver/HeatHazeDriver + add leaf-particle ambiance</title>
  <description>Owner request (2026-09-04): environment/atmosphere enhancement pass, part 2. Real bug found while scoping TASK-365: `scenes/core/RainDriver.gd` and `scenes/core/HeatHazeDriver.gd` both exist as complete, working scripts (RainDriver even has an owner-confirmed bugfix dated 2026-09-03) but neither is actually instanced as a node anywhere in `World.tscn` or any other scene -- confirmed via repo-wide grep, only self-references and one comment mention in SignalBus.gd. The rain visual effect has never played in a real session. Scope: (1) instance both `RainDriver` and `HeatHazeDriver` as real CanvasLayer nodes in `World.tscn`, following `DayNightTintDriver`'s existing correctly-wired pattern (same file, already a real node -- use it as the template for exactly how ext_resource + node instancing should look); (2) add each driver's expected child node (RainDriver expects `$RainParticles`, check HeatHazeDriver.gd for its own expected child name) with a real GPUParticles2D/effect node, not just the driver script with nothing to control; (3) verify via a manual or headless check that toggling `SignalBus.weather_changed.emit("rain")` actually makes the particles emit, since this exact class of bug (script correct, wiring missing) would not have been caught by the existing test suite if no test instances the full World.tscn scene tree and checks emitting state -- add a test if none currently covers this. (4) Additionally: add a NEW ambient leaf-particle effect (falling leaves drifting through outdoor areas) as a separate small driver, decorative only -- no leaf particle asset or driver currently exists anywhere in the codebase (confirmed via grep). Reuse an existing particle .tres as a structural template (e.g. lotus_pollen.tres's drift-particle setup) rather than starting a GPUParticles2D config from scratch. Season-gate is optional and delegate's call (e.g. only in "cool" season, or always-on ambiance) -- state the choice and reasoning in the summary. Shipped: both drivers now real nodes in World.tscn (RainDriver/RainParticles using existing rain.tres+rain_streak.png; HeatHazeDriver's HazeLayer/HazeRect sibling), a new always-on LeafDriver (no season-gate -- pure decoration, no meaningful "off" state) using a new leaves.tres adapted from lotus_pollen.tres, and a new test instancing the real World.tscn to catch this exact bug class in the future. Attempted delegation via the full 4-model fallback chain first; all 4 hit provider failures with only shallow progress, finished directly given the fix was already fully researched. Also found (filed separately, TASK-369): FestivalVisualDriver.gd has the identical orphan-wiring problem. Commit eca27be (merge -> main), full gate green across 3 runs (521 checks, 10 new).</description>
  <researcher_notes>The RainDriver/HeatHazeDriver orphan-wiring bug is a genuinely concerning class of issue: a script can be "fixed" and reviewed correctly (see RainDriver.gd's own detailed 2026-09-03 bugfix comment) while nobody notices it was never actually reachable in the running game, because nothing in the test suite instances the full World.tscn tree and checks node presence/emitting state for these specific effects. Worth a general lesson for future Code Quality Review passes on VFX/driver-shaped work: confirm the driver is actually instanced in the scene it's meant to run in, not just that the script itself is correct.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-367</id>
  <source>OWNER</source>
  <status>SPECCED</status>
  <priority>P3 (cosmetic, additive)</priority>
  <title>Extend farmhouse decor anchor-slots to a second slot (bed)</title>
  <description>Owner request (2026-09-04), "furniture" part of a combined environment-enhancement ask. TASK-360 shipped the anchor-slot decor pattern (GameData.decor_choices/DECOR_CATALOGUE, a style-picker interactable, market-purchasable alternate styles) for exactly ONE slot (the shrine). TASK-360's own spec deliberately scoped to one slot first ("Pick ONE decor slot to make interactive first... recommend the shrine") with the pattern designed to extend cleanly. Scope: extend `DECOR_CATALOGUE` with a second slot entry (recommend "bed" -- FarmHouseBed.gd already exists as an established interactable to attach a style-picker sibling to, mirroring FarmHouseShrineStylePicker.gd's exact pattern from TASK-360) with at least one alternate purchasable style, wired the same way (new market buy-offer item, FarmHouse.gd re-skins the bed sprite via GameData.decor_choice("bed")). Do NOT touch FarmHouseBed.gd's existing sleep/stamina-restore gameplay logic -- purely a visual-choice layer on top, exactly matching TASK-360's own constraint. No change to the shrine slot's existing behavior.</description>
  <researcher_notes>This is the smallest, safest possible next increment on TASK-360's pattern -- deliberately NOT the bigger TASK-361 free-placement furniture system (that stays NEEDS_OWNER_REVIEW / deferred per the owner's own 2026-09-04 decision to revisit only after NPC/economy gaps). This task is "furniture" in the sense the owner asked for it, without reopening the TASK-361 scope question.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-368</id>
  <source>OWNER</source>
  <status>SPECCED</status>
  <priority>P3 (cosmetic, additive)</priority>
  <title>Map decoration pass on existing areas + prop-density guideline for future areas</title>
  <description>Owner request (2026-09-04), "map" part of a combined environment-enhancement ask -- explicitly scoped to decoration on EXISTING areas plus a written guideline for future areas, NOT new unlockable areas (TASK-343/344 stay paused per the standing playthrough-first decision). Scope: (1) a light decoration pass adding a handful of existing-asset props (trees, rocks, bamboo clusters, etc. -- reuse `assets/environment/`'s existing texture set, do not generate new art) to World.tscn and/or CoastalArea.tscn's currently sparser tiles, following whatever existing prop-placement convention WorldRender.gd/CoastalArea.gd already use (read them first). Keep this modest -- a handful of props, not a full re-design pass. (2) A short written guideline (a new doc, e.g. `docs/art/environment-prop-density.md`, or a section added to an existing style-guide doc if one fits better -- delegate's call) capturing a rough prop-per-tile-area density target and asset-reuse convention, so future area work (TASK-343/344, whenever they resume) has a concrete density reference instead of ad hoc judgment each time.</description>
  <researcher_notes>Deliberately does not touch TASK-343/344 (still paused) -- this is decoration on what already exists, plus a guideline document for later, not new area construction. Confirmed with the owner via AskUserQuestion before scoping this way (2026-09-04): "map" meant decoration/props on existing areas and a guideline for future areas, not reopening paused area work.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-369</id>
  <source>AI-LOOP</source>
  <status>SPECCED</status>
  <priority>P3 (same class of bug as TASK-366, lower priority since festival visuals are seasonal/rare, not daily)</priority>
  <title>FestivalVisualDriver's FestivalLanterns/PondGlow also never instanced</title>
  <description>Found while fixing TASK-366 (RainDriver/HeatHazeDriver orphan-wiring): `scenes/core/FestivalVisualDriver.gd` references `$"../PondGlowLayer/PondGlowRect"` and `$"../WorldRender/FestivalLanterns"` -- neither `PondGlowLayer` nor a `FestivalLanterns` GPUParticles2D node exists anywhere in World.tscn (confirmed via grep, same check used to find the TASK-366 bug). The festival glow/lantern visual effect has never actually played in a real session despite the driver script being complete. Scope: mirror TASK-366's fix exactly -- add `PondGlowLayer/PondGlowRect` (a ColorRect, likely a warm/gold tint given "glow") and `WorldRender/FestivalLanterns` (a GPUParticles2D using the existing `festival_lanterns.tres` + `lantern_glow.png` assets, which already exist in `assets/particles/` unused) as real nodes in World.tscn, then verify via a test (following test_particle_drivers.gd's pattern from TASK-366: instance real World.tscn, fire SignalBus.festival_triggered, confirm the glow/lanterns actually toggle) that the effect actually fires.</description>
  <researcher_notes>Not fixed as part of TASK-366 to keep that diff scoped to what it already covered (rain/haze/leaves) -- filed separately per this project's own "don't scope-creep a diff" convention. `assets/particles/festival_lanterns.tres` and `assets/particles/lantern_glow.png` already exist and are unused, same reuse-don't-recreate pattern TASK-366 followed for rain.tres.</researcher_notes>
</task_item>
