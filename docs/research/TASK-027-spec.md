# TASK-027 — Accessibility: Font Scaling + High-Contrast HUD (Cozy/Access)

**Status:** `proposed` | **Priority:** medium | **Category:** ui | **Owner:** visual-inspector
**Files:** `scenes/ui/HUD.tscn`, `scenes/ui/HUD.gd`, `scenes/ui/Settings.tscn`, `project.godot`

## @qa-auditor Findings
- `HUD.gd:39` `Margin.scale = Vector2(s,s)` does 0.8 mobile scaling but no font-size scaling for accessibility; `theme_override_font_sizes/font_size` hard-coded `12-13` in `HUD.tscn:42` (Stamina/Harmony/Season/Time).
- `HUD.tscn:118` `TimeLabel`/`SeasonLabel` low contrast on `SeasonBg` `season_display.png` (0.41,0.10,0.60 purple on amber) — fails WCAG AA on `monsoon` blue `TimeManager`.
- No `Settings` to adjust `font_scale` or `high_contrast`; `PauseMenu.tscn:1` and `Settings` placeholder from `TASK-017` lacks `GameData` persistence.
- `gdlint` flags untyped `slots: Array` in `HUD.gd:82` `refresh_inventory` (TASK-018) — `Array[TextureRect]` needed.

## Plan
- `HUD.gd`: add `@export var font_scale: float = 1.0` with `func set_font_scale(s:float)` that updates `StaminaLabel/HarmonyLabel/SeasonLabel/TimeLabel/PromptLabel` `theme_override_font_sizes/font_size = int(12 * s)`, persist to `GameData` + `SaveManager` (`font_scale` field).
- `HUD.tscn`: add `high_contrast` toggle — when true, `StaminaBar`/`HarmonyBar` `tint_progress` → high-contrast palette (`#FFFFFF` on `#000000` under), `SeasonBg` modulate `1.5` brightness.
- `Settings.tscn`: `HSlider` 0.8–1.4 font scale, `CheckBox` high contrast, `SignalBus.settings_changed` (new) → `HUD` listens.
- `project.godot:11` `display/window/size/viewport_width` 1600 stays, but `HUD` `Margin` scale now `s * font_scale` for mobile: `0.8 * font_scale`.

## Acceptance
- Slider updates HUD font immediately, persists via `SaveManager` v2, survives reload.
- High-contrast toggle passes WCAG AA on all seasons (manual screenshot `HUD.gd` `F12` hook).
- `gdlint` clean (`Array[Label]` typing), `godot --headless` 54/54 + 50/50 green; no direct `get_node` coupling (uses `@onready` + `SignalBus`).

## Risk
- Low — visual only, additive `font_scale` default `1.0` keeps existing 0.8/1.0 behavior.
