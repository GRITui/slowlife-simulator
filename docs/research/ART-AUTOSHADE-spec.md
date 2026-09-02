# Full asset re-shading pass — general auto-shader tool

## Context (read this first)

An audit of all 393 PNGs under `assets/` (via a script measuring opaque
unique-color count per file — `im.getcolors()` on `.convert("RGBA")`,
counting only entries with alpha > 0) found:

- **340 files (86.5%) are "flat"**: 8 or fewer opaque colors.
- **53 files are "medium"**: 9-20 opaque colors (this includes the 6
  portraits already reworked this session in
  `tools/gen_npc_portraits_v2.py`, plus a handful of already-decent
  assets like `cat_idle_01.png`, `animal_buffalo_idle.png`, and
  `player_*.png`).
- **0 files exceed 20 colors.**

`ART_STYLE_GUIDE.md` documents a "softly-shaded, ~70 unique colors"
redesign as already applied project-wide (2026-08-31 pass) — this is
false for the vast majority of shipped assets; the pass evidently never
happened for anything but a few UI panels (see TASK-351's HUD work).

Given the scale (340 files), hand-designing each one individually
(the approach used for the 6 portraits) does not scale. This task
instead builds ONE general-purpose auto-shading tool that works on any
existing flat-colored PNG and applies it as a batch pass across the
asset tree.

## The technique (already proven this session)

`tools/gen_npc_portraits_v2.py`'s `shaded_region()` function is the
reference implementation: for a filled region, composite a **highlight
blob** (lightened color, offset toward the light source, shrunk) and a
**shadow blob** (darkened color, offset away from the light source,
shrunk), both clipped to the region's own mask via
`ImageChops.darker(shape_mask, region_mask)` (binary-mask
intersection — NOT a smooth gradient, which reads as noisy at these
resolutions (48x48 items, 64x64 portraits, up to 96px tall character
sprites) and clashes with the game's existing flat-shaded look
elsewhere).

This task generalizes that same technique to work on an ARBITRARY
existing image instead of a hand-authored one, by auto-detecting each
flat-color region instead of manually specifying ellipse/polygon masks
per asset.

## Build `tools/auto_shade.py`

### `auto_shade_image(path, min_region_px=4, skip_above_colors=8) -> bool`

Returns `False` (no-op, file untouched) if the image already has more
than `skip_above_colors` opaque unique colors — this is the
idempotency guard. Re-running this tool on an already-shaded asset
(or on the 6 hand-crafted portraits) must be a safe no-op.

Otherwise:

1. Load as RGBA. Record the exact alpha channel — **never modify
   alpha values**, only RGB. (This project has shipped the "PIL HSV
   round-trip destroys alpha" bug once already — see
   `tools/gen_rival_portraits.py`'s own comment on why it does a
   per-pixel `colorsys` shift instead of `Image.convert("HSV")`. Follow
   the same discipline here: never round-trip the whole image through
   a mode that drops alpha.)
2. Identify the **outline color**: the opaque color with the lowest
   HSV *value* (darkest) that has at least a few dozen pixels. If the
   image has 3+ distinct opaque colors, treat the single darkest one
   as "outline" and exclude it from shading entirely (leave those
   pixels untouched — outlines should stay crisp, not get a
   highlight/shadow blob of their own). If the image has only 1-2
   opaque colors (many `assets/items/*.png` icons are exactly this),
   there is no separate outline color — shade the single fill color
   directly (see step 4) and don't try to invent an outline.
3. For every remaining opaque color (excluding the outline color found
   in step 2, if any): build a binary mask of exactly that color
   (`Image.point` or direct pixel comparison), then find its connected
   components. **Do not add scipy or any new dependency** — implement
   connected-component labeling as a plain BFS/flood-fill over the
   mask (images here are at most 96x96px, this is fast enough in pure
   Python). Discard components smaller than `min_region_px`.
4. For each component: compute its bounding-box center `(cx, cy)` and
   an effective radius `r = sqrt(area / pi)`. Call the same
   `shaded_region`-style compositing already implemented in
   `tools/gen_npc_portraits_v2.py` — highlight blob at
   `(cx - 0.3r, cy - 0.3r)` with radius `0.55r` in `lighten(color)`,
   shadow blob at `(cx + 0.35r, cy + 0.35r)` with radius `0.6r` in
   `darken(color)`, both masked by the component's own pixel mask.
   Reuse `lighten()`/`darken()` from `gen_npc_portraits_v2.py` directly
   (import it, don't copy-paste the HSV scaling logic — one
   implementation, not two that can drift).
5. Composite the outline-color pixels back unchanged on top (if an
   outline color was identified in step 2).
6. Save, overwriting the original path, preserving the exact original
   dimensions and alpha channel bit-for-bit (only RGB values at
   already-opaque pixels may change).

### Batch runner (`if __name__ == "__main__":` block)

Walk these directories and call `auto_shade_image()` on every `.png`
found (skip `.png.import` sidecars — those are Godot's own cache
metadata, never touch them):

- `assets/items/` (157 files — mostly 2-3 color icons, the highest
  file count but smallest per-file screen footprint)
- `assets/environment/` including its `crops/`, `festival/`, `props/`
  subdirectories (~110 files combined — highest per-file screen
  footprint, second priority)
- `assets/characters/` — but ONLY files the pre-pass audit measured at
  8 or fewer colors (the tool's own `skip_above_colors` guard already
  handles this at the single-file level, so just point the runner at
  the whole directory)
- `assets/tilesets/`
- `assets/particles/`

Do **NOT** touch `assets/ui/` (portraits already redone by hand this
session; the 5 bar/panel textures were redone in TASK-351's
`gen_hud_assets.py` and are a different visual system — panel chrome,
not character/item art).

Print a before/after report as the runner goes: one line per
processed file, `path: N colors -> M colors` (or `SKIPPED (already N
colors)` for files the guard passed over). This report is for the
Code Quality Review step below — don't skip printing it to save
effort, it's the fastest way to sanity-check the whole run without
opening 340 images individually.

## Verification

1. Run `godot --headless --import --path .` after the batch pass and
   confirm it completes with no import errors — a changed PNG that
   Godot's importer chokes on (e.g., an unexpected color profile chunk
   PIL might embed) needs catching here, before anything else.
