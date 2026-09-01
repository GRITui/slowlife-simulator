# TASK-040 — Hot season heat-haze shader

**Status:** `proposed` | **Priority:** low | **Category:** art | **Owner:** art-po
**Sprint:** 5 of 10 (Head-of-Art roadmap, 2026-09-01)

## Findings

`ART_STYLE_GUIDE.md` calls for a Hot-season atmospheric treatment; TASK-032 (water/foliage) and TASK-034 (day/night tint) cover the other two named shader pillars from CLAUDE.md, leaving heat-shimmer as the one remaining named effect with zero implementation.

## Plan

1. `assets/shaders/heat_haze.gdshader` — `canvas_item`, screen-top-band shimmer overlay: flat `COLOR` output (Hot Orange, low alpha, `sin`-pulsed, tapering to zero below the top ~20% of the viewport). **Revised during implementation**: does not sample `TEXTURE`/`SCREEN_TEXTURE` for true UV distortion — that pattern isn't used anywhere else in this codebase's shaders (`day_night_tint.gdshader` is also a flat-color overlay, not a texture-sampling one) and its `gl_compatibility` reliability wasn't worth the risk for a purely cosmetic effect. Same proven technique as TASK-034, just a different color/band shape.
2. Full-screen `ColorRect` overlay, same slot pattern as TASK-034's `day_night_tint` (both composite — heat-haze layered above day/night tint, below UI).
3. ≤ 4 ALU ops in `fragment()`, no branches, matching TASK-032/034's established perf discipline.

## Acceptance

- Effect only visible during `season == "hot"`, fully off (no draw cost beyond one quad) otherwise.
- Compiles clean on `gl_compatibility`; visually subtle per CLAUDE.md's "cozy, zero-combat" mandate — this is ambient texture, not a gameplay-obscuring effect.

## Risk

Low — additive, same rollback pattern as TASK-034 (`material = null`).
