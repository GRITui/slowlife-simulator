#!/usr/bin/env python3
"""ART-AUTOSHADE-spec implementation — general auto-shading pass.

Builds ONE general-purpose auto-shading tool that works on any existing
flat-colored PNG (any of the 340 "flat" assets measured at <=8 opaque
colors in the docs/research/ART-AUTOSHADE-spec.md audit) and applies it
as a batch pass across the asset tree. The technique is the same one
already proven this session in tools/gen_npc_portraits_v2.py:
per-region highlight blob (lighten) + shadow blob (darken), each
clipped to the region's own mask via binary-mask intersection. We
import and reuse that script's `lighten`/`darken` rather than
reimplementing the HSV scaling (one source of truth for the color
math, not two that can drift).

Per-region masks are NOT hand-authored here. Instead we:

  1. Load the image as RGBA and snapshot the exact alpha channel —
     alpha is preserved bit-for-bit through the whole transform, only
     RGB at already-opaque pixels may change. This is the same
     discipline documented in tools/gen_rival_portraits.py's hue_shift()
     comment ("do not round-trip through Image.convert('HSV') — HSV
     mode has no alpha channel") — the project has shipped an
     alpha-destroying bug class once already, so we never touch alpha.
  2. Identify the single darkest opaque color (by HSV value) that has
     at least a few dozen pixels — that is the "outline" color. If the
     image has 3+ opaque colors, that one color is left UNTOUCHED (no
     highlight/shadow blob over outlines — outlines should stay
     crisp). If the image has only 1-2 opaque colors (many item icons
     are exactly this), there is no separate outline and every opaque
     color gets shaded directly.
  3. For every other opaque color, build a binary mask of just that
     color, then run a plain BFS/flood-fill connected-components scan
     in pure Python (no scipy, no numpy — matching the rest of
     tools/gen_*.py). Components below min_region_px are dropped.
  4. For each surviving component, compute its bounding-box center
     (cx, cy) and an effective radius r = sqrt(area/pi), then composite
     a lightened highlight ellipse at (cx - 0.3r, cy - 0.3r) with
     radius 0.55r in lighten(color), and a darkened shadow ellipse at
     (cx + 0.35r, cy + 0.35r) with radius 0.6r in darken(color). Both
     are clipped to the component's own pixel mask (binary-mask
     intersection, not a smooth gradient — matches the existing
     flat-shaded look elsewhere and reads cleanly at these sizes).
  5. Restore the original alpha channel byte-for-byte and save the
     image back over itself. Dimensions are never changed (PIL keeps
     the same canvas).

Idempotency: auto_shade_image() returns False (no-op, file untouched)
if the file already has more than skip_above_colors (=8) opaque
unique colors. Re-running on an already-shaded asset is safe.

Batch runner: walks assets/items/, assets/environment/ (recursive),
assets/characters/, assets/tilesets/, assets/particles/ — never
assets/ui/ (portraits were hand-rewritten by tools/gen_npc_portraits_v2.py
and the HUD bars/panels are a different visual system, redone in
TASK-351's gen_hud_assets.py). .png.import sidecars are Godot's
importer cache metadata and are never touched.

Pre-pass alpha snapshot: the batch runner also writes a JSON manifest
of every targeted file's pre-pass dimensions and per-pixel alpha bytes
(base64-encoded) to assets/.pre_pass_alpha_snapshot.json before it
modifies any file. The companion tests/test_asset_shading.gd reads
that snapshot and asserts alpha is preserved bit-for-bit, since the
spec's verification step explicitly calls out the alpha-destroying bug
class as "the single most important regression guard".

Run from the repo root:
    python3 tools/auto_shade.py
"""
import base64
import colorsys
import json
import math
import os
import sys
from collections import deque

# Reuse the proven color math — one implementation, not two that can drift.
from PIL import Image, ImageDraw, ImageChops

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_npc_portraits_v2 import lighten, darken  # noqa: E402

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

# Directories the batch pass walks. assets/ui/ is intentionally NOT here
# (portraits + HUD chrome are a different visual system).
#
# BUGFIX (Code Quality Review, found via visual sampling): assets/tilesets/
# is also intentionally excluded. Visually comparing before/after samples
# of ground_grass.png and water_surface.png showed a single large
# directional highlight+shadow blob reads as an obvious "spotlight" on a
# standalone sprite, but on a TILEABLE ground/water texture that gets
# repeated across large stretches of the map, that same blob becomes a
# visible, non-tiling artifact — every tile shows the identical blob in
# the identical spot, which reads as a repeating stain, not lighting.
# Tileable ground textures need a different technique entirely (subtle
# per-pixel noise/dithering that stays tile-seamless, not a single
# directional light source) — out of scope for this pass; left as a
# known follow-up rather than shipping a regression.
BATCH_DIRS = [
    "assets/items",
    "assets/environment",
    "assets/characters",
    "assets/particles",
]

