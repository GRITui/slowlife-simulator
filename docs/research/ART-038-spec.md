# TASK-038 — Monsoon rain particle system

**Status:** `proposed` | **Priority:** medium | **Category:** art | **Owner:** art-po
**Sprint:** 3 of 10 (Head-of-Art roadmap, 2026-09-01)

## Findings

Zero `GPUParticles2D` nodes exist anywhere in the repo. CLAUDE.md explicitly scopes "atmospheric particle shaders" and "`GPUParticles2D` process materials" as a deliverable; TASK-031's own perf budget doc names "Monsoon rain" as one of the ≤3 concurrent "ambient pillars" the draw-call ceiling was already reserving headroom for. Rain doesn't exist yet — this task delivers it within that already-budgeted envelope.

## Plan

1. `assets/particles/rain.tres` — `GPUParticles2D` process material: screen-space overlay, `amount` ≤ 200 (TASK-031 cap), simple falling-streak `ParticleProcessMaterial` (gravity + slight wind drift), Monsoon Blue `#3D5F80` tint at low alpha.
2. Author a small `RainDriver.gd` (bus-only, same pattern as `SeasonShaderDriver`/`DayNightTintDriver`) subscribing to the existing `SignalBus.season_changed` — `emitting = (season == "monsoon")`. No new signals, no `SignalBus.gd` edit.
3. Document node hookup (`GPUParticles2D` + driver as a child of `Main` or `WorldRender`) in `ART_STYLE_GUIDE.md` for `@po` to instance — one-node addition, not a logic change.

## Acceptance

- Particle count ≤ 200, draw-call delta ≤ 1 (single `GPUParticles2D` node) — stays inside TASK-031's ≤120 idle / ≤200 peak budget.
- `emitting` toggles correctly across all 3 seasons via existing signal, no new SignalBus surface.
- No GDScript outside the new driver file touched.

## Risk

Low — additive, capped by TASK-031's own perf gate; `emitting = false` is instant rollback.
