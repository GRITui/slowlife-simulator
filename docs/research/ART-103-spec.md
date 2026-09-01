# TASK-103 — Festival visual layer (krathong pond glow + lantern particles)

**Status:** `proposed` | **Priority:** low | **Category:** art | **Owner:** art-po
**Sprint:** 10 of 10 (Head-of-Art roadmap, 2026-09-01)
**Blocked on:** `FestivalManager` instantiation + `SignalBus.festival_triggered` wiring — see `PO_INBOX.md` #3 (this is TASK-030's original scope, rejected pre-launch-gate, flagged revisit-worthy now that the launch-gate-critical lane is drained).

## Findings

`FestivalManager.gd` exists (TASK-022, Loy Krathong) but is never instantiated in `Main.tscn`; `festival_triggered` has zero listeners (confirmed unchanged by TASK-033's signal cleanup, which only touched `day_night_cycle_changed`). The krathong-release event currently has no visual payoff beyond the dialogue/inventory item — no pond glow, no lantern particles, despite the festival being a named locked-in world-vision feature (Hybrid A/B canal maze).

## Plan

1. `assets/particles/festival_lanterns.tres` — warm Jasmine Gold/Hot Orange `GPUParticles2D`, low `amount` (≤ 60), slow upward drift, positioned over the lotus pond/dock area.
2. `assets/shaders/pond_glow.gdshader` — `canvas_item`, soft radial glow overlay on the `WaterOverlay` pond region, gated on active-festival state, blending with TASK-032's `water_seasonal` tint rather than replacing it.
3. Driver script subscribing to `SignalBus.festival_triggered` (bus-only pattern) — this is what gives that signal its first production listener, resolving the QA-audit-flagged dead-emit the same way TASK-034 resolved `day_night_cycle_changed`.
4. **Cannot be usefully merged until the `PO_INBOX.md` #3 engine dependency lands** — art assets/shaders can be authored in parallel, but the driver has nothing to listen to until `FestivalManager` is actually instantiated and emitting.

## Acceptance

- `SignalBus.festival_triggered` connect-site count 0 → ≥1.
- Effects only active during an active festival window, zero cost otherwise.
- Stays within TASK-031's draw-call/particle budget stacked with TASK-038/039's rain/smoke/pollen (worst-case joint check, same caveat as TASK-039).

## Risk

Low on the art side; the real risk is sequencing — do not promote this task ahead of its engine dependency landing, or the driver ships inert.
