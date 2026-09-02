#!/usr/bin/env python3
"""Portrait quality pass — replaces the flat, 5-6-color single-tone NPC
portraits with soft-shaded versions (highlight/base/shadow per region),
per ART_STYLE_GUIDE.md's already-written "softly-shaded, ~70 colors"
spec, which the 2026-08-31 "Claude Design redesign" pass documented but
never actually applied to portraits (verified: current portraits measure
5-6 flat opaque colors each, not the ~70 the doc claims).

Scope: only the 6 portraits actually referenced in code
(scenes/core/Main.gd's PORTRAIT_PATHS) — elder, child, handler, monk,
trader, buffalo. Unreferenced files (fah, niran, headman, monkey,
nong_ton) are dead assets, out of scope for this pass.

Each character keeps its existing identity color (clothing hue) and the
shared skin tone (#D99A68, matches ART_STYLE_GUIDE.md exactly) — this is
a shading/detail upgrade, not a redesign of who looks like what.

Shading technique: each filled region (head, body, hat, etc.) gets a
highlight blob (lightened, shifted toward the upper-left light source)
and a shadow blob (darkened, shifted toward the lower-right), both
composited only within that region's own mask via ImageChops.darker on
binary L masks (intersection). This is a standard pixel-art "light source
+ core shadow" trick, not a smooth gradient (a smooth gradient reads as
noisy at 64x64 and clashes with the game's flat-shaded look elsewhere).

Run from the repo root:
    python3 tools/gen_npc_portraits_v2.py
"""
import colorsys
import os
from PIL import Image, ImageDraw, ImageChops

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT_DIR = os.path.join(REPO_ROOT, "assets", "ui", "portraits")

SKIN = (217, 154, 104)      # #D99A68 — ART_STYLE_GUIDE.md's spec skin tone
INK = (43, 28, 20)          # shared outline ink, matches existing files
EYE = (30, 22, 16)
SIZE = (64, 64)
LIGHT_DIR = (-1, -1)  # light from upper-left, shadow falls lower-right


def _scale_value(color, mult, sat_mult=1.0):
    r, g, b = (c / 255.0 for c in color)
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    v = max(0.0, min(1.0, v * mult))
    s = max(0.0, min(1.0, s * sat_mult))
    nr, ng, nb = colorsys.hsv_to_rgb(h, s, v)
    return (int(nr * 255), int(ng * 255), int(nb * 255))


def lighten(color):
    return _scale_value(color, 1.35, 0.85)


def darken(color):
    return _scale_value(color, 0.62, 1.1)


def _mask_from_draw(draw_fn):
    """draw_fn(ImageDraw) draws a filled white shape on a black L canvas."""
    m = Image.new("L", SIZE, 0)
    d = ImageDraw.Draw(m)
    draw_fn(d)
    return m


def shaded_region(canvas, base_mask, base_color, cx, cy, r, light_dir=LIGHT_DIR):
    """Composite base_color into canvas wherever base_mask is set, then add
    a highlight blob (toward light_dir) and shadow blob (away from it),
    both clipped to base_mask. (cx, cy, r) approximate the region's center
    and radius, used to place/size the highlight+shadow blobs."""
    base_layer = Image.new("RGBA", SIZE, base_color + (255,))
    canvas.paste(base_layer, (0, 0), base_mask)

    hl_r = max(2, int(r * 0.55))
    hl_cx, hl_cy = cx + light_dir[0] * r * 0.3, cy + light_dir[1] * r * 0.3
    hl_mask = _mask_from_draw(lambda d: d.ellipse(
        [hl_cx - hl_r, hl_cy - hl_r, hl_cx + hl_r, hl_cy + hl_r], fill=255))
    hl_mask = ImageChops.darker(hl_mask, base_mask)
    hl_layer = Image.new("RGBA", SIZE, lighten(base_color) + (255,))
    canvas.paste(hl_layer, (0, 0), hl_mask)

    sh_r = max(2, int(r * 0.6))
    sh_cx, sh_cy = cx - light_dir[0] * r * 0.35, cy - light_dir[1] * r * 0.35
    sh_mask = _mask_from_draw(lambda d: d.ellipse(
        [sh_cx - sh_r, sh_cy - sh_r, sh_cx + sh_r, sh_cy + sh_r], fill=255))
    sh_mask = ImageChops.darker(sh_mask, base_mask)
    sh_layer = Image.new("RGBA", SIZE, darken(base_color) + (255,))
    canvas.paste(sh_layer, (0, 0), sh_mask)


