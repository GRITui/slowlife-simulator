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
- [ ] TASK-323 split B (breeding/incubator), 324, 325 —
      remaining approved backlog items
- [ ] All MVP-scope systems implemented + headless-tested
- [ ] Feature freeze declared — new asks go to a post-launch backlog
- [ ] Save/migration format finalized and locked (hard-escalate category
      in `AI-ENG-001` — never auto-merged, always human-reviewed)

## Phase 3 — Polish / QA / Performance
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
