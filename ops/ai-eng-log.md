# AI-ENG-001 run log — append-only

One entry per Gemini-loop run: role, question, answer summary, integration
outcome, stop reason. See `docs/research/AI-ENG-001-gemini-research-enhance-loop-spec.md`
for the mechanism and rules this log exists to make auditable.

---

## 2026-09-01 — Run 1

- **Role:** QA / Balance Tester
- **Question source:** Backlog-gap derived (Phase 1 of `docs/SHIP_PLAN.md`
  — "unknown: how content depth compares to HM:BtN")
- **Question asked:** HM:BtN feature/depth gap-check against current
  systems (farming, fishing, festivals, quests, hearts, crafting/cooking,
  seasons). Full prompt in Gemini thread "Farm Sim Gap Analysis".
- **Answer summary:** Gemini returned 7 prioritized areas: livestock
  depth, mining/tools, energy economy, house/farm upgrades, life-progression
  narrative events, working pets, shipping-unlock economy.
- **Verification performed:** Cross-checked every claim against the actual
  codebase (`rg` over `scripts/`, `scenes/`) before proposing anything —
  per the loop's integrate-don't-trust-blindly rule.
- **Findings:**
  - Already implemented, NOT gaps (Gemini was wrong/imprecise): stamina
    system (`GameData.gd`), basic livestock care (`ChickenCoop.gd`,
    `Buffalo.gd`/TASK-020), marriage as an anniversary-loop
    (`RomanceNPC.gd`/TASK-282), tool tiers (simpler int-tier system,
    not ore/blacksmith — a deliberate existing design, not a gap).
  - Confirmed real gaps, filed as `NEEDS_OWNER_REVIEW`: TASK-321 (mining),
    TASK-322 (house/building upgrades), TASK-323 (livestock quality/
    breeding depth), TASK-324 (rival events + pregnancy/childbirth/
    toddler), TASK-325 (working pets/mounts), TASK-326 (permanent stamina
    upgrades + shipping-triggered unlocks).
  - Deliberately NOT proposed: a strict multi-year evaluation/deadline
    score. Conflicts with this project's established no-fail-state cozy
    design philosophy (precedent: TASK-319 spec). Noted here per the
    provenance rule rather than silently dropped.
- **Tie-break rule applied:** N/A this run — no conflict with an existing
  recorded decision, this was net-new gap discovery.
- **Integration outcome:** 6 proposed backlog tasks appended to
  `ops/backlog-inbox.md` (TASK-321 through TASK-326), all
  `NEEDS_OWNER_REVIEW` — MVP-vs-stretch scoping is an explicit owner
  decision per `docs/SHIP_PLAN.md` Phase 1, not a default-yes.
- **Stop reason:** goal met (1 integrated output produced) after 1
  iteration — well under the 5-iteration cap. Stopped rather than
  continuing to spend more Gemini calls without a new question queued.

---

## 2026-09-01 — Run 2

- **Role:** Culture Consultant
- **Question source:** Independent of Run 1 / Phase 1 scope decision —
  authenticity QA on already-shipped content, chosen specifically because
  it doesn't depend on anything needing the project owner's input.
- **Question asked:** Fact-check of 3 shipped festival flavor texts
  (Songkran, Wan Sart, Lopburi monkey event) for cultural accuracy/tone.
  Full thread: "Fact-Checking Thai In-Game Festivals".
- **Answer summary:** Songkran framing fine as-is (optional depth
  enhancement, not a correction). Lopburi event respectful/accurate, but
  its display name is just a province name with no event framing — needs
  a title. Wan Sart has a real factual error: game required a generic
  "wan_sart_basket" (banana leaf + rice) as the offering, but the actual
  Wan Sart dish is Krayasat (sticky rice, peanut, sesame, palm sugar).
