"""TASK-351 HUD polish — regenerate UI textures per ART_STYLE_GUIDE.md's
already-specified (but never-implemented) visual spec: Clay Brown rounded
1px border, Rice White 90%-opacity background, warm accent gradients.
Same exact pixel dimensions as the assets they replace, so no HUD.tscn
layout math needs to change.

Run from the repo root:
    python3 tools/gen_hud_assets.py
"""
import os
from PIL import Image, ImageDraw

RICE_WHITE = (242, 230, 196)
JASMINE_GOLD = (224, 162, 58)
PANDAN_GREEN = (79, 138, 61)
GRASS_GREEN = (127, 174, 70)
LOTUS_PINK = (224, 138, 160)
CLAY_BROWN = (106, 74, 48)
INK_OUTLINE = (43, 28, 20)
HOT_ORANGE = (201, 98, 47)
SOIL_TAN = (216, 201, 160)

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(REPO_ROOT, "assets", "ui") + "/"

def rounded_panel(size, radius, bg, bg_alpha, border, border_w=1):
    w, h = size
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([0, 0, w - 1, h - 1], radius=radius,
                         fill=(bg[0], bg[1], bg[2], bg_alpha))
    d.rounded_rectangle([0, 0, w - 1, h - 1], radius=radius,
                         outline=border, width=border_w)
    return im

def energy_bar():
    # 128x28 — 4 warm-to-cool segments (green -> gold -> orange), Rice White
    # track showing through in the untraveled portion, Clay Brown border.
    w, h = 128, 28
    im = rounded_panel((w, h), 8, RICE_WHITE, 229, CLAY_BROWN)  # 229 = 90% of 255
    d = ImageDraw.Draw(im)
    segs = [GRASS_GREEN, GRASS_GREEN, JASMINE_GOLD, HOT_ORANGE]
    seg_w = (w - 6) / len(segs)
    for i, c in enumerate(segs):
        x0 = 3 + i * seg_w
        x1 = x0 + seg_w - 2
        d.rounded_rectangle([x0, 5, x1, h - 6], radius=4, fill=c)
    im.save(OUT + "energy_bar.png")

def harmony_bar():
    # 128x28 — Lotus Pink gradient segments, same frame treatment.
    w, h = 128, 28
    im = rounded_panel((w, h), 8, RICE_WHITE, 229, CLAY_BROWN)
    d = ImageDraw.Draw(im)
    segs = [(238, 200, 210), (232, 170, 190), LOTUS_PINK, (196, 100, 130)]
    seg_w = (w - 6) / len(segs)
    for i, c in enumerate(segs):
        x0 = 3 + i * seg_w
        x1 = x0 + seg_w - 2
        d.rounded_rectangle([x0, 5, x1, h - 6], radius=4, fill=c)
    im.save(OUT + "harmony_bar.png")

def season_display():
    # 128x32 — simple warm framed panel, no baked text (the real season
    # name is drawn by the Label nodes on top of this background already).
    im = rounded_panel((128, 32), 8, RICE_WHITE, 229, CLAY_BROWN)
    d = ImageDraw.Draw(im)
    # small corner accent flourish to differentiate from plain bars.
    d.ellipse([6, 8, 16, 18], fill=JASMINE_GOLD, outline=CLAY_BROWN, width=1)
    im.save(OUT + "season_display.png")

def inventory_slot():
    # 48x48 — Clay Brown rounded frame, Soil Tan interior (empty state).
    im = rounded_panel((48, 48), 10, SOIL_TAN, 255, CLAY_BROWN, border_w=2)
    im.save(OUT + "inventory_slot.png")

def action_prompt():
    # 48x48 base tile for the prompt background (stretched wide in HUD.tscn
    # via ActionPrompt's 240x48 container) — Rice White panel, Clay Brown
    # border, rounded corners, matching every other HUD panel now.
    im = rounded_panel((48, 48), 10, RICE_WHITE, 229, CLAY_BROWN)
    im.save(OUT + "action_prompt.png")

energy_bar()
harmony_bar()
season_display()
inventory_slot()
action_prompt()
print("done")
