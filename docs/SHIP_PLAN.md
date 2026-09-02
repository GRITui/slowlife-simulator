# Ship Plan — slowlife-simulator

Thai-themed cozy farm sim, targeting *Harvest Moon: Back to Nature*-level
depth, iOS target. Skeleton roadmap — phases are gates, not calendar dates;
a phase isn't "done" until its exit criteria are actually true, not just
time-elapsed.

## Phase 0 — Where we are now
- [x] Core systems shipped (123/123 backlog tasks): farming, fishing,
      festivals, quests (22 objectives), NPC hearts/relationships,
      crafting/cooking, seasonal cycle, HUD, safe-area/touch compliance
- [x] Headless test suite green (`run_tests`, `run_engine_tests`)
- [ ] `[HOLD]` Apple Developer enrollment, real bundle ID, Team ID
      (see `docs/ios_export_template.md`)
- [ ] Unknown: how content depth actually compares to HM:BtN — first task
      for the Gemini research loop (QA/Balance role, `AI-ENG-001`)

## Phase 1 — Content/Scope Gate ("is there enough game here?")
- [x] Gemini-loop: systematic HM:BtN feature comparison → gap list,
      cross-checked against actual code, routed to `ops/backlog-inbox.md`
      as 6 proposed tasks (TASK-321..326). Details: `ops/ai-eng-log.md`
      run 1.
- [x] Backlog groomed / cost-impact sequenced (Producer-role pass,
      `ops/backlog-inbox.md` 2026-09-01 note) — recommendation only.
- [x] Define MVP scope vs stretch — **DECIDED 2026-09-01**: TASK-321..326
      all in MVP scope, all flipped `READY_FOR_PM`. TASK-324 approved in
      full (rivals + life progression), explicitly accepting the tension
      with the no-fail-state precedent rather than avoiding it — see
      `ops/backlog-inbox.md` PO LEDGER 2026-09-01.
- [x] Exit criteria: no P0 gap left unaddressed or explicitly deferred —
      all 6 gaps from the Phase 1 comparison have an explicit scope
      decision, none silently dropped. **Phase 1 complete.**

## Phase 2 — Content Complete / Feature Freeze
- [x] TASK-327 (unplanned, found mid-scope): seed purchasing was
      structurally broken (only jasmine_rice plantable in real play) —
      fixed with a new market shop UI, ahead of TASK-321..326 since it
      was more foundational. Commit `11d734e`. Details: `ops/ai-eng-log.md`
      run 6, `docs/research/TASK-327-spec.md`.
- [x] TASK-323 split A (livestock quality tiers) — commit `76f922c`.
- [x] TASK-326 (redesigned — shipping-milestone stamina) — PR #178,
      `72c03d1`. Process incident: OpenCode self-merged before Claude's
      Code Quality Review ran, a real bug (redundant signal emission)
      shipped and had to be fixed forward (`8e3adff`). Pipeline corrected
      for future runs — see `ops/ai-eng-log.md` run 7.
- [x] TASK-322 (carpenter house-kitchen upgrade) — `7df45e8` + regression
      fix `9679f23`. Process fix from run 7 held (no self-merge this
      time); Code Quality Review caught a different bug class (a
      pattern-mismatch double-emission, not a leftover duplicate) plus
      an unrelated Claude-authored regression in `test_silver.gd` from
      TASK-327. See `ops/ai-eng-log.md` run 8.
- [x] TASK-321 (mining/ore, MVP scope) — `f1b9f87`. Redesigned down from
      the original floor-gen concept to mirror `FishingSpot.gd`'s pattern.
      Mid-task provider switch (slow OpenCode/GLM-5.3-Flash → Cline);
      Code Quality Review caught a real editing-corruption bug and
      confirmed two established bug classes stayed clean this time.
      See `ops/ai-eng-log.md` run 10.

### Remaining sprint plan (3 sprints to close out Phase 2)
Ordered smallest/best-understood first, most design-sensitive last — not
task-number order.

- [x] **Sprint 1 — TASK-323 split B** (breeding/incubator) — `9aa8f59`.
      Capped herd-count (chicken_count/buffalo_count, 1..3) scales yield,
      grows automatically via the daily interact once hearts>=2 + silver
      — no new animal entities, mirrors the skill-growth idiom. Third hit
      this session on the same OpenRouter rate limit (runs 7/10/11) —
      Cline completed 2 of 4 files cleanly before failing; Claude
      completed the rest directly rather than re-dispatching. See
      `ops/ai-eng-log.md` run 11.
