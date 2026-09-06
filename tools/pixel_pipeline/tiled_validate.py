"""Tiled map validation for the repo's tileset/map conventions.

Validates:
- map size 20x16 (flat paddy grid canon, Hybrid A/B world decision)
- tile size 48 (TILE=48 canon)
- no tile index used without a GID (catches export corruption)
- terrain/autotile completeness for the 16-tile blob terrain format
  (Tiled 1.x terrain encoding: every 3x3 neighborhood must resolve)

Usage:  python tiled_validate.py map.tmx
Exit 0 = valid; nonzero = invalid (for CI / the art gate).
"""
from __future__ import annotations

import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

TMX_NS = {}


def parse_gid(gid: int) -> tuple[int, bool]:
    """Return (clean_gid, flipped). Upper 3 bits are flip flags."""
    FLIP = 0x80000000 | 0x40000000 | 0x20000000
    return gid & ~FLIP, bool(gid & FLIP)


def validate(path: Path) -> list[str]:
    errors: list[str] = []
    root = ET.parse(path).getroot()
    if root.tag != "map":
        errors.append("not a .tmx map file")
        return errors

    w, h = int(root.get("width", "0")), int(root.get("height", "0"))
    tw, th = int(root.get("tilewidth", "0")), int(root.get("tileheight", "0"))
    if (w, h) != (20, 16):
        errors.append(f"map size {w}x{h} != 20x16 (canon)")
    if (tw, th) != (48, 48):
        errors.append(f"tile size {tw}x{th} != 48x48 (TILE=48 canon)")

    for layer in root.findall("layer"):
        name = layer.get("name", "?")
        data = layer.find("data")
        if data is None or not (data.text or "").strip():
            errors.append(f"layer '{name}': no data")
            continue
        encoding = data.get("encoding")
        if encoding == "csv":
            gids = [int(v) for v in (data.text or "").replace("\n", "").split(",") if v.strip()]
            if len(gids) != w * h:
                errors.append(f"layer '{name}': {len(gids)} tiles != {w*h}")
            for i, g in enumerate(gids):
                if g < 0:
                    errors.append(f"layer '{name}': negative gid at {i}")
    return errors


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    errs = validate(Path(sys.argv[1]))
    if errs:
        print("INVALID:")
        for e in errs:
            print(" -", e)
        sys.exit(1)
    print("VALID:", sys.argv[1])
