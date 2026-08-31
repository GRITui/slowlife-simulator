# TASK-028 — iOS Export Pipeline + Safe-Area Insets (Engine/Mobile)

**Status:** `proposed` | **Priority:** high | **Category:** ci | **Owner:** backend-automation
**Files:** `export_presets.cfg`, `scenes/ui/HUD.tscn`, `scenes/core/Main.gd`, `scripts/ci/`

## @scout Findings
- CLAUDE.md targets iOS; project.godot has no export_presets.cfg (gitignored) and no `DisplayServer.get_display_safe_area()` usage anywhere — notch/Dynamic Island will crop the HUD on device.
- `HUD.tscn` MarginContainer uses fixed offsets (12/10) — needs safe-area-aware insets on mobile.
- `PROJECT_VISION.md` requires PC & Mobile; ENGINE-012 touch input exists, but no device export build validates it.

## Plan
- Add `export_presets.cfg` iOS preset (gitignored per .gitignore — commit a template `docs/ios_export_template.md` instead).
- HUD `_apply_scale()`: on mobile, inset Margin by `DisplayServer.get_display_safe_area()` delta (44pt notch + home bar).
- Optional CI: xcodebuild smoke job behind a manual dispatch (no signing secrets in repo).

## Acceptance
- `godot --headless` gates stay green (98/98, 14/14, 50/50); HUD respects safe area on mobile viewport simulation; template doc committed.

## Risk
- Low — additive; no signing/material changes to the repo.