2. Run `bash scripts/ci/run_gate.sh all` — this project's existing
   tests only check resource **paths** for character sprites (see
   `tests/test_villager_portraits.gd`), never exact pixel content, so
   a content-only asset change should not break any existing test.
   Confirm this assumption holds (green gate) rather than just
   asserting it.
3. New `tests/test_asset_shading.gd` (GDScript, headless-safe):
   - Every file path that existed in `assets/items/`,
     `assets/environment/` (recursive), `assets/characters/`,
     `assets/tilesets/`, `assets/particles/` before the pass still
     exists after, at the same dimensions. (Compare against a
     `git show HEAD:<path>` snapshot for dimensions, or simpler: just
     assert `Image.load()` succeeds and `get_size()` matches a
     hardcoded manifest of `{path: [w, h]}` generated once from the
     current tree — whichever is less brittle to write headlessly in
     GDScript; use your judgement, this is a smoke test, not
     exhaustive pixel verification.)
   - Spot-check a handful of specific files (pick 5-6 across different
     categories — an item icon, an environment tile, a character
     sprite) and assert their POST-pass opaque color count is now
     `> 8` (proof the shading pass actually ran, not just a
     dimensions-preserved no-op).
   - Alpha invariant: for those same 5-6 spot-check files, confirm
     every originally-transparent pixel (alpha==0) is STILL alpha==0
     after the pass (compare against a `git show HEAD:<path>` byte
     snapshot of the pre-pass alpha channel). This is the single most
     important regression guard given the alpha-destroying bug class
     already shipped once in this project.

## Constraints

- No new pip/PyPI dependencies (no scipy, no numpy even, if avoidable
  — plain PIL + pure-Python flood fill only, matching every other
  `tools/gen_*.py` script in this repo).
- Do not modify any `.png.import` file.
- Do not touch `assets/ui/` (portraits, HUD bars/panels).
- Do not change any file's pixel dimensions.
- Do not modify alpha values anywhere — only RGB at already-opaque
  pixels.
- Reuse `lighten()`/`darken()` from `tools/gen_npc_portraits_v2.py`
  (import it) rather than reimplementing HSV scaling a third time.
- Run `bash scripts/ci/run_gate.sh all` and the new
  `tests/test_asset_shading.gd` yourself; both must be green.
- No git/gh actions — stop after the tool is written, the batch pass
  has been run once against the real asset tree, and tests are green.
  Do not commit, push, open a PR, or merge.