# Pre-pass alpha snapshot, written by the batch runner before any
# modification, read by tests/test_asset_shading.gd to verify the
# alpha-destroying bug class doesn't ship a second time. Hidden file
# in the assets/ root, not a real asset.
SNAPSHOT_PATH = os.path.join(REPO_ROOT, "assets", ".pre_pass_alpha_snapshot.json")

# Default idempotency threshold. Files already above this many opaque
# unique colors are skipped (re-running on already-shaded assets is a
# safe no-op).
DEFAULT_SKIP_ABOVE_COLORS = 8

# A "few dozen" pixels of outline is enough to confidently call a color
# an outline (single-pixel anti-alias flecks at a region border would
# otherwise trigger the outline detection).
OUTLINE_MIN_PIXELS = 24

# Components below this area in pixels are noise / single-pixel AA flecks
# — they're skipped during the connected-components scan, not turned
# into tiny blobs that read as dirt.
DEFAULT_MIN_REGION_PX = 4

# Light source: upper-left, so highlight shifts toward (-, -) and
# shadow toward (+, +). Matches tools/gen_npc_portraits_v2.py's default.
LIGHT_DIR = (-1, -1)


def _opaque_color_histogram(img):
    """Return { (r, g, b) : count } for every pixel with alpha > 0.

    Alpha itself is dropped from the key — only the RGB identity matters
    for region detection. We never need to know "this pixel is RGB=X
    with alpha=Y" separately, because we only ever paint RGB at pixels
    that are already opaque, and the pre-snapshotted alpha is restored
    byte-for-byte at write-back.
    """
    px = img.load()
    w, h = img.size
    out = {}
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            key = (r, g, b)
            out[key] = out.get(key, 0) + 1
    return out


def _identify_outline_color(hist):
    """Return the (r, g, b) of the darkest opaque color with at least
    OUTLINE_MIN_PIXELS pixels, or None if no such color exists.

    "Darkest" = lowest HSV value (V). Tie-broken by saturation
    descending (a more-saturated dark is more likely a deliberate
    outline than a coincidentally-dark mid-tone).
    """
    candidates = [(cnt, rgb) for rgb, cnt in hist.items() if cnt >= OUTLINE_MIN_PIXELS]
    if not candidates:
        return None
    def sort_key(cc):
        h, s, v = colorsys.rgb_to_hsv(cc[1][0] / 255.0,
                                       cc[1][1] / 255.0,
                                       cc[1][2] / 255.0)
        return (v, -s)
    candidates.sort(key=sort_key)
    return candidates[0][1]


def _color_masks(img, colors, exclude_rgb):
    """Return { (r,g,b) : 2D list-of-bool mask } for each color in
    colors, excluding the outline color (which is never shaded)."""
    px = img.load()
    w, h = img.size
    masks = {rgb: [[False] * w for _ in range(h)] for rgb in colors}
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            rgb = (r, g, b)
            if rgb == exclude_rgb:
                continue
            if rgb in masks:
                masks[rgb][y][x] = True
    return masks


def _connected_components(mask, min_pixels):
    """Plain BFS/flood-fill connected-components labeling over a 2D
    bool mask (4-connectivity). Returns a list of components, each a
    dict { 'pixels': [(x, y), ...], 'bbox': (x0, y0, x1, y1) }.

    Images here are at most 96x96 (tall character sprites), so a pure
    Python BFS over the mask is well under a millisecond per file.
    No scipy/numpy — matches every other tools/gen_*.py in the repo.
    Components smaller than min_pixels are dropped.
    """
    h = len(mask)
    w = len(mask[0]) if h else 0
    seen = [[False] * w for _ in range(h)]
    components = []
    for y0 in range(h):
        for x0 in range(w):
            if not mask[y0][x0] or seen[y0][x0]:
                continue
            q = deque()
            q.append((x0, y0))
            seen[y0][x0] = True
            pixels = []
            xmin = ymin = 10**9
            xmax = ymax = -1
            while q:
                x, y = q.popleft()
                pixels.append((x, y))
                if x < xmin: xmin = x
                if x > xmax: xmax = x
                if y < ymin: ymin = y
                if y > ymax: ymax = y
                if x > 0     and mask[y][x-1]     and not seen[y][x-1]:
                    seen[y][x-1] = True; q.append((x-1, y))
                if x < w - 1 and mask[y][x+1]     and not seen[y][x+1]:
                    seen[y][x+1] = True; q.append((x+1, y))
                if y > 0     and mask[y-1][x]     and not seen[y-1][x]:
                    seen[y-1][x] = True; q.append((x, y-1))
                if y < h - 1 and mask[y+1][x]     and not seen[y+1][x]:
                    seen[y+1][x] = True; q.append((x, y+1))
            if len(pixels) >= min_pixels:
                components.append({
                    "pixels": pixels,
                    "bbox": (xmin, ymin, xmax, ymax),
                })
    return components


