# TASK-034 — Day/night ambient color-grading shader (canvas_item)

**Status:** `proposed` | **Priority:** medium | **Category:** art | **Owner:** art-po

## Findings (Phase 2 visual audit, shaders/atmosphere)

- **Zero `.gdshader` files exist anywhere in the repo** (`find . -iname "*.gdshader"` → empty). CLAUDE.md's Shader deliverables list "day/night screen color grading" alongside foliage sway and water refraction.
- TASK-032 (proposed, tech-art-lead) already covers `water_seasonal.gdshader` and `foliage_sway.gdshader` — this proposal deliberately does **not** duplicate that scope.
- **Superseded finding:** `SignalBus.day_night_cycle_changed` no longer exists. TASK-033 (backend-automation) executed and merged first (PR #86, `d0e1dd0`) — the signal and its per-minute emit were removed as orphan cleanup, and a negative-contract engine test now asserts it *stays* removed. The original framing of this proposal ("wire a listener onto the existing dead signal") is stale.
- TASK-033's own commit message green-lights the path forward: *"Reintroduce only with a live consumer (e.g. DayNightAtmosphere shader)."* This proposal now does exactly that — the plan below **re-adds** the signal as part of shipping the shader, not merely subscribes to it.

## Plan

1. Author `assets/shaders/day_night_tint.gdshader` — `canvas_item`, `render_mode unshaded, blend_mix`, full-screen `ColorRect` overlay (z-index above world, below UI). Single `vec3` tint uniform blended by day-fraction (dawn warm/Jasmine Gold → noon neutral → dusk Hot Orange → night Deep Navy), no per-pixel loops.
2. Matching `.tres` `ShaderMaterial`; author a driver script (`DayNightTintDriver.gd`, bus-only like `SeasonShaderDriver` from TASK-032) that expects a `day_night_cycle_changed(time_fraction: float)` signal to subscribe to.
3. Palette anchors from `ART_STYLE_GUIDE.md`: Jasmine Gold `#E0A23A` (dawn), Hot Orange `#C9622F` (dusk), Deep Navy `#274259` (night), neutral passthrough at noon.
4. Document uniform table + node hookup in `ART_STYLE_GUIDE.md`.
5. **Out of this role's edit scope (hand to `@po`/backend-automation, per Strict Guardrails — do not edit `SignalBus.gd`):** re-add `signal day_night_cycle_changed(time_fraction: float)` to `SignalBus.gd` and its per-minute emit in `TimeManager.gd` (both were removed by TASK-033, PR #86), and update TASK-033's new negative-contract engine test (`tests/run_engine_tests.gd`, "orphan stays removed" check) to allow it now that a live consumer exists. This driver script is inert without that signal — the two changes must land together, ideally in the same PR that wires this driver into `Main.tscn`.

## Acceptance

- Shader compiles clean on `gl_compatibility`; ≤ 4 ALU ops + no branches in `fragment()`.
- `SignalBus.day_night_cycle_changed` re-exists with exactly one connect-site (`DayNightTintDriver`) — the negative-contract gate from TASK-033 is updated, not just broken.
- No GDScript outside the new driver file, `SignalBus.gd`, and `TimeManager.gd` touched; `Main.tscn` node hookup documented for `@po` to wire.

## Risk

Low — additive `ColorRect` overlay, `material = null` is an instant rollback. No interaction with TASK-031's draw-call budget (one extra full-screen quad, well within the ≤120 idle target).