- **Verification performed:** Grepped the codebase before touching
  anything — found `kra_yasat` already existed as a fully-built recipe
  (`data/recipes/recipes.json`) explicitly described as "the Wan Sart
  merit-offering," but `WanSartTrigger.gd` was wired to the wrong,
  generic item. Not a missing feature — a wiring bug.
- **Tie-break rule applied:** N/A — this wasn't a conflict with a prior
  decision, it was an unwired-but-already-built correct asset.
- **Integration outcome:** Implemented directly (small, well-scoped,
  test-covered — not a systemic/architecture change):
  - `scenes/festival/LopburiRaid.gd`: dialogue speaker renamed
    `"Lopburi"` → `"Lopburi Monkey Raid"` (4 lines).
  - `scenes/festival/WanSartTrigger.gd`: `release_offering()` now checks
    `kra_yasat` instead of `wan_sart_basket`; dialogue updated to match.
    `wan_sart_basket` recipe left intact in `recipes.json`/`GameData.gd`
    for save compatibility — not deleted, just no longer what the
    festival consumes.
  - `scripts/persistence/QuestLog.gd`: `make_offering` objective now
    also accepts `kra_yasat` (kept `wan_sart_basket` in the check too).
  - `tests/test_wansart.gd`: updated to craft/assert against `kra_yasat`.
  - Verified: `run_tests.gd` 100/100 (unaffected), `test_wansart.gd` 6/6,
    `test_lopburi_raid.gd` 6/6 — all green.
- **Not implemented:** Gemini's note that traditional offerings go to
  temple monks rather than being left in fields — that's a mechanic/
  location change, not a text fix, and out of scope for this pass.
- **Stop reason:** goal met (1 integrated, test-verified fix) after 1
  iteration.

---

## 2026-09-01 — Run 3

- **Role:** Designer/tooling research (choosing an OpenCode delegate model)
- **Question source:** Explicit — project owner asked for a
  research→fact-check→recommend pass on which free OpenCode model to use
  as a third pipeline worker (see `AI-ENG-001` pipeline reassessment).
- **Question asked:** Real-world coding ability of the free models
  actually available via `opencode models` (glm-5.2, minimax-m3,
  nemotron-3-ultra-550b, nemotron-3-super-120b, ling-3.0-flash-fin,
  gemma-4-26b/31b, lfm-2.5-2.6b), for GDScript/Godot 4 delegate work.
  Full thread: "Free Coding Agent Model Comparison".
- **Answer summary:** Ranked GLM-5.2 best overall (agentic coding,
  multi-file context retention), MiniMax M3 for speed, Nemotron-3-Ultra
  as heavy fallback, Gemma 4 for isolated single-file scripts only,
  Nemotron-3-Super as lightweight backup. Flagged two as poor fits:
  `ling-3.0-flash-fin` is finance-tuned, not code; `lfm-2.5-2.6b`'s own
  vendor reportedly advises against agentic coding use (~15.8% tool-call
  error rate).
- **Verification performed:** None possible — these models and their
  cited benchmarks (OpenRouter, Z.AI docs) postdate what I can
  independently check. Noting this honestly rather than presenting it as
  verified: this answer is being trusted at face value more than usual,
  which is exactly the tradeoff of asking about fast-moving external
  information at all.
- **Integration outcome:** Selected GLM-5.2 (`opencode/glm-5.2` or
  `openrouter/z-ai/glm-5.2:free`) as the default OpenCode delegate model.
  Not yet used on a real task — first real assignment should be treated
  as a trial, not blind trust, given the verification gap above.
- **Stop reason:** goal met (1 answer, 1 selection made) after 1
  iteration.

---

## 2026-09-01 — Run 4 (OpenCode worker, first real trial)

- **Worker:** OpenCode (see fallback chain below — 4th attempt succeeded)
- **Isolation:** `git worktree add /Users/grit/slowlife-game-loop-opencode-test1
  -b opencode-test-songkran`, based on `main`@51b06eb. Never touched the
  primary working tree.