# BUGFIX (Code Quality Review, found first by the delegate itself while
# tracing why cabbage_stage1.png's fill color vanished entirely): for a
# small component, hl_r/sh_r's `max(2, ...)` floor means both blobs are
# a full circle of diameter >=4 regardless of how small the component
# actually is. Once a component's area drops below ~16px (r < ~2.26),
# the highlight ellipse and shadow ellipse together cover the ENTIRE
# mask, and the true base color — the visual "base" of a base/highlight
# /shadow 3-tone look — disappears completely, leaving only the two
# extreme tones. Below this threshold, apply the highlight blob only
# (skip the shadow) so the original base color always survives
# somewhere in the region; a 2-tone base+highlight look on a handful of
# pixels (early crop-growth sprites, tiny particle dots) reads better
# than losing the base tone outright.
_TINY_REGION_AREA_PX = 16


def _shade_component(canvas, base_mask_pixels, color, w, h):
    """Composite a lighten() highlight blob and a darken() shadow blob
    into canvas (an RGBA image, w x h) at the component's mask. The
    component's pixels live in base_mask_pixels (a list of (x, y)
    tuples). cx, cy, r are derived from the centroid and area:
    r = sqrt(area / pi).

    Both blobs are clipped to the component's exact pixel mask via
    ImageChops.darker on a binary L mask — same binary intersection
    technique used by tools/gen_npc_portraits_v2.py's shaded_region().
    Not a smooth gradient (smooth gradients read as noisy at 48x48 /
    64x64 and clash with the game's flat-shaded look elsewhere).
    """
    area = len(base_mask_pixels)
    cx = sum(x for (x, _) in base_mask_pixels) / area
    cy = sum(y for (_, y) in base_mask_pixels) / area
    r = max(2.0, math.sqrt(area / math.pi))
    tiny_region = area < _TINY_REGION_AREA_PX

    # Build a binary L mask from the component's exact pixel set.
    base_l = Image.new("L", (w, h), 0)
    bp = base_l.load()
    for x, y in base_mask_pixels:
        bp[x, y] = 255

    # Highlight blob — lightened color, toward light source (-, -).
    hl_r = max(2, int(r * 0.55))
    hl_cx = cx + LIGHT_DIR[0] * r * 0.3
    hl_cy = cy + LIGHT_DIR[1] * r * 0.3
    hl_canvas = Image.new("L", (w, h), 0)
    ImageDraw.Draw(hl_canvas).ellipse(
        [hl_cx - hl_r, hl_cy - hl_r, hl_cx + hl_r, hl_cy + hl_r],
        fill=255,
    )
    hl_mask = ImageChops.darker(hl_canvas, base_l)
    canvas.paste(Image.new("RGBA", (w, h), lighten(color) + (255,)),
                 (0, 0), hl_mask)

    if tiny_region:
        return  # base + highlight only — see _TINY_REGION_AREA_PX comment above

    # Shadow blob — darkened color, away from light source (+, +).
    sh_r = max(2, int(r * 0.6))
    sh_cx = cx - LIGHT_DIR[0] * r * 0.35
    sh_cy = cy - LIGHT_DIR[1] * r * 0.35
    sh_canvas = Image.new("L", (w, h), 0)
    ImageDraw.Draw(sh_canvas).ellipse(
        [sh_cx - sh_r, sh_cy - sh_r, sh_cx + sh_r, sh_cy + sh_r],
        fill=255,
    )
    sh_mask = ImageChops.darker(sh_canvas, base_l)
    canvas.paste(Image.new("RGBA", (w, h), darken(color) + (255,)),
                 (0, 0), sh_mask)


