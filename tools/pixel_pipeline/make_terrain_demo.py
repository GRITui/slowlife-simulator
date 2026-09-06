"""Stage 5 demo: Tiled blob terrain (16-tile corner wang/terrain format).

Derives a full 16-combo grass/water terrain tileset from two pipeline-produced
48x48 base tiles (repo principle: derive variants locally, don't re-generate),
writes Tiled legacy terrain attributes (corner order TL,TR,BL,BR), assembles a
canon 20x16 demo map with a pond, and rasterizes a preview with tmxrasterizer.

Run:  ~/.venvs/artpipe/bin/python make_terrain_demo.py \
        --grass /tmp/tile_grass.png --water /tmp/tile_water.png --out /tmp/terrain_demo
"""
from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw

TILED = "/Applications/tiled.app/Contents/MacOS/tiled"
RASTERIZER = "/Applications/tiled.app/Contents/MacOS/tmxrasterizer"
INK = (0x2B, 0x1C, 0x14, 255)
GRASS_IDX = 0
WATER_IDX = 1

# corner bit layout: bit0=TL, bit1=TR, bit2=BL, bit3=BR  (set = GRASS on that corner)
CORNERS = [(0, 0), (47, 0), (0, 47), (47, 47)]
# pieslice angles (PIL: 0 = 3 o'clock, clockwise)
_PIESLICE = {0: (90, 180), 1: (0, 90), 2: (180, 270), 3: (270, 360)}


def derive_tile(base_grass: Image.Image, base_water: Image.Image, mask: int) -> Image.Image:
    """Water base + grass corner-quadrants where mask bits are set.

    Corner-wang geometry: each corner's terrain fills its full quadrant
    (corner -> tile center), so identical corners across a shared edge join
    seamlessly and a full-corner tile is solid. A quarter-arc accent marks
    the diagonal shore inside each grass quadrant (pure full-grass stays clean).
    """
    img = base_water.convert("RGBA").copy()
    grass = base_grass.convert("RGBA")
    d = ImageDraw.Draw(img)
    mid = 24  # tile center
    for i, (cx, cy) in enumerate(CORNERS):
        if not (mask >> i) & 1:
            continue
        qx0, qy0 = min(cx, mid), min(cy, mid)
        qx1, qy1 = max(cx, mid), max(cy, mid)
        img.paste(grass, (0, 0), _quadrant_mask(i))
    return img


def _quadrant_mask(i: int) -> Image.Image:
    """Alpha mask covering quadrant i (corner -> center)."""
    m = Image.new("L", (48, 48), 0)
    ImageDraw.Draw(m).rectangle([(24 if i in (1, 3) else 0, 24 if i in (2, 3) else 0),
                                 (48 if i in (1, 3) else 24, 48 if i in (2, 3) else 24)],
                                fill=255)
    return m


def terrain_attr(mask: int) -> str:
    """Legacy Tiled terrain attr: corner terrain ids TL,TR,BL,BR (grass=0, water=1)."""
    return ",".join(str(GRASS_IDX if (mask >> i) & 1 else WATER_IDX) for i in range(4))


def build_tmx(tiles: list[Image.Image], out_dir: Path) -> Path:
    out_dir.mkdir(parents=True, exist_ok=True)

    # atlas strip referenced by the tileset
    atlas = Image.new("RGBA", (192, 192), (0, 0, 0, 0))
    for i, t in enumerate(tiles):
        atlas.paste(t, ((i % 4) * 48, (i // 4) * 48))
    atlas.save(out_dir / "atlas.png")

    # tileset: terrain 0=grass (anchor 15 = full grass), 1=water (anchor 0 = full water)
    terrains = (' <terrain name="grass" tile="15"/>\n'
                ' <terrain name="water" tile="0"/>')
    tsx = "\n".join(
        ['<?xml version="1.0" encoding="UTF-8"?>',
         '<tileset version="1.10" tiledversion="1.12.2" name="terrain_demo" '
         'tilewidth="48" tileheight="48" tilecount="16" columns="4">',
         ' <image source="atlas.png" width="192" height="192"/>',
         terrains]
        + [f' <tile id="{i}" terrain="{terrain_attr(i)}"/>' for i in range(16)]
        + ["</tileset>"]
    )
    (out_dir / "terrain_demo.tsx").write_text(tsx)

    # demo map: grass field with a 5x4 pond (center-dominated, interior water
    # shows the 16-tile corner format's limits; 47-tile blob format is the
    # upgrade path for rounded shores — see ART_DESIGN_PLAN.md)
    W, H = 20, 16
    pond = {(x, y) for x in range(7, 12) for y in range(6, 10)}

    def cell_mask(x: int, y: int) -> int:
        """Water cell's grass corners = diagonal neighbors NOT in the pond."""
        m = 0
        for i, (dx, dy) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)]):
            if (x + dx, y + dy) not in pond:
                m |= 1 << i
        return m

    gids = []
    for y in range(H):
        for x in range(W):
            # pond cells: grass corners toward non-pond diagonals;
            # field cells: full grass = tile id 15 -> gid 16 (firstgid 1)
            gids.append(cell_mask(x, y) + 1 if (x, y) in pond else 16)

    tmx = "\n".join(
        ['<?xml version="1.0" encoding="UTF-8"?>',
         '<map version="1.10" tiledversion="1.12.2" orientation="orthogonal" '
         'renderorder="right-down" width="20" height="16" tilewidth="48" tileheight="48" '
         'infinite="0" nextlayerid="2" nextobjectid="1">',
         ' <tileset firstgid="1" source="terrain_demo.tsx"/>',
         ' <layer id="1" name="ground" width="20" height="16">',
         '  <data encoding="csv">',
         ",".join(str(g) for g in gids),
         " </data>",
         " </layer>",
         "</map>"]
    )
    map_path = out_dir / "terrain_demo.tmx"
    map_path.write_text(tmx)
    return map_path


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--grass", required=True)
    ap.add_argument("--water", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    out_dir = Path(args.out)

    grass = Image.open(args.grass)
    water = Image.open(args.water)
    tiles = [derive_tile(grass, water, mask) for mask in range(16)]
    map_path = build_tmx(tiles, out_dir)

    subprocess.run([RASTERIZER, str(map_path), str(out_dir / "preview.png")], check=True)
    print("demo map + preview written to", out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

