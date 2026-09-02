#!/usr/bin/env python3
"""TASK-342 placeholder portraits — hue-shift 6 existing romance-candidate
sprites to create 6 rival portraits, each visibly different. Mirrors the
hue-shift approach used for TASK-341's kanya/kiet/malee placeholders (those
were later renamed to chang/klong/yaa). Source/dest under
res://assets/characters/.

Run from the repo root:
    python3 tools/gen_rival_portraits.py
"""
import os
from PIL import Image

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
CHAR_DIR = os.path.join(REPO_ROOT, "assets", "characters")

# source_base_id -> (output_id, hue_degrees) — six distinct hue rotations
# taken from six different existing sprites so no two rivals look identical.
JOBS = [
    ("ek",    "yai",  30.0),
    ("fah",   "ohm",  90.0),
    ("ploy",  "rung", 150.0),
    ("chang", "note", 210.0),
    ("klong", "fon",  270.0),
    ("yaa",   "boon", 330.0),
]

def hue_shift(src_path: str, dst_path: str, degrees: float) -> None:
    # NOTE: do not round-trip through Image.convert("HSV") — HSV mode has no
    # alpha channel, so merging back to RGBA reconstructs alpha as fully
    # opaque (255) everywhere, destroying the sprite's transparent background
    # (turns it into a solid black rectangle in-game). Shift hue per-pixel via
    # colorsys instead, preserving each pixel's original alpha explicitly.
    import colorsys
    img = Image.open(src_path).convert("RGBA")
    px = img.load()
    w, h_px = img.size
    out = Image.new("RGBA", (w, h_px))
    opx = out.load()
    shift = degrees / 360.0
    for y in range(h_px):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                opx[x, y] = (0, 0, 0, 0)
                continue
            hh, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
            hh = (hh + shift) % 1.0
            nr, ng, nb = colorsys.hsv_to_rgb(hh, s, v)
            opx[x, y] = (int(nr * 255), int(ng * 255), int(nb * 255), a)
    out.save(dst_path)
    print("wrote %s (hue %+.0f)" % (os.path.relpath(dst_path, REPO_ROOT), degrees))

def main() -> None:
    for src_id, dst_id, deg in JOBS:
        src_path = os.path.join(CHAR_DIR, "%s_idle_01.png" % src_id)
        dst_path = os.path.join(CHAR_DIR, "%s_idle_01.png" % dst_id)
        if not os.path.exists(src_path):
            raise SystemExit("missing source sprite: %s" % src_path)
        hue_shift(src_path, dst_path, deg)

if __name__ == "__main__":
    main()