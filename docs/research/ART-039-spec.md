# TASK-039 — Cooking smoke + lotus pollen ambient particles

**Status:** `proposed` | **Priority:** medium | **Category:** art | **Owner:** art-po
**Sprint:** 4 of 10 (Head-of-Art roadmap, 2026-09-01)

## Findings

Continues TASK-038's particle-pillar buildout. TASK-031's perf budget names "cooking smoke" and "lotus pollen" alongside rain as the three always-considered ambient systems; neither exists yet. `clay_stove_tall.png` (cooking) and the lotus maze/pond water feature (from the Hybrid A/B world-layout decision) are both already-placed static props this can attach to.

## Plan

1. `assets/particles/cooking_smoke.tres` — small always-on `GPUParticles2D`, low `amount` (≤ 40), soft upward drift + fade, anchored at the `clay_stove_tall` prop position in `WorldRender.gd`'s prop layer. Always-emitting (no signal gating needed — stove is a static fixture).
2. `assets/particles/lotus_pollen.tres` — gentle horizontal drift over the lotus maze/pond area, low `amount` (≤ 40), Rice White/Jasmine Gold tint, slow fade-in/out loop.
3. Both stay well under TASK-031's ≤200-peak ceiling even stacked with TASK-038's rain (40+40+200 worst case still ≤ 280 peak — flag this in Acceptance below for a joint perf check once TASK-038 lands, since the two tasks' budgets weren't co-designed).

## Acceptance

- Combined draw-call delta with TASK-038 (rain) verified ≤ TASK-031's 200 peak cap — call out to `@po`/`@qa-auditor` to re-run the perf gate once both particle tasks are merged, not just each individually.
- Both particles readable at the 3/4-perspective camera zoom (2.2) without obscuring gameplay-relevant sprites.

## Risk

Low-medium — the only real risk is the *combined* particle budget across TASK-038+039+ (rain+smoke+pollen simultaneously during a rainy cooking scene); flagged above rather than assumed safe.
