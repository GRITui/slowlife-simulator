# TASK-101 — Crop Progress bar asset + HUD wiring

**Status:** `proposed` | **Priority:** medium | **Category:** art | **Owner:** art-po
**Sprint:** 6 of 10 (Head-of-Art roadmap, 2026-09-01)

## Findings

`ART_STYLE_GUIDE.md`'s Required UI Elements table lists Crop Progress (150x12) as "not yet delivered as a redesigned asset" — confirmed still true (see this doc's corrected HUD-wiring note, 2026-09-01). It's the one HUD element still rendering as a plain `Label` (`CropLabel` in `HUD.tscn`) instead of the themed bar the other four elements already got in TASK-015.

## Plan

1. Author `assets/ui/crop_progress_bar.png` (150x12, matching the table spec) — Pandan Green fill on Rice White base, consistent with `energy_bar.png`/`harmony_bar.png`'s existing style.
2. Replace `HUD.tscn`'s `CropLabel` (`Label`) with a `TextureProgressBar` (mirroring `StaminaBar`/`HarmonyBar`'s existing node pattern) using the new texture, plus keep a small text overlay for the "3/4" stage counter (`HUD.gd`'s `_on_crop_progress` already sets `progress`/`max_stage` — reuse those values for both the bar fill and the counter label, no new signal needed).
3. Update `ART_STYLE_GUIDE.md`'s Required UI Elements table to mark this delivered once shipped.

## Acceptance

- Crop progress renders as a themed bar consistent with the other 4 HUD elements, not a bare label.
- `HUD.gd:_on_crop_progress` continues to work with only a node-reference change (`crop_label` → new bar node), no signal/logic rewrite.
- Touch/safe-area unaffected (same `Margin/Root/CropProgress` container).

## Risk

Very low — single asset + single node swap in an already-wired scene.
