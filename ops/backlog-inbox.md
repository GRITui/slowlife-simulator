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
  <status>NEEDS_OWNER_REVIEW</status>
  <priority>P1 (fairness gap in an already-approved mechanic — should land before or alongside Sprint 3)</priority>
  <title>Early rival-awareness — fix a real fairness gap in the TASK-340/341/342 warning system</title>
  <description>Found while discussing Sprint 2/3: the existing candidate "rival" flavor-dialogue tier (built for Niran/Fah/Ploy under TASK-324, planned for Kiet/Malee/Kanya under TASK-341) only surfaces at close tier (affinity >= 60) — but the loss condition fires when affinity NEVER reaches 25. A player actually at risk of losing a candidate would never see that hint at all; the rival NPC's own tier-0 dialogue (as specced in TASK-342) was also written deliberately soft ("casual, no pressure yet"), revealing nothing. As specced, an at-risk player could go the full 90 days with zero warning and learn what happened only from the single ambient "X has married Y" message after the fact — directly contradicting the fairness goal the whole mechanic was designed around.</description>
  <researcher_notes>Proposed fix (not yet applied to the pending specs, filed here instead per owner instruction 2026-09-02): (1) rival tier-0 dialogue should establish the competing-interest fact immediately on first meeting, not withhold it to later tiers; (2) add a distinct line to each candidate's OWN stranger-tier pool (their lowest tier, the one an at-risk/disengaged player actually sees) that surfaces once rival_warning_shown >= 1, so the person the player would actually lose is the one delivering the warning, not a rival the player may never approach. Needs applying to docs/research/TASK-341-spec.md and TASK-342-spec.md before either is built. GitHub issue: not yet opened.</researcher_notes>
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