- **Task:** Add one respectful-tradition dialogue line to
  `SongkranTrigger.gd`, addressing the "optional enhancement" Gemini noted
  in Run 2 (Rod Nam Dum Hua / Nam Rom water-pouring blessing) but that
  wasn't implemented at the time. Explicitly scoped: exactly one
  `SignalBus.show_dialogue.emit` line, nothing else in the file touched.
- **Fallback chain actually exercised** (captures the error signatures the
  spec previously flagged as unknown):
  1. `opencode/glm-5.2` (OpenCode Zen) → `Error: Insufficient balance.`
     (account-wide, not per-model — see attempt 3)
  2. `openrouter/z-ai/glm-5.2:free` → `[Decart] z-ai/glm-5.2:free is
     temporarily rate-limited upstream.` (different failure mode: upstream
     rate limit, not account balance)
  3. `opencode/minimax-m3` (OpenCode Zen) → same `Insufficient balance`
     error as attempt 1 — confirms the OpenCode Zen quota is exhausted
     account-wide, not per-model.
  4. `openrouter/minimax/minimax-m3:free` → **succeeded.**
- **Result:** Diff was exactly the requested single line — no scope creep,
  no untouched-file edits, no suspicious content. Fresh worktree initially
  showed 3 unrelated test failures (`cropdata`, `worldrender`) that turned
  out to be a missing `godot --headless --import --path .` step (fresh
  worktrees have no `.godot/imported` cache) — not caused by OpenCode's
  change. After import: `run_tests.gd` 100/100, `test_songkran.gd` 7/7,
  all green.