def outline_ellipse(canvas, bbox, width=2):
    ImageDraw.Draw(canvas).ellipse(bbox, outline=INK, width=width)


def outline_polygon(canvas, points, width=2):
    d = ImageDraw.Draw(canvas)
    d.line(points + [points[0]], fill=INK, width=width, joint="curve")


def draw_eyes(canvas, cx, cy, spacing=6, r=2):
    d = ImageDraw.Draw(canvas)
    d.ellipse([cx - spacing - r, cy - r, cx - spacing + r, cy + r], fill=EYE)
    d.ellipse([cx + spacing - r, cy - r, cx + spacing + r, cy + r], fill=EYE)


def new_canvas():
    return Image.new("RGBA", SIZE, (0, 0, 0, 0))


def portrait_elder():
    # Village Elder — traditional Thai conical farmer hat (ngob), walking
    # stick implied by warm palette, lotus-pink robe (matches the existing
    # file's identity color).
    c = new_canvas()
    body_mask = _mask_from_draw(lambda d: d.rounded_rectangle([14, 38, 50, 62], radius=10, fill=255))
    shaded_region(c, body_mask, (224, 138, 160), 32, 50, 16)
    head_mask = _mask_from_draw(lambda d: d.ellipse([18, 16, 46, 44], fill=255))
    shaded_region(c, head_mask, SKIN, 32, 30, 14)
    # conical hat: a triangle + brim ellipse, straw-tan colored.
    hat_mask = _mask_from_draw(lambda d: (
        d.polygon([(32, 2), (14, 20), (50, 20)], fill=255),
        d.ellipse([10, 15, 54, 25], fill=255),
    ))
    shaded_region(c, hat_mask, (196, 168, 96), 32, 12, 14)
    outline_ellipse(c, [18, 16, 46, 44])
    outline_ellipse(c, [14, 38, 50, 62])
    outline_polygon(c, [(32, 2), (14, 20), (50, 20)])
    ImageDraw.Draw(c).ellipse([10, 15, 54, 25], outline=INK, width=2)
    draw_eyes(c, 32, 32)
    ImageDraw.Draw(c).line([(28, 38), (36, 38)], fill=INK, width=2)  # calm mouth
    c.save(os.path.join(OUT_DIR, "elder.png"))
    print("wrote elder.png")


def portrait_child():
    # Child NPC — smaller sprite (scaled down, more empty canvas margin per
    # ART_STYLE_GUIDE.md), simple round hair, small basket accent.
    c = new_canvas()
    body_mask = _mask_from_draw(lambda d: d.rounded_rectangle([20, 42, 44, 60], radius=8, fill=255))
    shaded_region(c, body_mask, (79, 138, 61), 32, 51, 12)
    head_mask = _mask_from_draw(lambda d: d.ellipse([21, 20, 43, 42], fill=255))
    shaded_region(c, head_mask, SKIN, 32, 31, 11)
    hair_mask = _mask_from_draw(lambda d: d.chord([21, 18, 43, 36], start=180, end=360, fill=255))
    shaded_region(c, hair_mask, (60, 40, 25), 32, 24, 11)
    # small basket held at the side.
    basket_mask = _mask_from_draw(lambda d: d.rounded_rectangle([44, 48, 54, 56], radius=2, fill=255))
    shaded_region(c, basket_mask, (168, 122, 66), 49, 52, 5)
    outline_ellipse(c, [21, 20, 43, 42])
    outline_ellipse(c, [20, 42, 44, 60])
    ImageDraw.Draw(c).rounded_rectangle([44, 48, 54, 56], radius=2, outline=INK, width=1)
    draw_eyes(c, 32, 30, spacing=5, r=2)
    c.save(os.path.join(OUT_DIR, "child.png"))
    print("wrote child.png")


