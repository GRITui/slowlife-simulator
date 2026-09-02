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

---

## 2026-09-01 — Run 9 (Cline capability calibration — local Ollama vs. Cline's own cloud tier)

- **Trigger:** project owner asked to test how much Cline + local Ollama
  (`qwen2.5-coder:3b`) could actually handle, and whether any task is
  worth giving it, before adding Cline to the pipeline as proposed.
- **Test:** identical scope/difficulty to Run 4's very first OpenCode
  trial (one dialogue line, one file, mirrors an existing pattern) —
  chosen specifically so results are directly comparable across workers.
  Task: update `WanSartTrigger.gd`'s offering dialogue to mention the
  temple monk (the unimplemented half of Run 2's cultural note).
- **`qwen2.5-coder:3b` via `cline -P ollama`:** 2 attempts, **0 real
  edits.** Both times it printed a JSON-looking blob as plain
  conversational text instead of invoking Cline's actual tool-call
  protocol — on the second attempt the "edit" it hallucinated wasn't
  even valid GDScript (a literal diff-style `-`/`+` line). This is a
  genuine tool-calling reliability failure at this model size, not a
  fluke — confirmed on retry.
- **`qwen3.5:9b` via `cline -P ollama`:** timed out completely (180s+)
  without finishing even one response. Too slow for practical agentic
  use on this hardware, independent of quality.
- **Control: `minimax/minimax-m3:free` via Cline's own `cline` provider**
  (not Ollama — a separate cloud account/quota from OpenCode's OpenRouter
  usage): worked perfectly on the first attempt. Real tool calls (read,
  edit, re-read to verify), a correct scoped one-line diff, no git
  commands run, and it self-verified before reporting done. This isolates
  the failure to the **local Ollama models specifically** — Cline's CLI
  harness itself is fine.
- **Verdict:**
  - **Local Ollama (this hardware, these models): not viable as a coding
    delegate right now.** `qwen2.5-coder:3b` fails to reliably format
    tool calls; the next size up (`qwen3.5:9b`) is too slow to finish.
    Zero quota risk doesn't matter if it can't produce a usable edit.
  - **Cline's own cloud tier (`minimax-m3:free` / `stealth/ox-alpha`) is
    a genuinely good addition** — a real, separate-quota fallback tier
    behind OpenCode's two providers, proven capable on a fair like-for-
    like test.
  - Recommend updating `AI-ENG-001`'s fallback chain to a 4-tier
    OpenCode chain unchanged, **then Cline (cloud) as tier 5**, and
    dropping local Ollama from the plan entirely rather than adding it
    as a last-resort tier — it isn't one; it just fails differently.
- **Integration outcome:** the calibration edit itself was correct and
  worth keeping (matches Gemini's original Run 2 note) — merged directly,
  `9e982d2`, pushed. `run_tests.gd` 100/100.
- **Stop reason:** goal met — capability question answered with real
  evidence, one incidental real fix shipped.

---

## 2026-09-01 — Run 10 (TASK-321, mid-task provider switch: OpenCode → Cline)

- **Scope:** Claude redesigned TASK-321 down from Gemini's original
  "multi-floor mines, ladder digging" concept (the single highest scope-
  creep risk item on the approved list) to mirror `FishingSpot.gd`'s
  existing pattern exactly — documented as a Designer-tier scoping call
  in `docs/research/TASK-321-spec.md`, not re-escalated.
- **Provider switch, mid-flight:** dispatched to `opencode-go/glm-5.3-flash`
  (the new top-ranked model per the same-day ranking update) first. After
  5+ minutes with zero tool-call activity in the log (vs. Cline/MiniMax
  typically showing activity within the first minute), the project owner
  asked to switch to Cline. Killed the OpenCode process (confirmed zero
  partial file changes — clean kill) and re-dispatched the identical
  prompt to `cline -P cline -m minimax/minimax-m3:free`.
  - **Process note for next time:** GLM-5.3-Flash's slowness here is one
    data point, not yet a verdict — Run 9's calibration didn't test it
    directly (that was local Ollama vs. Cline's cloud tier). Worth a
    controlled retry before demoting it in the ranking.
- **Cline's own run hit two issues**, both surfaced through Claude's
  Code Quality Review rather than blind trust of "it reported success":
  1. **Editing mistake**: a line-offset error while writing
     `test_mining.gd` left ~3 lines of duplicated/orphaned content
     (a stray `_check(...)` fragment mid-function and another after the
     function's closing brace) — would have been a GDScript parse error.
     Cline's own log showed it noticing and attempting self-repair.
  2. **Rate limit mid-repair**: the same OpenRouter
     `minimax/minimax-m3:free is temporarily rate-limited upstream` error
     seen in Run 7/8 hit while Cline was mid-self-repair, ending the
     session in `failed` status before the fix completed.
  - Claude fixed the corruption directly (removed the two orphaned
    fragments) rather than re-running the whole task — the rest of the
    diff (`GameData.gd`, `MiningSpot.gd`, `Main.gd`, `test_tool_tiers.gd`,
    `ore.json`) was clean on inspection, no reason to discard good work
    over one file's mechanical error.
- **Code Quality Review, substantive checks (beyond the corruption fix):**
  `GameData.upgrade_tool()`'s new ore requirement uses check-both-before-
  deduct-either — no repeat of TASK-322's speculative-deduct-then-refund
  bug class. `MiningSpot.gd` deducts stamina via the existing property
  setter (which already clamps + emits) rather than a redundant manual
  emit — no repeat of TASK-326's double-emission bug class either. Two
  bug classes now have a second clean instance each, suggesting the
  written-down categories in the Code Quality Review section are
  generalizing, not just describing one-off incidents.
- **Operational note on Cline's daemon architecture:** the foreground
  `cline` CLI process exits/detaches almost immediately; the actual work
  happens inside a persistent hub daemon (`cline hub`). `ps` won't show a
  task-specific process — use `cline history --json` (session status
  field) to poll instead. Also: `status` is a read-only variable name in
  zsh — don't use it as a shell variable in monitor scripts (broke the
  first monitor attempt this run).
- **Verification:** `test_mining.gd` 24/24, `test_tool_tiers.gd` 8/8,
  `run_tests.gd` 100/100, `run_engine_tests.gd` 50/50.
- **Integration outcome:** committed (`f1b9f87`) and merged directly,
  pushed. Worktree/branch cleaned up.
- **Stop reason:** goal met (feature shipped, one editing bug fixed
  directly, two established bug-class checks confirmed clean).

---

## 2026-09-01 — Run 11 (Sprint 1 of 3: TASK-323 split B, breeding)

- **Context:** project owner asked for the 3 remaining approved backlog
  items to be split into 3 sprints. Order set (smallest/best-understood
  first, most design-sensitive last): Sprint 1 = TASK-323 split B,
  Sprint 2 = TASK-325, Sprint 3 = TASK-324. Recorded in `SHIP_PLAN.md`
  and `ops/backlog-inbox.md`.
- **Scope:** Claude redesigned split B down from "spawn multiple physical
  animals" (would require refactoring `ChickenCoop`/`Buffalo` off their
  current hard-singleton pattern — real scope) to a capped herd-count
  variable that scales yield, grown automatically via the existing daily
  interact — mirroring the `fishing_skill`/`mining_skill` gradual-growth
  idiom rather than inventing a new mechanic. Documented in
  `docs/research/TASK-323B-spec.md`.
- **Dispatched to Cline** (`minimax/minimax-m3:free`) directly this
  time — skipped OpenCode entirely given Run 10's experience (Cline
  produced real activity within the first minute both times it's been
  tried this session; OpenCode/GLM-5.3-Flash showed zero activity after
  5+ minutes in Run 10).
- **Third hit on the same OpenRouter rate limit** (`minimax/minimax-m3:free
  is temporarily rate-limited upstream`) this session, after Run 7 and
  Run 10 — this is now a clearly recurring constraint on this specific
  free-tier model/provider pair, not a one-off. Session ended `failed`
  mid-task, but after cleanly completing 2 of 4 planned files.
- **Claude's response, given the pattern is now established:** rather
  than re-dispatch (risking a fourth rate-limit hit) or discard the good
  partial work, reviewed the 2 completed files (`GameData.gd`,
  `ChickenCoop.gd`) — both correct, matched the spec exactly, proper
  check-before-deduct ordering (no repeat of the TASK-322 bug class) —
  then completed the remaining 2 files directly: mirrored the reviewed
  `ChickenCoop.gd` pattern into `Buffalo.gd`, and wrote
  `tests/test_livestock_breeding.gd` from the spec's Acceptance Criteria.
  Also fixed a minor pluralization nit in Cline's dialogue text
  ("+2 egg" → "+2 eggs") while completing the file.
- **Verification:** `test_livestock_breeding.gd` 23/23 (new), all 4
  existing tests the spec flagged as touching the modified functions
  regression-checked clean (`test_chicken.gd` 7/7, `test_hearts_live.gd`
  9/9, `test_buffalo_hearts.gd` 5/5, `test_livestock_quality.gd` 16/16),
  `run_tests.gd` 100/100, `run_engine_tests.gd` 50/50.
- **Integration outcome:** committed (`9aa8f59`) and merged directly,
  pushed. Worktree/branch cleaned up.
- **Process note:** three rate-limit hits on the same model/provider pair
  in one session is worth weighing before Sprint 2/3 — either accept
  "Claude finishes what Cline starts" as the normal shape of a run now,
  or consider trying `stealth/ox-alpha`/GLM-5.3-Flash on Cline's own
  provider (different quota bucket, same CLI) as the default instead of
  `minimax-m3:free`, now that GLM-5.3-Flash is ranked #1 overall (even
  though its OpenCode-Go path was slow in Run 10 — that's a different
  provider/path than Cline's own).
- **Stop reason:** goal met (Sprint 1 shipped; 2 of 4 files delegated,
  2 of 4 completed directly after a clean handoff from a rate-limited
  session rather than a wasted retry).

---

## 2026-09-01 — Run 12 (Sprint 2 of 3: TASK-325, companion bond)

- **Scope:** investigation before any implementation found most of the
  original ask ("dog trained for racing, horse for transport/racing")
  already shipped under different animals — `BuffaloRace.gd` (TASK-270)
  and buffalo riding (TASK-272) already cover riding+racing; `CompanionNPC.gd`
  (TASK-048, a cat) already provides passive pet-following. Redesigned to
  the one real gap: the companion has no progression. Added a bond system
  mirroring `buffalo_affinity`/`buffalo_hearts` exactly, growing passively
  via `minute_ticked` while nearby, with a small bonus tie-in to the
  *existing* race rather than a duplicate one. Documented in
  `docs/research/TASK-325-spec.md`.
- **4th hit on the same OpenRouter rate limit this session** (runs
  7/10/11/12) — at this point it's a confirmed, routine characteristic of
  `minimax/minimax-m3:free` on the shared upstream pool today, not a
  fluke worth re-diagnosing each time. This occurrence was the cleanest
  yet: it hit right after all 4 files were written, mid a final
  self-verification read — no corruption this time (contrast Run 11's
  mid-repair corruption).
- **Code Quality Review, implementation files:** `GameData.gd`,
  `CompanionNPC.gd`, `BuffaloRace.gd` all clean — correct mirror of the
  `buffalo_affinity` pattern, correct guard ordering in
  `_companion_bonus_eligible()` (cheap tier check before the more
  expensive node-group scan), proper `_exit_tree()` signal disconnect
  (a convention this codebase uses but wasn't explicitly requested).
  One trivial fix: `_find_player()` was called twice per tick where once
  would do.
- **The new test file had two real, distinct authoring bugs** — this is
  a genuinely different failure shape than runs 10/11's rate-limit-mid-
  edit corruption, both caught by actually running the test rather than
  reading it and assuming correctness:
  1. Used the bare `SignalBus` global identifier, which doesn't resolve
     in a standalone `SceneTree`-extending test script — every other
     test in this repo goes through `root.get_node("SignalBus")` first;
     this one skipped that, causing a compile error on load.
  2. A tier-math error: expected `companion_bond_tier() == 1` after a
     single 60-tick nearby cycle, but 60 ticks only grants **+1 bond
     point**, and a tier needs 25 points (mirrors `buffalo_hearts()`'s
     `/25.0` math exactly, correctly implemented in the actual code —
     the test's *expectation* was wrong, not the implementation). Fixed
     by starting the tick sequence at bond=24 so it crosses the tier
     boundary in one cycle, testing the real integration path without
     1500 ticks.
  3. `BuffaloRace.force_finish()` (a documented test/debug helper) skips
     `start_race()`, so `_player` — which `_companion_bonus_eligible()`
     reads — was never set, silently making every bonus-path assertion
     pass or fail for the wrong reason. Fixed by setting `_player`
     directly via `race.set("_player", player)` before use.
- **Verification:** `test_companion_bond.gd` 33/33 (after fixes),
  `test_companion.gd` 7/7, `test_race.gd` 13/13 (both regression-checked
  per the spec), `run_tests.gd` 100/100, `run_engine_tests.gd` 50/50.
- **Integration outcome:** committed (`f5cb512`) and merged directly,
  pushed. Worktree/branch cleaned up.
- **Process note carried forward from Run 11:** still worth trying
  GLM-5.3-Flash via Cline's own provider (a different quota bucket than
  `minimax-m3:free`) as the default for Sprint 3, given the rate limit is
  now confirmed routine on this specific model/provider pair.
- **Stop reason:** goal met (Sprint 2 shipped; all 4 files delegated
  this time, 2 real test bugs found and fixed directly rather than
  re-dispatching).

---

## 2026-09-01 — Run 13 (Sprint 3 of 3: TASK-324 — Phase 2 closed)

- **Scope:** rivals + life progression, entirely reused the existing
  `RomanceNPC.gd`/`DialogueDB.gd`/`GameData.gd` marriage/anniversary
  system (TASK-282) — no new NPCs, no new scenes. Rivals implemented as
  flavor-only dialogue with zero mechanical effect (never blocks a
  proposal, never costs affinity), honoring the owner's note that rival
  pressure and no-fail-state aren't mutually exclusive. Life progression
  (pregnant → born → toddler) ties directly into the existing yearly
  anniversary interaction, with an explicit constraint carried through
  from the spec: never change the silver amount or add a second
  `festival_triggered` event, since `tests/test_anniversary.gd` asserts
  both exactly.
- **Two provider failures before real progress, a new failure shape
  each time:**
  1. `stealth/ox-alpha` (Cline's own hosted "early access" model, used
     successfully in Run 9's calibration) failed immediately: `Cline
     Credits balance is $-0.07` — insufficient balance, not a rate
     limit. The free-access period/credit apparently doesn't cover
     sustained use across a full session.
  2. `minimax/minimax-m3:free` (retry): spent an unusual ~5 minutes in
     pure reasoning/planning with **zero tool calls** — a different
     shape than any prior run (previous runs started editing within the
     first minute). Given no clean way to cancel a running Cline hub
     session was found, and zero edits had happened yet, Claude began
     implementing the same spec directly in parallel as a hedge.
- **A real, if low-stakes, concurrency incident:** once Cline actually
  started writing (after the long reasoning phase), it and Claude's
  parallel manual edit both touched `DialogueDB.gd` within moments of
  each other — Claude's edit landed first (niran's rival pool), Cline's
  landed second (fah's rival pool), non-colliding by luck. Cline then
  independently **noticed the pre-existing niran edit didn't match its
  own draft, reverted the whole file via `git checkout`, and redid both
  NPCs' rival pools itself consistently** — self-correcting the
  collision without being told about it. Claude stopped manual editing
  at that point rather than risk a second collision. This is worth
  remembering as a pattern: a `git worktree`'s isolation doesn't protect
  against two agents editing the *same file inside the same worktree* at
  the same time — the isolation is one worktree per *task*, not per
  *editor*. Running Claude and a delegate against the same file
  concurrently was an avoidable risk this run stumbled into rather than
  planned around.
- **The rate limit hit a 6th time this session**, mid the final
  `_talk()` edit in `RomanceNPC.gd` — but by then `DialogueDB.gd`,
  `GameData.gd`, and 2 of 3 `RomanceNPC.gd` changes were already
  complete and, on inspection, all 3 implementation files turned out to
  be fully done (the log's last visible line undersold the actual
  progress — always verify against the real diff, not just where the
  log output stopped).
- **Code Quality Review:** all 3 implementation files clean — correct
  guard ordering in the anniversary branch (silver/harmony(10)/event
  emission untouched, milestone logic strictly additive), correct
  `married_year` recording at proposal time mirroring the existing
  `tm.year()` lookup pattern, correct rival-pool substitution logic in
  `_talk()`. No repeat of any previously-catalogued bug class.
- **The test file was entirely Claude's** (Cline died before writing
  it) and needed two rounds of self-correction on the first pass: (1)
  tested "year 1 anniversary" in the same calendar year as the wedding
  itself, where `years_married = 0` — never satisfies the `>= 1`
  transition threshold, so the very first assertion failed; loose
  substring dialogue matching (`"harmony"`) coincidentally passed for
  the wrong reason since the standard line also contains that word,
  masking the real bug until the numeric assertion caught it; (2) the
  bypass-path test case reused year 1 a second time without accounting
  for `active_quests`' per-year keying, silently short-circuiting into
  the "already interacted this year" branch. Both fixed; tightened the
  dialogue assertions to match milestone-specific substrings instead of
  the generic word both paths share.
- **Verification:** `test_life_progression.gd` 26/26 (after fixes),
  `test_anniversary.gd` 6/6 and `test_wedding.gd` 6/6 (both regression-
  checked per the spec's explicit constraint), `run_tests.gd` 100/100,
  `run_engine_tests.gd` 50/50.
- **Integration outcome:** committed (`1cd8088`) and merged directly,
  pushed. Worktree/branch cleaned up.
- **Phase 2 closed.** All 6 approved backlog items (321, 322, 323 split
  A+B, 324, 325, 326) are complete. `docs/SHIP_PLAN.md` updated
  accordingly — see that file for what Phase 3 and the remaining launch
  gaps (monetization, analytics, the Apple `[HOLD]` items) look like.
- **Stop reason:** goal met — final sprint shipped, 3-sprint plan
  complete, Phase 2 closed.

## 2026-09-02 — Run 14 (Phase 3 polish: HUD progression gap, self-executed)

- **Worker:** Claude (Sonnet, self-executed — `.tscn`/UI is this repo's
  never-delegated tier per `CLAUDE.md`, not an AI-ENG-001 delegate task).
- **Trigger:** continuing "Keep digging" Phase 3 audit. Found that four
  progression stats had no HUD surface at all: `companion_bond`
  (TASK-325), `chicken_affinity`/`chicken_count` herd size (TASK-323),
  and `fishing_skill`/`mining_skill` (TASK-050/321). Confirmed with
  owner ("Add them now") before implementing.
- **Signal-parity gap found:** `buffalo_affinity_changed` and
  `chicken_affinity_changed` both exist on `SignalBus.gd`, but there was
  no equivalent for companion bond — `CompanionNPC.gd` only emitted
  `show_dialogue` on tier-up, giving the HUD no reactive hook at all.
  Added `companion_bond_changed(bond, tier)` mirroring the existing
  pair, emitted from `CompanionNPC._on_minute_ticked()` on every bond
  grant (not just tier-ups, matching how buffalo/chicken emit on every
  interact regardless of tier change).
- **No signal exists for fishing/mining skill level-ups either**
  (`FishingSpot.gd`/`MiningSpot.gd` only emit `show_dialogue`). Rather
  than add two more single-purpose signals for a stat that only needs
  to be eventually-consistent on a HUD label, piggybacked the refresh
  on HUD's existing `SignalBus.minute_ticked` connection instead.
- **HUD additions:** two new compact combined-stat labels under
  `Margin/Root/HBox/TimeBox` in `HUD.tscn`, matching the existing
  `HeartsLabel`/`ToolTierLabel` convention (one line per related-stat
  group, not one label per stat): `FarmHeartsLabel` ("Chicken: ♥♥ (30)
  x2 | Cat: ♥ (10)") and `SkillsLabel` ("Skills: Fish Lv2 | Mine Lv1").
  Added both to `_BASE_FONT_SIZES` so the existing accessibility
  font-scaling system covers them.
- **Verification:** new `tests/test_hud_progression.gd` (10/10) covers
  the new signal, both label init states, and live refresh on both the
  new signal and the piggybacked `minute_ticked` path. Full gate green:
  `run_gate.sh all` — engine+content 100/100, save-compat 35/35,
  perf-budget 6/6 (unaffected — no new sorted Node2D children). Spot-
  checked `test_hearts_live.gd` (9/9) and `test_fishing.gd` (16/16)
  unaffected by the new `SignalBus` connections in `HUD._ready()`.
- **Integration outcome:** self-executed, no delegate gate to pass —
  committed and pushed directly per the standing push-immediately rule.
- **Stop reason:** task complete; continuing Phase 3 digging next.

## 2026-09-02 — Run 15 (Phase 3 polish: quest duplicate-payout exploit, self-executed)

- **Worker:** Claude (Sonnet, self-executed — bug hunting, not a delegate task).
- **Trigger:** "Keep digging." Read `QuestLog.gd`/`GameData.gd`'s quest
  primitive end to end. `GameData.start_quest`/`complete_objective`/
  `is_quest_complete` never remove a quest from `active_quests` on
  completion — there is no claim/remove step anywhere in the codebase.
- **Bug found (economy-breaking, confirmed via manual repro before
  fixing):** `QuestLog.complete_objective_everywhere(objective_id)` loops
  every entry in `GameData.active_quests` and re-checks
  `is_quest_complete()` → `_payout()` on **every** matching event, with
  no guard against a quest that already paid out. Since completed quests
  stay in `active_quests` forever, any later unrelated action sharing an
  objective id (e.g. catching a second fish after the "first_catch"
  quest already completed and paid its reward) silently re-triggers
  `_payout()` again — unbounded, repeatable silver/harmony/item
  duplication for the lifetime of a save. Manually repro'd: two calls to
  `_check_objective_by_item("pla_nin_small")` after a quest completed on
  the first doubled `gd.harmony`.
- **Fix:** added an `is_quest_complete(quest_id)` skip at the top of the
  loop in `complete_objective_everywhere()`, and the same guard in the
  manual `complete_objective()` entry point — a completed quest is now
  permanently skipped rather than re-evaluated. Minimal, matches the
  session's established check-before-mutate pattern; no new state, no
  schema change (so no save-compat implication).
- **Verification:** new `tests/test_quest_no_dupe_payout.gd` (6/6) —
  confirms single payout on completion and zero further mutation on
  repeated same-objective triggers and on the manual entry point.
  Existing `test_quest_chain.gd` (27/27) and `test_questdata.gd` (8/8)
  unaffected. Full gate green: `run_gate.sh all` (content 100/100,
  engine 50/50, save-compat 35/35, perf 6/6, touch 10/10 — see below).
- **Process note:** also wired the pre-existing but orphaned
  `tests/ui/test_touch_targets.gd` (10/10, unrelated to this bug) into
  `scripts/ci/run_gate.sh`'s `all` target — it existed and passed but
  wasn't part of the standard gate, so a future UI regression there
  would have gone unnoticed.
- **Integration outcome:** self-executed, committed and pushed directly
  per the standing push-immediately rule.
- **Stop reason:** task complete; continuing Phase 3 digging next.

## 2026-09-02 — Run 16 (Gemini research: HM:BtN gap analysis v2 + 2 shipped fixes)

- **Role:** QA / Balance (Gemini), Claude for verification + implementation.
- **Question source:** User request — deep dive on gameplay depth, content
  range, and NPC engagement/social balance vs HM:BtN, explicitly "do not
  defer if that can help us, but may label as non P0/P1... to do later."
- **Process note:** Gemini (3.6 Thinking, via claude-in-chrome) stalled
  twice before producing a real answer — one silent "you stopped this
  response" on the first submit, then a ~90s stuck "thinking" state on
  the retry with no visible progress. Closed the tab and started a fresh
  chat with a shorter single-line prompt (no embedded newlines, which may
  have been what confused the multiline input box) — that one completed
  normally. Documented here since it cost real wall-clock time; worth
  trying a fresh chat early if a Thinking-model response looks stuck
  rather than repeatedly waiting on the same one.
- **Answer summary:** Gemini returned 9 mechanics across the 3
  dimensions, each tagged impact/effort.
- **Verification performed (per the loop's integrate-don't-trust-blindly
  rule):** cross-checked every claim against actual code (`rg` over
  `scripts/`, `scenes/`, `data/`) before proposing or acting on anything.
- **Findings:**
  - Already implemented, Gemini was WRONG: (1) monsoon-season auto-water
    + hot-season wilt tracking already exist in `GridManager.gd`'s
    `_on_minute_ticked()` — Gemini's "Monsoonal Hydrology" pitch was a
    real mechanic already shipped. (2) Gift-giving with per-NPC
    preference tiers (loved/liked/neutral) already exists
    (`DialogueDB.gd` `GIFT_PREFERENCES`, `gift_tier()`/`gift_affinity()`)
    — but checking this surfaced a REAL gap Gemini never asked about:
    the preference table already listed `elder`/`child`/`handler`/
    `trader`, yet only `RomanceNPC.gd` (the 2 marriage candidates) ever
    called the gifting mechanic. Villagers had the data but no path to
    it.
  - **Shipped immediately (not deferred, per the user's instruction):**
    (a) Extended gift-giving to `VillagerNPC.gd` for elder/child/
    handler/headman/vet (trader stays transactional, no gifting) —
    mirrors `RomanceNPC._give_gift()` exactly, reusing the existing
    preference data with zero new content authored. (b) While verifying
    this end-to-end, found a real pre-existing bug shared by BOTH NPC
    scripts: quest talk-tracking (`_try_offer_quest`/
    `_try_complete_talk_objective`) only ran inside each script's
    dialogue-fallback branch — any earlier early-return (the gift branch
    especially, which fires on ANY interact while holding food, a state
    that's near-universal in a farming sim) silently skipped
    `talk_to_<npc_id>` quest objectives for that click. This predates
    today's gift extension (RomanceNPC.gd had the identical structure
    already) — fixed in both files by moving quest talk-tracking to run
    unconditionally at the top of `talk()`/`try_interact()`, before any
    branch. Verified with a new regression test proving a quest
    completes even while the same interact also fires a gift.
  - Confirmed real gaps, filed `NEEDS_OWNER_REVIEW` with priority labels
    per the user's sequencing instruction: TASK-328 (weather-reactive
    NPC schedules, P1 — infra exists via `ScheduleDB.gd`, low effort),
    TASK-329 (weather-aware dialogue branch, P1 — same low-effort
    pattern as the existing season branch), TASK-330 (festival density,
    P2 — only 4 exist across a 90-day year), TASK-331 (milestone
    collectibles beyond the single shipping-axis TASK-326 gave us, P2),
    TASK-332 (repeatable side-quest noticeboard, P2 — zero repeatable
    quest content exists today), TASK-333 (affinity decay, P3 —
    explicitly flagged as a no-fail-state design-philosophy conflict,
    same category as TASK-324's rival decision; do not implement without
    an owner call), TASK-334 (tool AoE/charge tiers, P3 — real depth gap
    but touches the foundational 1:1-tile interaction model, needs its
    own design pass).
  - Deliberately not filed as a new task: TASK-333's decay mechanic
    could also apply to the newly-extended villager gifting relationship
    — noted in the ticket rather than silently assumed either way.
- **Verification:** `tests/test_gift_prefs.gd` extended 8→11 checks
  (villager gifting end-to-end). New
  `tests/test_talk_objective_not_skipped_by_gift.gd` (6/6) locks in the
  quest-skip fix for both NPC scripts. Full gate green: `run_gate.sh
  all` (content 100/100, engine 50/50, save-compat 35/35, perf 6/6,
  touch 10/10). Regression-checked `test_quest_chain.gd` (27/27),
  `test_anniversary.gd` (6/6), `test_wedding.gd` (6/6) — the anniversary/
  wedding silver-and-event-count constraints from TASK-324 were not
  touched by either fix.
- **Integration outcome:** the two fixes (villager gifting extension,
  quest-talk-skip guard) self-executed and committed/pushed directly —
  small, low-risk, purely additive/corrective changes, not a scope
  decision. The 7 filed tasks are `NEEDS_OWNER_REVIEW` per the existing
  MVP-vs-stretch precedent (`SHIP_PLAN.md` Phase 1) — priority labels
  are a sequencing recommendation, not a scope decision made on the
  owner's behalf.
- **Stop reason:** goal met (research delivered, verified, 2 items
  shipped, rest triaged and filed with priority labels per instruction).

## 2026-09-02 — Run 17 (3-sprint backlog clearance, Sprints 1-2)

- **Trigger:** "run 3 sprints autonomously to complete all of pending
  backlogs" (TASK-328..334). Clarified TASK-333 (affinity decay) first —
  it was explicitly filed as needing an owner call for a design-
  philosophy conflict, and a blanket "do all" instruction doesn't
  obviously cover that. Owner chose to skip it; 6 items (328/329/330/
  331/332/334) proceeded across 3 sprints.
- **Sprint 1 — TASK-328 (weather-reactive NPC schedules) + TASK-329
  (weather-aware dialogue):** self-executed (dialogue voice/quality
  benefits from direct authorship for a task this size — narrative
  flavor text is not a great fit for blind delegation). `ScheduleDB.gd`
  gained a `weather` param + `RAIN_HOME` override (elder/child route
  home in rain — the only two NPCs with an existing "home" schedule
  slot, not inventing new positions for the rest). `DialogueDB.
  get_seasonal_line()` gained a weather branch (~40% flavor chance)
  ahead of the season fallback. `tests/test_schedules.gd` 3→12 checks,
  new `tests/test_weather_dialogue.gd` 5/5. Gate green. Merged
  (`ada73e3`), pushed.
- **Sprint 2 — TASK-330 (monsoon festival density) + TASK-332
  (noticeboard):** delegated to OpenCode (`openrouter/z-ai/glm-5.3-flash`)
  from written specs, in two SEPARATE worktrees run in parallel — a
  deliberate fix from this session's earlier worktree-concurrency
  lesson (run 13): two delegates must never share a worktree, even
  briefly. (First launch attempt actually failed silently — `timeout`
  isn't installed on this machine, so both `opencode run` invocations
  no-op'd instantly; caught before any real concurrent-worktree risk
  materialized, redone without `timeout` in isolated worktrees.)
  - TASK-330: both new triggers (`AsalhaBuchaTrigger.gd`,
    `OkPhansaTrigger.gd`) mirror `SongkranTrigger.gd`'s exact shape,
    flavor-only per spec (no new items/economy). Code Quality Review:
    clean, matches spec verbatim. `tests/test_new_monsoon_festivals.gd`
    13/13. Gate green. Merged (`7c7f637`), pushed.
  - TASK-332: `Noticeboard.gd` mirrors `MiningSpot.gd`'s programmatic-
    Area2D pattern exactly; check-before-deduct fulfill (verified via a
    `silver_changed` emission-count assertion, not just trusting the
    code); V1 deliberately does not persist across save/load (save-
    format changes are always-escalate, not bundled here). Code Quality
    Review: clean. `tests/test_noticeboard.gd` 24/24 — the delegate also
    correctly caught and fixed a knock-on: the Y-sort perf budget test
    needed `Noticeboard` added to its no-sprite exclusion list (same
    treatment as `MiningSpot`), which it did without being told to.
    Gate green. Merged (`5e155b6`), pushed — Main.gd auto-merged cleanly
    against Sprint 2's other branch (both were pure independent
    additions to `_ready()`), re-verified full gate on `main` post-merge
    anyway rather than trusting the auto-merge.
- **Scope correction found while writing Sprint 3's spec (before
  delegating):** the original TASK-334 ticket ("tool tier AoE/charge
  mechanic") assumed no multi-tile interaction existed at all. Code
  audit found `Player.gd` already has a working mounted 3x3 mechanic
  (`_mounted_plant_3x3()`, TASK-272) — it only handles planting. Real
  gap: extending it to water/harvest too, not building a new touch-
  charge gesture system. Rescoped `docs/research/TASK-334-spec.md`
  accordingly before this went to a delegate — same "audit before
  trusting the ticket's own framing" discipline applied to every prior
  research-sourced task this session.
- **Sprint 3 — TASK-331 (milestone collectibles) + TASK-334 (mounted
  3x3 water/harvest):** both delegates hit provider exhaustion before
  landing — `openrouter/z-ai/glm-5.3-flash` returned an insufficient-
  credits error on the very first call for both tasks (not a rate
  limit — an actual balance issue), `openrouter/z-ai/glm-5.2:free` was
  rate-limited upstream immediately after, and `opencode/glm-5.2`
  (native, non-openrouter) returned its own insufficient-balance error.
  Fell to `openrouter/minimax/minimax-m3:free` (established fallback
  tier) for both — this time clean, no rate-limit hit mid-task unlike
  several earlier runs this session.
  - TASK-331: `GameData.earn_milestone()` + `milestones_earned` dict
    (idempotent, +10 harmony), 5 trigger sites (deep_miner,
    master_angler, inseparable, herd_keeper x2 call sites,
    storm_catch), correctly gated inside each site's own skill-up/tier-
    up transition block. Did not touch `SaveManager.gd`, per spec. Code
    Quality Review: clean, matches spec. `tests/test_milestones.gd`
    38/38. Gate green. Merged (`136b04e`), pushed.
  - TASK-334: `_mounted_plant_3x3()` generalized to
    `_mounted_interact_3x3()`, mirroring `_try_grid_interact()`'s
    unmounted branch logic per-cell (null→plant, ready→harvest,
    else→water), one summary dialogue line omitting zero-count
    categories. Unmounted branch confirmed byte-for-byte unchanged.
    Code Quality Review: clean, matches spec. `tests/test_riding.gd`'s
    one call-site rename verified correct; new
    `tests/test_mounted_interact_3x3.gd` 62/62 (mix-state grid,
    all-empty regression, unmounted no-spill). Gate green. Merged
    (`31f10d4`), pushed.
- **3-sprint run complete.** All 6 approved items (328/329/330/331/332/
  334) shipped 2026-09-02. TASK-333 (affinity decay) remains filed,
  unimplemented, pending an explicit owner decision on the no-fail-
  state design-philosophy question — not silently dropped, not
  defaulted to yes.
- **Process note carried forward:** the provider fallback chain held up
  exactly as designed across two independent tasks hitting exhaustion
  simultaneously — worth keeping the chain (glm-5.3-flash →
  glm-5.2:free → opencode/glm-5.2 → minimax-m3:free → ...) as the
  default retry order rather than re-deriving it per incident.
- **Stop reason:** goal met — all 6 non-deferred items from the
  research pass are shipped, tested, reviewed, merged, and pushed.

## 2026-09-02 — Run 18 (TASK-333 resolved: decay -> weekly streak bonus)

- **Trigger:** user asked to bring TASK-333 back for discussion. Laid
  out the actual decision (not a default-yes): the no-fail-state
  precedent (`TASK-319`, reaffirmed for `TASK-324`'s rivals), why a
  decreasing-only value is punish-adjacent, and 3 concrete options —
  skip it, implement decay anyway, or a non-punishing alternative
  (streak bonus instead of decay). Owner picked the non-punishing
  alternative.
- **Design:** `GameData.record_weekly_engagement(npc_id, day)` — reuses
  `_get_specialty_week()`'s existing week concept (day/7). Consecutive
  weeks interacting with an NPC grant a small bonus (+1 affinity per
  streak week beyond the first, capped at +5); missing a week resets
  the streak to restart but never reduces affinity already earned.
  Wired unconditionally into both `VillagerNPC.talk()` and
  `RomanceNPC.try_interact()` (excluding the transactional trader),
  right alongside the existing unconditional quest-talk-tracking calls
  from run 16's fix.
- **UX bug caught before it shipped:** first draft emitted a dedicated
  `SignalBus.show_dialogue` line announcing the bonus. Checked
  `Main._on_show_dialogue()` first (per this session's now-standard
  "verify, don't assume" discipline) and found it has no queue —
  `dialogue_label.text` is overwritten directly, so a bonus line
  emitted before the branch's own dialogue would be instantly
  overwritten and never actually seen. Removed the dedicated line;
  bonus is granted silently (matches how buffalo/chicken hearts are
  discovered too — via HUD, not a toast).
  Also caught the same class of test-authoring mistake as run 16's
  gift work: the end-to-end tests initially compared affinity deltas
  across two `talk()` calls without clearing the seeded starting
  inventory, so the auto-gift mechanic's own affinity gain (any
  `FOOD_ITEMS` held) would have been counted as part of the "weekly
  bonus" delta. Fixed by clearing inventory before each call, isolating
  the streak effect being tested.
- **Verification:** new `tests/test_weekly_engagement.gd` (18/18) —
  direct streak-math unit checks (first interaction, same-week repeat,
  consecutive-week growth to the +5 cap, missed-week reset,
  independent per-npc state) plus end-to-end through both NPC scripts.
  Full gate green: `run_gate.sh all` (content 100/100, engine 50/50,
  save-compat 35/35, perf 6/6, touch 10/10). Regression-checked
  `test_gift_prefs.gd` (11/11), `test_quest_chain.gd` (27/27),
  `test_talk_objective_not_skipped_by_gift.gd` (6/6),
  `test_anniversary.gd` (6/6), `test_wedding.gd` (6/6) — none affected.
- **Integration outcome:** self-executed (small, narrative/balance-
  sensitive, same category as run 17's Sprint 1). TASK-333 flipped to
  `COMPLETED` in `ops/backlog-inbox.md`; GitHub issue #184 closed.
- **Stop reason:** goal met — the one remaining filed item from the
  Gemini research pass is resolved.

## 2026-09-02 — Run 19 (broaden-to-compete plan, Sprint 1: cast & stakes)

- **Trigger:** asked for a real quality/stickiness verdict vs HM:BtN.
  Gave a candid, evidence-based one (verified via grep, not vibes):
  2 romance candidates vs HM:BtN's 5, ~9 named NPCs vs ~20-30, single
  static 20x16 map with no expansion, zero scored competitions anywhere
  (confirmed via a repo-wide grep for score/placement/leaderboard —
  BuffaloRace is a solo time-trial, Fishing Competition was pure
  flavor), and — the single highest-leverage gap — no human has ever
  played this game end-to-end. User asked for a draft sprint plan to
  close the gap; approved running all 3 sprints, gave creative freedom
  on the new romance candidate concept.
- **TASK-335 (third romance candidate, self-executed):** designed
  Ploy — a warm, sociable market dessert-maker, deliberately filling
  the personality gap Niran (competitive) and Fah (introspective)
  leave open, and tying the underused 36-recipe cooking system into
  romance content for the first time via her specialty-sell channel.
  `RomanceNPC.gd`/`DialogueDB.gd`'s tier system and
  `GIFT_PREFERENCES` are already generic per npc_id — this was mostly
  content, not engineering. Two things caught before shipping: (1) her
  first specialty-item list (khanom_krok, sangkhaya) had no
  `GameData.SELL_PRICES` entry — a real, separate, pre-existing gap
  found by the test failing, not by inspection; swapped to
  banana_rice_cake/pandan_sticky_rice which are actually sellable.
  (2) her `Sprite2D` pushed the Y-sort perf budget from 49→50 — raised
  the cap, exact same treatment as every prior legitimate-sprite
  addition this session. Portrait is a documented placeholder (hue-
  shifted from Fah's sprite, not original art). `tests/test_peer_npcs.gd`
  11→20 checks. Merged `6ed128e`, pushed.
- **TASK-336 (scored Fishing Competition, delegated to OpenCode
  `minimax-m3:free` directly — skipped the top-tier retry ladder this
  time since the pattern of exhaustion/rate-limiting across all 3
  higher tiers was already established twice in run 17):** extended
  the existing flavor-only trigger into the game's first real
  competitive mini-game — fish caught during the window score points,
  a rival score is rolled at window close, placement (1st/tie/
  participation) grants a strictly-positive reward every time, no fail
  state. Delegate extracted `_placement_for()` as a pure function
  specifically so the tie tier (not forceable via `randi_range`) could
  still be tested deterministically — good judgment call not spelled
  out verbatim in the spec. Code Quality Review: clean, one trailing-
  newline nit fixed. `tests/test_fishing_competition_scoring.gd`
  26/26. Merged `6606a1f`, pushed.
- **Sprint 2 (TASK-337 secondary area, TASK-338 more NPCs) queued
  next.**
- **Stop reason:** Sprint 1 of 3 complete, both items shipped, gate
  green, continuing to Sprint 2.

## 2026-09-02 — Run 19 continued (Sprint 2: world breadth)

- **User said "go carefully."** Spent extra verification time up front
  before writing either spec — paid off twice.
- **TASK-338 (grow the NPC roster, self-executed) design work
  surfaced a real bug before any new code was written:** while
  confirming exactly how Elder/Child/Handler are declared (they're 3
  instances of one shared `VillagerNPC.tscn`, not separate files —
  verified by reading `Main.tscn` directly rather than assuming),
  found `VillagerNPC.gd`'s headless-safe idle-texture fallback had
  cases for elder/child/handler but NONE for headman/vet — despite
  both having dedicated portrait assets (`headman_idle_01.png`,
  `vet_idle_01.png`) sitting unused since whenever they were added.
  Both silently rendered as Elder. Fixed immediately as its own commit
  (`d876154`), with a new `tests/test_villager_portraits.gd` (15/15) —
  the first test in this project to check portrait textures at all,
  since it's exactly the class of purely-visual bug headless testing
  otherwise can't catch (ties directly back to the verdict's "nobody
  has played this" finding).
- **TASK-338 itself:** added Nok, a veteran-farmer villager, using the
  now-verified simple pattern (static `VillagerNPC.tscn` instance +
  explicit `idle_texture` override, no new `.tscn`, no new `Main.gd`
  function). Caught one more issue in my own first draft before
  shipping: her loved-gift list included `"ginger"`, which isn't in
  `GameData.FOOD_ITEMS` (the auto-gift picker's source list) — would
  never have been reachable. Swapped for `thai_basil`. Extended
  weather-reactive scheduling (TASK-328) to a 3rd NPC via the existing
  `RAIN_HOME` mechanism, for free. Y-sort budget 50→51 (same
  documented pattern, now a running commit-log of its own). Merged
  `480b790`, pushed.
- **TASK-337 (secondary unlockable area, delegated to OpenCode
  `minimax-m3:free`):** designed carefully to route around the actual
  risk flagged in the original plan — no grid/map expansion at all.
  Verified the unlock condition (`mining_skill >= 3`) is already
  persisted, so the spot's existence is derived live every check
  rather than stored as a new flag, sidestepping a `SaveManager.gd`
  schema bump entirely (always-escalate category, would otherwise have
  needed separate human review). Verified rarity-weight math and the
  exact ore-roster reuse before writing the spec, so the delegate had
  zero design decisions left to make, only implementation. Delegate
  made two good judgment calls not spelled out verbatim in the spec:
  didn't inflate the perf budget for a spot with no sprite (correctly
  added it to the exclusion list instead, matching precedent), and
  used a seeded RNG in the statistical rarity-inversion test to avoid
  flakiness. Code Quality Review: clean, matches spec exactly,
  correctly avoided duplicating the `deep_miner` milestone trigger.
  `tests/test_mountain_cave.gd` 16/16. Merged `73c3c3e`, pushed.
- **Sprint 2 closed.** Both items shipped, one real pre-existing bug
  found and fixed as a bonus, gate green throughout
  (content 100/100, engine 50/50, save-compat 35/35, perf 6/6, touch
  10/10).
- **Stop reason:** Sprint 2 of 3 complete, checking in before Sprint 3
  (second scored mini-game).

## 2026-09-02 — Run 19 concluded (Sprint 3: second scored mini-game)

- **TASK-339 (Songkran Cooking Contest, delegated to OpenCode
  `minimax-m3:free`):** rather than add a whole new festival day for a
  cooking contest (which would have undone TASK-330's careful 2-per-
  season balancing), extended `SongkranTrigger.gd` in place to reuse
  its existing hot-day-3, 12:00-18:00 window — the same move TASK-336
  made on the fishing trigger. Ties the 36-recipe cooking system (the
  game's most content-rich, most underused system per the original
  verdict) into a competitive loop for the first time.
- **Real risk identified and specced around before delegating:**
  `SignalBus.craft_completed` is shared across `CookingStation`,
  `FishingSpot`, and `MiningSpot` — a naive scoring handler would have
  double-counted fish/ore catches as "cooking." Spec explicitly
  required a `recipes.json` membership check instead of a prefix match
  (recipes have no consistent id prefix, unlike fish's `_small/_mid/_big`
  suffix), and required a test proving fish/ore/typo item_ids do NOT
  score. Delegate's diff and test suite both did this correctly on the
  first pass — no fix-forward needed here, unlike Sprint 1's fishing
  contest which needed a trailing-newline nit fixed.
- Code Quality Review: clean, mirrors `FishingCompetitionTrigger.gd`'s
  proven shape exactly including the `_placement_for()` pure-function
  extraction for deterministic tie testing.
  `tests/test_songkran_cooking_contest.gd` 32/32. Merged `3fc026b`,
  pushed. Independently re-verified full gate on `main` post-merge.
- **"Broaden to compete with HM:BtN" plan closed.** All 6 items shipped
  (TASK-335..339 plus the bonus headman/vet portrait fix) across 3
  sprints. Two new romance candidates' worth of social depth (well,
  one — Ploy — plus the weekly-engagement system from the prior run),
  two scored competitive loops where zero existed before, one gated
  secondary area, one new villager, and one real pre-existing visual
  bug fixed along the way. Gate green throughout every single merge
  (content 100/100, engine 50/50, save-compat 35/35, perf 6/6, touch
  10/10) — never merged on a red or unreviewed diff.
- **What's still not addressed, unchanged from the original verdict:**
  no human has played any of this end-to-end. Still the single
  highest-leverage gap, and no amount of further content generation
  substitutes for it.
- **Stop reason:** goal met — all 3 sprints complete, plan closed.

## 2026-09-02 — Run 20 (6 romance + 6 rivals + 5 areas, Sprint 1)

- **Trigger:** user requested scaling to 6 romance candidates, 6
  romance rivals, and 5 unlockable areas. Given the rival concept's
  direct conflict with the no-fail-state precedent this session has
  held (and reaffirmed) throughout, surfaced the actual design fork via
  AskUserQuestion before drafting anything: flavor-only rivals (matches
  precedent) vs soft competition vs real stakes where a rival can
  permanently win a candidate. Owner explicitly chose real stakes, and
  physical (not narrative-only) rival NPCs — a deliberate, informed
  reversal of the precedent, not an accidental one. Designed the
  mechanic to be as fair as a real-stakes system can be: 90-day window
  from FIRST MEETING (not game start), 3 telegraphed warnings, and a
  soft landing (lost candidate just becomes a permanent friendly NPC,
  no other consequence). User asked to see all 5 sprints' specs before
  any code — wrote and verified all 5
  (`docs/research/TASK-340..344-spec.md`) against the actual codebase
  first (map positions via headless `ground_at()` probes, gift/
  specialty items against `FOOD_ITEMS`/`SELL_PRICES`, confirmed the
  lotus maze interior is unwalkable `deep_pond` so area 4 goes at its
  edge instead, confirmed `get_sell_price()`/`cheapest_sellable()`
  already support the pattern area 5 needs).
- **TASK-340 (save schema + RivalClock mechanism), self-executed given
  the stakes:** `SaveManager` v3→v4 adds `npc_first_met_day`/
  `lost_to_rival`/`rival_warning_shown`, and — since a schema bump was
  already in progress — closed a second, unrelated, already-known gap
  in the same pass: TASK-331's `milestones_earned` was deliberately
  never persisted at the time (that task's spec explicitly deferred
  it); persisting it now cost nothing extra given the migration was
  already happening. `RivalClock.gd` ships with an empty `PAIRS` table
  — pure mechanism, zero content, so the schema and daily-check logic
  are proven correct in total isolation before TASK-341/342 add any
  candidates or rivals to depend on it.
- **Real bug caught by my own test, not by inspection:** the v3→v4
  migration block was accidentally nested one indentation level too
  deep — inside the `if version < 3:` body instead of as its sibling —
  so it silently never executed for a payload that started exactly at
  v3 (the single most common real-world case: every existing save).
  Only `test_save_compat.gd`'s "migrate advances v3 payload to version
  4" assertion caught it; visual inspection of the diff had missed it.
  Fixed and reverified.
- **Verification:** `run_gate.sh all` green (content 100/100, engine
  50/50, save-compat 46/46, perf 6/6, touch 10/10). New
  `tests/test_rival_clock.gd` (17/17) exercises the full 90-day/3-
  warning/loss timeline including the "clears forever once affinity
  hits 25" and "married spouse never at risk" edge cases.
  `tests/test_peer_npcs.gd` extended to 25/25 covering the
  `_check_proposal()` hard lock. `test_anniversary.gd`/`test_wedding.gd`
  unaffected. Merged `6549931`, pushed.
- **Stop reason:** Sprint 1 of 5 (the highest-risk one) complete,
  checking in before Sprint 2 (3 new romance candidates).

## 2026-09-02 — Run 20 continued (discoverability gap found, filed not fixed)

- **User asked whether the 6 rivals need backstory/dialogue hinting
  they're rivals at all.** Answering that surfaced a real fairness gap
  in the design as specced: the candidate's own "rival" flavor tier
  only shows at close tier (affinity >= 60), but the loss condition
  fires when affinity NEVER reaches 25 — the player actually at risk
  would never see it. TASK-342's rival tier-0 dialogue was also
  written deliberately soft, revealing nothing. As specced, a
  disengaged player could lose a candidate with zero warning ever
  surfaced, contradicting the fairness goal the mechanic was designed
  around in TASK-340.
- Per explicit owner instruction, filed as TASK-345 rather than
  editing the pending TASK-341/342 specs immediately — proposed fix
  (rival tier-0 reveals the competing interest immediately; add a
  distinct candidate-stranger-tier line gated on
  `rival_warning_shown >= 1`) is documented in the backlog entry for
  whoever builds Sprint 2/3 to apply.
- **Second question: could the rival and candidate's own relationship
  visibly develop over the 90 days, not just flip at the deadline?**
  Assessed as feasible and valuable with near-zero added mechanical
  risk — `rival_warning_shown` (0-3, already tracked) is already a
  reasonable proxy for "how far along" and can be reused purely as
  richer dialogue content (both the rival's own tone and, once
  TASK-345 lands, the candidate's own dialogue) rather than needing a
  new persisted stat. A deeper version (a real `rival_affection` value
  with reciprocal effects from player action) was flagged as a
  separate, larger scope decision, not bundled into the current plan.
- No code changed this entry — pure design discussion + backlog filing.

## 2026-09-02 — Run 21 (10-level system, phase 1: shared scale + romance retrofit)

- Owner escalation this run bundled several asks at once (festival
  win/loss nudging rival progress, romance switching to a 10-level
  scale applied to animals/villagers too, and a rival-friendship ->
  confession -> dilemma quest system) — resolved into 8 sequenced specs
  (TASK-346..349 for the level system + schema, TASK-341/342 already
  in flight for the new cast, TASK-343/344 for the remaining
  unlockable areas). Full specs written and reviewed with the owner
  before any code changed, per explicit request.
- **Sequencing question** (build the new mini-game/quest content now
  vs. after the 8 already-specced sprints) was routed to Gemini for a
  second opinion per explicit owner instruction, rather than decided
  directly. Gemini recommended Option B — ship the 8 specced sprints
  first, treat the 1 new mini-game + 3 rival quest chains as a
  fast-follow spec-and-build pass after. Owner said proceed on that
  basis; the mini-game/quest work is deferred, not dropped.
- **TASK-346 built this run** (self-executed — narrative content):
  `GameData.level_for(value) = clampi(value/10, 0, 10)` added as the
  one shared derived scale (no schema change, affinity stays 0-100).
  Niran/Fah/Ploy's dialogue retrofitted from the old 4-tier
  (stranger/friendly/close/romantic, 8 lines each) to 10 numbered
  pools (20 lines each) — the original 8 lines per candidate kept as
  anchors, redistributed to their nearest new level, with new lines
  filling the expanded resolution. `RomanceNPC._talk()` now selects by
  level instead of the removed `DialogueDB.get_affinity_tier()`; the
  TASK-324 rival-flavor override now fires on levels 6-8 (the
  level-equivalent of the old "close" tier). `_check_proposal()`'s
  affinity>=90 gate is unchanged. Level-0 fallback (affinity < 10)
  falls back to level 1's pool.
- **Verification:** `run_gate.sh all` green (content 100/100, engine
  50/50, save-compat 46/46, perf 6/6, touch 10/10).
  `tests/test_affinity.gd` rewritten from tier-string checks to
  `level_for()` boundary checks + per-level dialogue-pool existence
  checks (43/43). `tests/test_peer_npcs.gd` (25/25),
  `test_anniversary.gd` (6/6), `test_wedding.gd` (6/6) regression-
  checked green, unaffected — none hardcode dialogue-pool key strings.
  Merged `c70f90a`, pushed.
- **Stop reason:** TASK-346 (phase 1 of the level system, and a
  dependency for TASK-341/347/348/349) complete. TASK-341 (3 new
  candidates, 10-level from the start) is next in sequence.

## 2026-09-02 — Run 22 (Sprint 2: Kiet, Malee, Kanya — 6 romance candidates)

- **TASK-341 built this run** (self-executed — narrative content):
  3 new romance candidates bringing the total to 6 — Kiet (apprentice
  woodcarver), Malee (festival drummer), Kanya (herbalist). Each got a
  full `DialogueDB` entry authored directly in TASK-346's 10-level
  shape (20 level lines + "1_warned" + "rival"), a `GIFT_PREFERENCES`
  entry (all loved/liked items re-verified against `FOOD_ITEMS` before
  writing — the auto-gift-picker mistake that shipped 3 times earlier
  this session did not recur), a `RomanceNPC._try_specialty_sell()`
  branch, a placeholder portrait (hue-shifted from an existing
  sprite), and `.tscn` + `Main.gd` wiring mirroring the existing 3.
- **TASK-345's fix folded in for all 6 candidates**, not just the 3
  new ones: `RomanceNPC._talk()` now checks a `"1_warned"` dialogue
  pool at level 1 once `GameData.rival_warning_shown >= 1` — retrofit
  onto Niran/Fah/Ploy in the same pass so it isn't a second edit to
  this file later. TASK-345 marked RESOLVED (half of it — the rival
  NPC's own tier-0 dialogue is still TASK-342's to do).
- **Real bug caught while writing the test, not by inspection**: the
  `"1_warned"` end-to-end test used a lambda (`func(_w, l): last_line
  = l`) as a signal-spy callback — GDScript lambdas capture local vars
  by value, so the assignment silently updated a shadow copy and the
  outer `last_line` never changed, making every assertion read an
  empty string. Fixed by using a class-member field + a bound method
  instead of a lambda closure. Worth remembering: this is a real
  GDScript gotcha, not specific to this test.
- **Verification:** `run_gate.sh all` green (content 100/100, engine
  50/50, save-compat 46/46, perf 6/6 after bumping the Y-sort budget
  51->54, touch 10/10). `tests/test_peer_npcs.gd` extended to 73/73
  (instancing/gift/specialty-sell for all 3 new candidates, plus the
  "1_warned" fire/no-fire check across all 6). `test_affinity.gd`
  (43/43), `test_anniversary.gd` (6/6), `test_wedding.gd` (6/6)
  regression-checked green, unaffected. Merged `64850e7`, pushed.
- **Stop reason:** Sprint 2 of the 8-sprint plan complete. TASK-347
  (schema v5: `rival_progress`/`rival_friendship`/`rival_confessed`)
  is next — a save-schema change, same risk class as TASK-340, self-
  executed with the same care (write the migration test first).