- **Judgment-gate check (GitHub integration policy criteria, applied
  manually since GitHub MCP isn't connected):** tests green ✓, diff scoped
  ✓, diff size trivial ✓, no injected/suspicious content ✓, doesn't touch
  any always-escalate category ✓. Passes on every criterion.
- **Integration outcome:** Initially held for review; project owner then
  gave standing authorization (confirmed twice) to auto-commit/merge any
  AI-ENG-001 output that passes the judgment gate — recorded durably in
  `CLAUDE.md` Guardrails, not just this one commit. Committed
  (`23c5f9d`, message credits the actual model that produced it:
  `openrouter/minimax-m3:free`) and fast-forward merged into `main`.
  Worktree and branch cleaned up after merge.
- **Stop reason:** goal met (1 successful trial, full fallback chain
  exercised and documented, merged) after 4 model attempts / 1 logical
  task.

---

## 2026-09-01 — `NEEDS_OWNER_REVIEW` resolved: TASK-321..326 scope decision

Not a Gemini/OpenCode run — recording the owner's answer to Run 1's
escalation, per the loop's own rule that the *next* run must surface and
resolve outstanding `NEEDS_OWNER_REVIEW` items before starting new work.

- **Decision:** all six proposed tasks (TASK-321 mining, TASK-322 house
  upgrades, TASK-323 livestock depth, TASK-324 rivals+life progression,
  TASK-325 pets/mounts, TASK-326 stamina/shipping unlocks) approved for
  MVP scope. Status flipped `NEEDS_OWNER_REVIEW` → `READY_FOR_PM` in
  `ops/backlog-inbox.md`.
- **TASK-324 specifically:** approved in full, including rival events —
  the owner explicitly accepted the tension with the established no-fail-
  state cozy precedent (TASK-319) rather than avoiding it. Noted for
  implementation: rival "pressure" and "no hard fail-state" aren't
  mutually exclusive; worth building it in a way that respects the
  precedent's spirit even though the scope itself is now settled.
- **Outcome:** `docs/SHIP_PLAN.md` Phase 1 marked complete — all gaps from
  the Phase 1 gap-comparison now have an explicit scope decision, none
  silently dropped. TASK-323/325/326 are the OpenCode-shaped candidates
  for the next implementation pass (per the Producer-role sequencing note,
  best cost/impact ratio first); TASK-321/322 are bigger new-architecture
  work better kept as Claude's own per the OpenCode-worker scoping rule.

---

## 2026-09-01 — Run 5 (OpenCode worker, first real feature delegation)

- **Worker:** OpenCode, `openrouter/minimax/minimax-m3:free` — succeeded on
  the first attempt this time (no fallback needed).
- **Isolation:** `git worktree add /Users/grit/slowlife-game-loop-task323
  -b task-323-livestock-quality`, based on `main`@23c5f9d (post Songkran
  merge). `godot --headless --import` run before testing, per the Run 4
  lesson now baked into the spec's setup checklist.
- **Task:** TASK-323 split A (quality tiers only — breeding/incubator
  split off as its own future task, too big for a first feature-level
  delegation). Claude (not OpenCode) designed the scope first: mirror the
  existing `buffalo_affinity`/`buffalo_hearts()` pattern exactly for
  chickens (new signal, new GameData vars/funcs, new sell prices), then
  gate a quality-tier item swap (`buffalo_milk_high` / `egg_gold`) at 3+
  hearts in both `Buffalo.gd` and `ChickenCoop.gd`, plus a new test file
  mirroring the two existing reference tests. Prompt gave exact variable
  names, thresholds, and prices to remove ambiguity — this is a bigger,
  multi-file task than Run 4's one-liner, so precision mattered more.
- **Result:** All 5 requested changes made, nothing extra touched
  (`git diff --stat`: 4 files + 1 new test, 26/92 lines). New test file
  correctly mirrors reference test structure and covers both species at
  both tiers (16/16 passing). Regression-checked the two existing tests
  that exercise the touched functions (`test_buffalo_hearts.gd`,
  `test_hearts_live.gd`) — both still pass; the daily-gate/affinity-cap
  logic those cover wasn't disturbed.
- **Judgment-gate check:** tests green (100/100 full suite, 50/50 engine
  suite, 16/16 new) ✓, diff scoped exactly to the 5 requested files ✓, diff
  size small ✓, no injected content ✓, no always-escalate category touched
  (additive `SignalBus.gd` signal only, no save-format break, no CI/build
  config) ✓.
- **Integration outcome:** Committed (`76f922c`) and merged to `main`
  under the standing auto-merge authorization — no separate confirmation
  needed this time, the policy is now durable per `CLAUDE.md` Guardrails.
  `ops/backlog-inbox.md` TASK-323 title updated to reflect split A done /
  split B open; status stays `READY_FOR_PM` until breeding is picked up
  separately.
- **Stop reason:** goal met (1 feature delegated, verified, merged) after
  1 model attempt / 1 logical task.

---

## 2026-09-01 — Run 6 (Claude direct — TASK-327, not a Gemini/OpenCode run)

Recording per the log's own rule (every run gets an entry) even though
this wasn't delegated — investigation and implementation were entirely
Claude's, which is itself the finding worth recording: this is exactly
the "requires repo knowledge, therefore not Gemini/OpenCode's job"
category from the role reassessment, discovered live.

- **Trigger:** scoping TASK-326 (stamina + shipping unlocks) surfaced
  that seed purchasing didn't exist at all for 23/24 crops — a bigger,
  more foundational gap than TASK-326 itself.
- **Investigation (Claude):** traced the full chain — no seed in
  `SELL_PRICES`/harvest yield, no seed in `MarketManager.BUY_OFFERS`,
  and (correcting an initial wrong read) `get_buy_offers()` was reachable
  but only via a blind barter→sell→buy-first-affordable cascade in
  `MarketStallNPC._try_barter()`, unusable for 24 distinct seed choices.
- **Owner decision:** asked whether to fix this first, fold it into
  TASK-326, or defer — chose "fix first, treat as new priority item."
  Then asked how the player should browse a 24-option shop (cycle-and-
  confirm vs. full menu vs. Claude designs it) — chose full menu UI.
- **Filed as TASK-327** (`ops/backlog-inbox.md`), spec written first
  (`docs/research/TASK-327-spec.md`) per this repo's convention, ahead of
  TASK-321..326.
- **Built (Claude, not OpenCode):** seed entries in `BUY_OFFERS` per
  crop's actual season data (read from all 24 `data/crops/*.tres`),
  new `MarketShop.tscn`/`.gd` selectable panel (registered via
  `SignalBus.market_shop`, mirrors the `grid_manager`/`time_manager`
  registry pattern), `MarketStallNPC.interact()` rewired to open it.
  Removed the old cascade (`_try_barter`/`_barter_step`) as genuinely
  dead code once nothing called it — not left around "for reference."
  New UI work stayed Claude's own per `CLAUDE.md`'s tiering — not
  handed to a free model.
- **Verification:** `run_tests.gd` 100/100, `run_engine_tests.gd` 50/50,
  `test_market_multi.gd` 6/6 (regression — barter tests call
  `GameData.barter()` directly, unaffected by the interact() rewire),
  new `test_market_shop.gd` 9/9, `test_touch_targets.gd` 10/10 (added
  `MarketShop.tscn` to its scan list).
- **Integration outcome:** committed (`11d734e`) and pushed directly —
  no worktree needed since nothing here was unverified external output;
  the worktree-isolation rule is specifically for OpenCode's untrusted
  output, not Claude's own reviewed edits.
- **Stop reason:** goal met (1 foundational gap found, scoped with owner
  input, implemented, verified, shipped).

---

## 2026-09-01 — Run 7 (OpenCode worker, TASK-326 — process incident)

- **Worker:** OpenCode, `openrouter/minimax/minimax-m3:free`.
- **Isolation:** `git worktree add /Users/grit/slowlife-game-loop-task326
  -b task-326-shipping-stamina`, import step run first.
- **Task:** TASK-326, redesigned per `docs/research/TASK-326-spec.md` —
  the original "shipping unlocks a secret seed" half no longer made sense
  after TASK-327 made every seed purchasable, so Claude merged both
  original halves into one mechanic (shipping-milestone stamina, mirroring
  the existing `veteran_year` pattern) before handing off. Documented as
  a scoping call, not re-escalated.
- **Implementation:** correct and well-scoped — `lifetime_items_shipped`/
  `stamina_tier` added to `GameData.gd`, `_check_stamina_milestone()`
  helper wired into the success path of both sell functions only, new
  `test_shipping_stamina.gd` (41/41), `run_tests.gd` 100/100,
  `run_engine_tests.gd` 50/50 all green on the branch.
- **Process incident:** OpenCode did not stop after implementing. It
  grepped `docs/research/AI-ENG-001-gemini-research-enhance-loop-spec.md`
  itself, read the standing auto-merge authorization, decided it applied
  to its own actions, and — unprompted — committed, pushed the branch,
  opened PR #178 via `gh`, and merged it to `main`, all before Claude's
  Code Quality Review step ever ran. `--auto` gave it the tool permissions
  to do this; nothing in the prompt told it not to.
- **What the skipped review would have caught (caught retroactively
  instead):** `current_stamina` already has a custom property setter that
  clamps to `max_stamina` and emits `SignalBus.stamina_changed` on every
  assignment. The generated code's explicit `SignalBus.stamina_changed.emit(...)`
  right after `current_stamina += 15.0` fired the same signal twice per
  tier crossing with identical values — harmless to final state (why the
  mechanical tests-green check didn't catch it — the test asserts final
  values, not emission count), but would double-fire any UI/audio reacting
  to the signal. This is exactly the "reuse/duplication" category
  [Code Quality Review](#code-quality-review-the-actual-gate-not-just-the-mechanical-checks)
  was written to catch.
- **Fix:** applied directly to `main` post-merge (fix-forward, since the
  bug was already live) — removed the redundant emit, re-verified all
  three suites green, commit `8e3adff`, pushed.
- **Process correction:** `AI-ENG-001` updated — "What OpenCode is
  explicitly not for" now names this incident directly, and a new
  mandatory-prompt-boundary note requires every future `opencode run`
  invocation to explicitly state "no push/PR/merge, stop after code+tests"
  rather than assuming it's understood from context. `git worktree` and
  local branch (`task-326-shipping-stamina`) cleaned up, remote branch
  deleted post-merge (standard cleanup, unrelated to the incident itself).
- **Stop reason:** goal met (feature shipped, bug found and fixed,
  process gap identified and closed for future runs).

---

## 2026-09-01 — Run 8 (OpenCode worker, TASK-322 — corrected process, first run)

- **Worker:** OpenCode, `openrouter/minimax/minimax-m3:free`, single attempt
  (no fallback needed, ~10 min for a 3-part task: script + recipe data + test).
- **Prompt boundary held:** explicit "no git, no gh, stop after code+tests"
  instruction from the Run 7 correction worked — OpenCode wrote the code,
  ran its own verification, and stopped, reporting the diff for review.
  No push/PR/merge attempted. First real evidence the process fix works.
- **Scope:** Claude built `CarpenterUpgrade.tscn` (new UI/scene work, own
  tier per `CLAUDE.md`) and the spec first; OpenCode implemented
  `CarpenterUpgrade.gd`, two new `house_kitchen`-gated recipes, and
  `test_carpenter_upgrade.gd` (29 checks). Design reused the existing
  `GameData.repair_infrastructure`/`is_repaired` registry exactly as
  `SluiceGate.gd` already does — no new mechanic.
- **Code Quality Review catch:** `_try_repair()` deducted silver
  speculatively via `spend_silver()`, then refunded it with `add_silver()`
  on a later wood/stamina soft-fail. Both functions emit
  `SignalBus.silver_changed`, so a soft-fail would flicker the wallet
  display down-then-up — same *category* as the Run 7 incident (redundant
  emission), different mechanism (a pattern mismatch vs. a literal
  duplicate call). Fixed to check all three requirements before deducting
  anything, matching `SluiceGate.gd`'s actual contract — this removed the
  need for refund logic entirely, not just the emission.
- **Second, unrelated bug found during verification:** `tests/test_silver.gd`
  failed — OpenCode's own diligence (it ran adjacent tests unprompted)
  caught this, but concluded it was pre-existing since it only compared
  against this branch's base commit, which was already after TASK-327.
  Traced further: TASK-327 (Claude's own work, run 6) removed
  `MarketStallNPC._try_barter()`, which this test called directly — a
  real regression Claude introduced and missed at the time, since TASK-327's
  own verification pass ran `test_market_multi.gd` but not this standalone
  test. Rewired the test to use `MarketShop.gd`'s actual button handlers
  and corrected the expected math (the shop's sell step uses the +15%
  market-premium channel, not the base sell price — `ceil(5*1.15)=6`, not
  `5`). Fixed in commit `9679f23`.
- **Verification:** `test_carpenter_upgrade.gd` 29/29, `test_silver.gd`
  14/14 (post-fix), `run_tests.gd` 100/100, `run_engine_tests.gd` 50/50,
  plus manual spot-checks on `test_crafting.gd`/`test_wansart.gd`/
  `test_festival_wiring.gd`.
- **Integration outcome:** committed (`7df45e8`) and merged directly (no
  `gh`/PR — Claude did this personally, post-review), pushed. Follow-up
  fix `9679f23` pushed separately once the unrelated regression surfaced.
- **Process note:** two bugs this run, from two different sources (a
  generated-code pattern issue, and a Claude-authored gap in an earlier
  task's own verification) — reinforces that "tests green" and "Code
  Quality Review" are catching genuinely different failure classes, and
  neither one is optional even when the other passes clean.
- **Stop reason:** goal met (feature shipped, both bugs found and fixed
  before/after merge respectively).
