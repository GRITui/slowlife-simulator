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
- [x] **Sprint 3 — second scored mini-game.** TASK-339: Songkran
      Cooking Contest, reusing the existing festival window rather than
      adding a new one. Ties the 36-recipe cooking system into
      competition for the first time.

**"Broaden to compete with HM:BtN" plan closed** (2026-09-02). All 6
items shipped across 3 sprints, full gate green on every merge, every
diff Code-Quality-Reviewed. Unchanged from the original verdict: no
human has played this end-to-end yet — still the single highest-
leverage gap, and the natural next step now that this plan is done.

## 6 romance + 6 rivals + 5 unlockable areas (2026-09-02, 5-sprint plan)
A deliberate, owner-confirmed one-time reversal of the no-fail-state
precedent above: rivals have real stakes (a neglected candidate can be
permanently lost), designed to be as fair as that can be — a 90-day
window from first meeting, 3 telegraphed warnings, soft landing on loss.
- [x] **Sprint 1 — save schema + mechanism.** TASK-340: `SaveManager`
      v3→v4, `RivalClock.gd` (ships inert, empty pairing table).
      Real bug caught by the test suite: a migration block was nested
      one level too deep and silently never ran for the most common
      case. Fixed, reverified.
- [x] **10-level system, phase 1 — shared scale + romance retrofit.**
      TASK-346: `GameData.level_for()` (0-10 derived from 0-100
      affinity, no schema change), Ek/Fah/Ploy's dialogue
      retrofitted from 4 tiers to 10 numbered pools. Landed ahead of
      Sprint 2 in the numbering since TASK-341 (below) depends on it.
- [x] **Sprint 2 — 3 new romance candidates.** TASK-341: Chang, Klong,
      Yaa, bringing the total to 6, authored directly in the
      10-level shape. Also closed TASK-345's fairness gap for all 6
      candidates via a "1_warned" dialogue pool.
- [x] **Schema v5 — rival progress meter.** TASK-347: `rival_progress`
      (replaces day-elapsed tracking, nudgeable), `rival_friendship`,
      `rival_confessed` fields; `RivalClock.nudge_progress()`; festival
      tie-in (Fishing Competition -> fah, Songkran -> ploy, only the
      thematically-linked rival). Prerequisite for Sprint 3 below.
- [x] **Sprint 3 — 6 rival NPCs.** TASK-342: `RivalClock.PAIRS` wired
      live (Yai/Ohm/Rung/Note/Fon/Boon), friendship + confession
      dilemma. First real test of the delegate-first policy on a large
      task — mechanical implementation delegated to OpenCode, dialogue
      self-executed; Code Quality Review caught and fixed a real
      alpha-channel bug in the delegate's portrait script before merge.
- [PAUSED] 10-level system, phases 2-3 — animals (TASK-348) and
      villagers (TASK-349), folded into the same plan per owner request.
      Paused 2026-09-04 (see owner decision below) — not dropped.
- [PAUSED] Sprint 4 — 2 more unlockable areas (Deep Canal Bend, Sacred
      Grove). TASK-343. Paused 2026-09-04.
- [PAUSED] Sprint 5 — final 2 unlockable areas (Lotus Maze Shore,
      Coastal Trading Post), completing the set of 5. TASK-344. Paused
      2026-09-04.
- [ ] **Deferred fast-follow (per Gemini second opinion + owner
      "Proceed" 2026-09-02):** 1 new scored mini-game (Harvest Race,
      Yai/Ek) + 3 rival quest chains with a 30-day bidirectional
      deadline (Note/Chang — mask-carving; Fon/Klong — festival
      performance; Boon/Yaa — remedy quest) — specced after the 8
      sprints above ship, not before. Also blocked behind the
      playthrough per the same 2026-09-04 decision.
- [ ] **Full human playthrough pass — PROMOTED to immediate next step
      (owner decision, 2026-09-04).** Content sprints above (TASK-343,
      344, 348, 349) explicitly paused, not sequenced around — this is
      the highest-leverage gap and has been flagged twice before without
      acting on it; the one time it did happen it caught 2 real bugs
      (permanently-opaque day/night shader, stat bars never rendering)
      that the full headless suite missed entirely. Resume the paused
      content sprints only after this pass and its fixes land.
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
- [ ] Pricing/monetization model — **NEEDS OWNER DECISION, explicitly
      parked for now (2026-09-04)** — not urgent pre-playthrough; revisit
      when Phase 4 actually starts (no monetization code exists today)
- [ ] TestFlight build, external testers, feedback loop
- [ ] App Store review submission

## Phase 5 — Launch
- [ ] Release build shipped
- [ ] Launch-day monitoring plan — **NEEDS OWNER DECISION, explicitly
      parked for now (2026-09-04)** — not urgent pre-playthrough (no
      crash-reporting/analytics pipeline exists yet)

## Phase 6 — Post-launch / Live-ops
- [ ] Player feedback triage → backlog
- [ ] Content update cadence — **NEEDS OWNER DECISION**
- [ ] Gemini-loop Producer role: periodic "what's stalled" retro summaries

## First human playthrough (2026-09-02) — findings and fixes
The single highest-leverage gap flagged repeatedly throughout this plan
finally happened. Real bugs surfaced immediately that no amount of
headless testing had caught:
- [x] **Day/night tint shader was permanently fully opaque**, hiding
      the entire game world behind a solid color wall. One-line fix
      (a stray `* 0.0` nullified the alpha fade term). Pre-existing
      bug (TASK-034), not a regression.
- [x] **Stat bars (Stamina/Harmony) have never rendered their fill
      graphic**, ever — `HUD.tscn` used non-existent `TextureProgressBar`
      property names (`under_texture`/`progress_texture` instead of
      `texture_under`/`texture_progress`). Found and fixed as part of
      TASK-351.
- [x] **TASK-351 — HUD visual polish**, applying `ART_STYLE_GUIDE.md`'s
      already-specified but never-implemented visual spec.
- [ ] **TASK-350 — active-seed selection for planting** (currently
      always plants rice, no player control). Decided: one shared
      InputMap action (`Q` / gamepad `L1` / HUD-tap), fallback to
      jasmine_rice with a distinct dialogue line when no seed is
      primed. Ready to build.

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