def portrait_handler():
    # Buffalo Handler — cyan neck scarf (matches existing accent color),
    # simple cloth headwrap, clay-brown traditional outfit.
    c = new_canvas()
    body_mask = _mask_from_draw(lambda d: d.rounded_rectangle([13, 38, 51, 62], radius=9, fill=255))
    shaded_region(c, body_mask, (106, 74, 48), 32, 50, 17)
    head_mask = _mask_from_draw(lambda d: d.ellipse([17, 15, 47, 45], fill=255))
    shaded_region(c, head_mask, SKIN, 32, 30, 15)
    wrap_mask = _mask_from_draw(lambda d: d.chord([16, 12, 48, 34], start=170, end=370, fill=255))
    shaded_region(c, wrap_mask, (95, 182, 201), 32, 18, 16)
    scarf_mask = _mask_from_draw(lambda d: d.rounded_rectangle([20, 38, 44, 46], radius=4, fill=255))
    shaded_region(c, scarf_mask, (95, 182, 201), 32, 42, 12)
    outline_ellipse(c, [17, 15, 47, 45])
    outline_ellipse(c, [13, 38, 51, 62])
    draw_eyes(c, 32, 32)
    c.save(os.path.join(OUT_DIR, "handler.png"))
    print("wrote handler.png")


def portrait_monk():
    # Temple Priest — bald head (skin-colored, no hair shape), saffron
    # robe with a darker sash line, calm expression.
    c = new_canvas()
    body_mask = _mask_from_draw(lambda d: d.rounded_rectangle([14, 38, 50, 62], radius=10, fill=255))
    shaded_region(c, body_mask, (224, 130, 40), 32, 50, 16)
    head_mask = _mask_from_draw(lambda d: d.ellipse([18, 16, 46, 44], fill=255))
    shaded_region(c, head_mask, SKIN, 32, 30, 14)
    outline_ellipse(c, [18, 16, 46, 44])
    outline_ellipse(c, [14, 38, 50, 62])
    # sash: a diagonal darker-orange band across the robe.
    ImageDraw.Draw(c).line([(18, 40), (34, 60)], fill=darken((224, 130, 40)), width=4)
    draw_eyes(c, 32, 32)
    ImageDraw.Draw(c).line([(27, 39), (37, 39)], fill=INK, width=1)  # serene mouth
    c.save(os.path.join(OUT_DIR, "monk.png"))
    print("wrote monk.png")


def portrait_trader():
    # Coastal/market trader — purple merchant outfit (existing identity
    # color), small cap accent.
    c = new_canvas()
    body_mask = _mask_from_draw(lambda d: d.rounded_rectangle([13, 38, 51, 62], radius=9, fill=255))
    shaded_region(c, body_mask, (106, 27, 154), 32, 50, 17)
    head_mask = _mask_from_draw(lambda d: d.ellipse([17, 15, 47, 45], fill=255))
    shaded_region(c, head_mask, SKIN, 32, 30, 15)
    cap_mask = _mask_from_draw(lambda d: d.chord([17, 10, 47, 30], start=180, end=360, fill=255))
    shaded_region(c, cap_mask, darken((106, 27, 154)), 32, 16, 15)
    outline_ellipse(c, [17, 15, 47, 45])
    outline_ellipse(c, [13, 38, 51, 62])
    draw_eyes(c, 32, 32)
    c.save(os.path.join(OUT_DIR, "trader.png"))
    print("wrote trader.png")


def portrait_buffalo():
    # Buffalo — shaded body (muzzle highlight, underbelly shadow), horns.
    c = new_canvas()
    body_mask = _mask_from_draw(lambda d: d.ellipse([8, 22, 56, 56], fill=255))
    shaded_region(c, body_mask, (120, 100, 85), 32, 39, 20)
    snout_mask = _mask_from_draw(lambda d: d.ellipse([20, 40, 44, 54], fill=255))
    shaded_region(c, snout_mask, lighten((120, 100, 85)), 32, 47, 10)
    outline_ellipse(c, [8, 22, 56, 56])
    d = ImageDraw.Draw(c)
    d.line([(18, 24), (12, 8)], fill=(200, 200, 190), width=3)
    d.line([(46, 24), (52, 8)], fill=(200, 200, 190), width=3)
    d.ellipse([25, 44, 29, 48], fill=EYE)  # nostril-ish
    d.ellipse([35, 44, 39, 48], fill=EYE)
    d.ellipse([20, 30, 24, 34], fill=EYE)  # eyes
    d.ellipse([40, 30, 44, 34], fill=EYE)
    c.save(os.path.join(OUT_DIR, "buffalo.png"))
    print("wrote buffalo.png")


if __name__ == "__main__":
    portrait_elder()
    portrait_child()
    portrait_handler()
    portrait_monk()
    portrait_trader()
    portrait_buffalo()
    print("done")
