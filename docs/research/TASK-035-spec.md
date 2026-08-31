# TASK-035 — UI touch-target sizing, safe-area insets & cozy theming (Settings/Pause/Title)

**Status:** `proposed` | **Priority:** high | **Category:** art | **Owner:** art-po

## Findings (Phase 2 visual audit, `scenes/ui/`)

- **`Settings.tscn` (LIVE — instanced in `Main.tscn` id `10_settings`, reachable in production today):**
  - `FontScaleSlider`: `custom_minimum_size = Vector2(180, 20)` — 20px drag height is well under the 44×44pt touch minimum (CLAUDE.md §Technical Constraints #3).
  - `HighContrastCheck`: no `custom_minimum_size` at all — default `CheckBox` hit box (~24px) also fails the minimum.
  - No cozy-palette theme applied anywhere in the scene; renders in default Godot gray, inconsistent with `ART_STYLE_GUIDE.md`.
- **`PauseMenu.tscn` / `TitleScreen.tscn` (currently dead — confirmed via `grep`, not instanced by any scene; blocked on a `GameStateManager` wiring task outside this role's GDScript-logic guardrail):**
  - `Resume` / `Settings` / `Quit` / `NewGame` / `Continue` buttons are bare `Button` nodes: no `custom_minimum_size`, no theme, default Godot styling.
  - No `MarginContainer` and no safe-area handling — same gap `HUD.gd:_apply_safe_area_insets()`-equivalent (`apply_safe_area()`) already solves for the HUD (TASK-028).

## Plan

1. **`Settings.tscn`:** set `FontScaleSlider.custom_minimum_size = Vector2(200, 44)`; wrap `HighContrastCheck` sizing to `Vector2(44, 44)` minimum via theme override; apply the cozy palette (`ART_STYLE_GUIDE.md` anchors: Rice White bg, Clay Brown text, Jasmine Gold accent) as a scene-local `Theme` resource.
2. **`PauseMenu.tscn` / `TitleScreen.tscn`:** give every `Button` `custom_minimum_size = Vector2(200, 44)` (≥44pt height), apply the same cozy `Theme`, and add a root `MarginContainer` sized/inset to match `HUD.tscn`'s pattern so a future `apply_safe_area()`-style call (GDScript wiring, out of this role's scope) has a container to inset.
3. Document the required activation interface (a `GameStateManager` or pause-input hook to actually show these scenes) in `ART_STYLE_GUIDE.md` and hand back to `@po` per Strict Guardrails — this task only fixes the visual/`.tscn` layer, not instancing/wiring.

## Acceptance

- All interactive controls in the three scenes report `size.y >= 44` and `size.x >= 44` post-layout.
- Cozy theme applied (no default-gray Godot controls remain in these scenes).
- `godot --headless` gates stay green (150/150 per current QA baseline); no `.gd` logic files touched.

## Risk

Low — `.tscn`/`Theme` only, no GDScript logic or SignalBus changes. `PauseMenu`/`TitleScreen` remain unwired (dead) after this task; only their visual readiness changes.