def auto_shade_image(path,
                     min_region_px=DEFAULT_MIN_REGION_PX,
                     skip_above_colors=DEFAULT_SKIP_ABOVE_COLORS):
    """Auto-shade one PNG. Returns True if the file was modified,
    False if it was a no-op (file untouched).

    See module docstring for the full algorithm. The two parameters
    the batch runner relies on:
      * min_region_px: components smaller than this many pixels are
        treated as noise / anti-alias flecks and not shaded.
      * skip_above_colors: idempotency guard. Files already above this
        many opaque unique colors are left alone.
    """
    img = Image.open(path).convert("RGBA")
    w, h = img.size

    # Snapshot the alpha channel — restored bit-for-bit at write-back.
    # This is the single most important invariant of the whole pass
    # (the project has shipped an alpha-destroying bug class once).
    px = img.load()
    original_alpha = bytearray(px[x, y][3] for y in range(h) for x in range(w))

    # Count opaque colors for the idempotency guard. We do this BEFORE
    # any modification.
    opaque_hist = _opaque_color_histogram(img)
    n_opaque = len(opaque_hist)
    if n_opaque > skip_above_colors:
        return False  # already shaded (or otherwise already-decent)

    # Identify the outline color. If the image has only 1-2 opaque
    # colors there's no separate outline — every color gets shaded.
    outline_rgb = None
    if n_opaque >= 3:
        outline_rgb = _identify_outline_color(opaque_hist)

    # Build per-color masks (excluding outline) and shade each region.
    shade_colors = [rgb for rgb in opaque_hist if rgb != outline_rgb]
    if not shade_colors:
        return False  # nothing to shade (image is all outline)

    masks_2d = _color_masks(img, shade_colors, outline_rgb)

    # Work on a copy — we paste *over* the original pixels, not
    # replace them, so the original RGB at every opaque pixel acts as
    # the base. The highlight+shadow blobs are then composited on top
    # of that base via PIL.paste (which respects the mask).
    canvas = img.copy()

    for rgb, mask_2d in masks_2d.items():
        comps = _connected_components(mask_2d, min_region_px)
        for comp in comps:
            _shade_component(canvas, comp["pixels"], rgb, w, h)

    # Restore the exact original alpha channel byte-for-byte.
    out_px = canvas.load()
    idx = 0
    for y in range(h):
        for x in range(w):
            r, g, b, _a = out_px[x, y]
            out_px[x, y] = (r, g, b, original_alpha[idx])
            idx += 1

    canvas.save(path)
    return True


def _walk_pngs(roots):
    """Yield full paths of every .png under any of the given roots
    (recursive). .png.import sidecars are skipped — those are Godot's
    own cache metadata."""
    for root in roots:
        full_root = os.path.join(REPO_ROOT, root)
        if not os.path.isdir(full_root):
            continue
        for dp, _dn, fn in os.walk(full_root):
            for f in sorted(fn):
                if not f.endswith(".png"):
                    continue
                if f.endswith(".png.import"):
                    continue
                yield os.path.join(dp, f)


def _count_opaque_colors(path):
    """Helper for the batch report — same definition the pre-pass
    audit used, so the report numbers match. Uses .getcolors() on a
    forced RGBA conversion, then filters entries by alpha > 0."""
    img = Image.open(path).convert("RGBA")
    entries = img.getcolors(maxcolors=img.width * img.height) or []
    return sum(1 for cnt, rgba in entries if rgba[3] > 0)


def _write_pre_pass_snapshot(png_paths):
    """Write a JSON manifest of {path: {w, h, alpha_b64}} for every
    targeted PNG. The test reads this to assert alpha is preserved
    bit-for-bit post-pass. Only written if the file doesn't already
    exist, so re-running the batch pass doesn't lose the original
    pre-pass snapshot.
    """
    if os.path.exists(SNAPSHOT_PATH):
        return
    snap = {}
    for p in png_paths:
        img = Image.open(p).convert("RGBA")
        w, h = img.size
        px = img.load()
        alpha_bytes = bytes(px[x, y][3] for y in range(h) for x in range(w))
        snap[os.path.relpath(p, REPO_ROOT)] = {
            "w": w,
            "h": h,
            "alpha": base64.b64encode(alpha_bytes).decode("ascii"),
        }
    with open(SNAPSHOT_PATH, "w") as f:
        json.dump(snap, f)


def main():
    paths = list(_walk_pngs(BATCH_DIRS))
    print(f"== auto-shade batch pass: {len(paths)} files ==")
    _write_pre_pass_snapshot(paths)

    n_shaded = 0
    n_skipped = 0
    n_failed = 0
    for p in paths:
        rel = os.path.relpath(p, REPO_ROOT)
        before = _count_opaque_colors(p)
        try:
            shaded = auto_shade_image(p)
        except Exception as e:
            print(f"{rel}: ERROR {e}")
            n_failed += 1
            continue
        if not shaded:
            print(f"{rel}: SKIPPED (already {before} colors)")
            n_skipped += 1
        else:
            after = _count_opaque_colors(p)
            print(f"{rel}: {before} colors -> {after} colors")
            n_shaded += 1
    print(f"== done: {n_shaded} shaded, {n_skipped} skipped (idempotency guard), {n_failed} failed ==")


if __name__ == "__main__":
    main()