- [x] **Sprint 2 — TASK-325** (redesigned: companion bond + race tie-in)
      — `f5cb512`. Investigation found riding/racing (buffalo) and a
      pet companion (cat) already shipped; real gap was companion
      progression, not a literal dog/horse. 4th hit on the same
      OpenRouter rate limit this session; Code Quality Review found 3
      real bugs in the generated test file (unresolvable global,
      tier-math error, unset `_player`), all fixed directly. See
      `ops/ai-eng-log.md` run 12.
- [x] **Sprint 3 — TASK-324** (rival flavor + life progression) — `1cd8088`.
      Rivals implemented as flavor-only dialogue, zero mechanical effect
      (honors the owner's no-fail-state note). Pregnancy/birth/toddler
      staged onto the existing anniversary loop, harmony-only bonuses,
      silver/event-count left exactly unchanged (test_anniversary.gd's
      exact assertions were the hard constraint here). Two provider
      failures before real progress (Cline's own `stealth/ox-alpha` out
      of credits, then `minimax-m3:free`'s 5-minute stall before its 6th
      rate limit of the session) — see `ops/ai-eng-log.md` run 13 for a
      worktree-concurrency lesson worth reading before the next delegated
      run.

**Phase 2 complete.** All 6 approved backlog items (321, 322, 323 A+B,
324, 325, 326) shipped 2026-09-01.
- [x] All MVP-scope systems implemented + headless-tested — `run_tests.gd`
      100/100, `run_engine_tests.gd` 50/50 as of the TASK-324 merge.
- [ ] Feature freeze declared — new asks go to a post-launch backlog.
      **Owner call, not yet made.**
- [x] Save/migration format audit — `SaveManager.gd` was silently
      dropping ~24 of ~30 `GameData.gd` fields on every save/load cycle
      (only inventory/harmony/season/silver/a11y prefs ever persisted).
      Extended to v3 covering everything added through TASK-321..326;
      `test_save_compat.gd` grown 14→35 checks (v1→v3 and v2→v3
      migration + full round-trip). Still human-reviewed per the
      hard-escalate policy — not auto-merged.

## Phase 3 — Polish / QA / Performance
- [x] Fixed latent `@onready $InteractArea` null-bug in `FishingSpot.gd`
      (mirrors a bug already caught in `MiningSpot.gd`'s first draft) —
      both dynamically-instanced spots now build a real `Area2D` in
      `_ready()`, so proximity interact actually works in real play.
- [x] Raised the Y-sort perf budget 44→49 to account for TASK-322's
      `CarpenterUpgrade` sprite; excluded `MiningSpot` (no sprite, was
      incorrectly counted against the budget).
- [x] HUD progression gap closed — companion bond, chicken hearts/herd
      size, fishing/mining skill previously had zero HUD surface. Added
      `SignalBus.companion_bond_changed` (parity with the existing
      buffalo/chicken pattern) and two new combined-stat labels
      (`FarmHeartsLabel`, `SkillsLabel`). See `ops/ai-eng-log.md` run 14.
- [x] **Fixed a real economy-exploit:** completed quests never left
      `GameData.active_quests`, so any later unrelated action sharing an
      already-satisfied objective id re-triggered that quest's payout —
      unbounded silver/harmony/item duplication for the rest of a save.
      Guarded both `QuestLog.complete_objective_everywhere()` and the
      manual `complete_objective()` entry point against re-paying an
      already-complete quest. See `ops/ai-eng-log.md` run 15.
- [x] Wired the pre-existing `tests/ui/test_touch_targets.gd` (was
      orphaned — passing but not part of `run_gate.sh`) into the `all`
      gate so future UI changes can't silently regress touch-target size.
- [x] **Gemini-loop round 2** — deep gap analysis vs HM:BtN on gameplay
      depth / content range / NPC engagement (not just a feature
      checklist this time). Two quick wins shipped immediately: villager
      gift-giving (data already existed, only romance candidates could
      use it) and a real pre-existing bug the fix surfaced — quest
      talk-objectives were silently skipped on any interact where the
      player also happened to hold a giftable item. 7 larger items filed
      to `ops/backlog-inbox.md` as TASK-328..334 with priority labels
      (P1: weather-reactive schedules/dialogue — infra exists, low
      effort; P2: festival density, milestone collectibles, side-quest
      noticeboard; P3: affinity decay — flagged as a no-fail-state
      design conflict needing explicit owner sign-off, and tool AoE/
      charge tiers — real depth gap but touches the core interaction
      model). See `ops/ai-eng-log.md` run 16.
- [x] **3-sprint autonomous run closed all 6 non-deferred TASK-328..334
      items.** Sprint 1 (self-executed): weather-reactive NPC schedules
      + dialogue. Sprint 2 (OpenCode-delegated): monsoon festival
      density (2 new flavor-only festivals — monsoon had zero before
      this), repeatable side-quest noticeboard. Sprint 3
      (OpenCode-delegated, after the top 3 provider tiers all hit
      exhaustion/rate-limits back to back — fell to `minimax-m3:free`):
      milestone collectibles across 5 varied activities, and a scope
      correction found before delegating — TASK-334's ticket assumed no
      multi-tile interaction existed; a mounted 3x3 mechanic already
      did (planting only), so the real gap was extending it to water/
      harvest, not a new touch-charge system. TASK-333 (affinity decay)
      deliberately excluded — still needs an explicit owner call on the
      no-fail-state design tension. All 5 delegated/self-executed diffs
      passed Code Quality Review and an independent full-gate re-run
      before merge. See `ops/ai-eng-log.md` run 17.
- [x] **TASK-333 resolved.** Brought back for discussion; owner rejected
      decay and picked a non-punishing alternative — a weekly
      interaction streak (`GameData.record_weekly_engagement()`) that
      grants a small bonus for consistent engagement instead of ever
      reducing affinity. Every item from the Gemini gap-analysis
      research pass is now shipped or explicitly resolved. See
      `ops/ai-eng-log.md` run 18.

## Broaden to compete with HM:BtN (2026-09-02 quality/stickiness verdict)
- [x] **Sprint 1 — cast & stakes.** TASK-335: third romance candidate
      (Ploy). TASK-336: Fishing Competition is now a real scored
      contest — the game's first competitive mini-game (zero fail
      state, every placement tier grants something).
- [x] **Sprint 2 — world breadth.** TASK-337: Mountain Cave, a
      secondary area gated behind mining mastery (no map/grid
      expansion, no new item, no save-schema change). TASK-338: Nok,
      a 12th named villager. Bonus: found and fixed a real pre-existing
      bug while scoping this — headman/vet had dedicated portraits
      that silently never rendered (always showed Elder instead).
- [ ] Sprint 3 — second scored mini-game. Queued, pending check-in.
- [ ] Full human playthrough pass (headless tests don't substitute for this)
- [ ] Performance budget check on real iOS hardware (frame time/thermal,
      not just Compatibility-renderer correctness)
- [ ] Art pass: 16-color palette consistency, texture compression sizes
      verified against `docs/art/style_guide.md`
- [ ] Accessibility/touch-target audit (44x44pt minimum — re-verify, don't
      assume it still holds after content additions)
- [ ] Bug backlog burned down to zero P0/P1

## Phase 4 — Launch Prep
- [ ] `[HOLD → RESOLVE]` Apple Developer Program enrollment ($99/yr)
- [ ] `[HOLD → RESOLVE]` Bundle ID finalized — locks permanently on first
      App Store Connect registration (proposed:
      `com.gritui.slowlife-simulator`)
- [ ] `[HOLD → RESOLVE]` Team ID / signing
- [ ] Store listing: name, screenshots, description, age rating
- [ ] Pricing/monetization model — **NEEDS OWNER DECISION** (no
      monetization code exists today)
- [ ] TestFlight build, external testers, feedback loop
- [ ] App Store review submission

## Phase 5 — Launch
- [ ] Release build shipped
- [ ] Launch-day monitoring plan — **NEEDS OWNER DECISION** (no
      crash-reporting/analytics pipeline exists yet)

## Phase 6 — Post-launch / Live-ops
- [ ] Player feedback triage → backlog
- [ ] Content update cadence — **NEEDS OWNER DECISION**
- [ ] Gemini-loop Producer role: periodic "what's stalled" retro summaries

## Known gaps (not placeholders — real, named absences)
- No monetization model defined or implemented
- No crash reporting / analytics pipeline
- No human-verified comparison of content depth against HM:BtN yet
  (Phase 1's first job)

## Related
- `docs/research/AI-ENG-001-gemini-research-enhance-loop-spec.md` — the
  Gemini research/critique loop referenced throughout this plan
- `docs/ios_export_template.md` — iOS export config and `[HOLD]` items
- `backlog.json`, `ops/backlog-inbox.md` — task-level tracking this plan
  feeds into
