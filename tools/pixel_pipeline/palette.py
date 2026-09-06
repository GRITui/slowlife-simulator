"""Repo palette bridge — 16 named hue roles from ART_STYLE_GUIDE.md (locked 2026-08-31).

Each role anchors a 3-tone soft-shading ramp (highlight/base/shadow) per the
style guide's "each rendered with its own soft shading ramp" rule. Pixel
pipeline output is quantized to the union of these ramps so generated art
stays inside the repo's measured ~70-color envelope.
"""
from __future__ import annotations

import colorsys
from typing import Dict, List, Tuple

# Role -> anchor hex, transcribed from ART_STYLE_GUIDE.md (measured 2026-08-31)
ROLE_ANCHORS: Dict[str, str] = {
    "rice_white": "#F2E6C4",
    "jasmine_gold": "#E0A23A",
    "pandan_green": "#4F8A3D",
    "grass_green": "#7FAE46",
    "lotus_pink": "#E08AA0",
    "clay_brown": "#6A4A30",
    "ink_outline": "#2B1C14",
    "deep_shadow": "#241A12",
    "pha_khao_ma_gray": "#B8B0A0",
    "monsoon_blue": "#3D5F80",
    "canal_teal": "#5FB6C9",
    "hot_orange": "#C9622F",
    "skin_wood_warm": "#D99A68",
    "deep_navy": "#274259",
    "dark_cloth": "#3F3E40",
    "soil_tan": "#D8C9A0",
}

INK = (0x2B, 0x1C, 0x14)
PAPER = (0xF6, 0xEF, 0xDB)  # warm white mix target for highlights


def _hex_to_rgb(h: str) -> Tuple[int, int, int]:
    h = h.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]


def _mix(a: Tuple[int, int, int], b: Tuple[int, int, int], t: float) -> Tuple[int, int, int]:
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))  # type: ignore[return-value]


def _clamp(v: Tuple[int, int, int]) -> Tuple[int, int, int]:
    return tuple(max(0, min(255, c)) for c in v)  # type: ignore[return-value]


def role_ramp(anchor_hex: str) -> Tuple[Tuple[int, int, int], ...]:
    """3-tone ramp: highlight (toward warm paper), base anchor, shadow (toward ink)."""
    base = _hex_to_rgb(anchor_hex)
    # hue/sat preserving-ish lighten: mix toward paper, nudge brightness floor
    hi = _mix(base, PAPER, 0.28)
    lo = _mix(base, INK, 0.30)
    return (_clamp(hi), base, _clamp(lo))


def build_ramp_palette(extra_hexes: List[str] | None = None) -> List[Tuple[int, int, int]]:
    """Ordered list of every palette color the quantizer may pick from."""
    colors: List[Tuple[int, int, int]] = []
    for role, anchor in ROLE_ANCHORS.items():
        ramp = role_ramp(anchor)
        # darkest roles: skip a near-duplicate highlight to save budget
        if role in ("ink_outline", "deep_shadow", "dark_cloth", "deep_navy"):
            colors.extend([ramp[1], ramp[2]])
        else:
            colors.extend(ramp)
    for hx in extra_hexes or []:
        colors.append(_hex_to_rgb(hx))
    # dedupe preserving order
    seen = set()
    out = []
    for c in colors:
        if c not in seen:
            seen.add(c)
            out.append(c)
    return out


def quantize_image(img, palette: List[Tuple[int, int, int]] | None = None, alpha_threshold: int = 128):
    """Quantize RGBA pixels to the ramp palette; alpha below threshold -> fully transparent.

    Keeps alpha channel binary (crisp pixel-art edges, no AA fringe) — matches the
    repo's hard-pixel-edge convention. NEAREST-friendly.
    """
    from PIL import Image

    palette = palette or build_ramp_palette()
    img = img.convert("RGBA")
    w, h = img.size
    src = img.load()
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dst = out.load()
    # precompute palette as flat list for speed
    pal = list(palette)
    for y in range(h):
        for x in range(w):
            r, g, b, a = src[x, y]
            if a < alpha_threshold:
                continue
            best, bd = None, 1 << 30
            for pr, pg, pb in pal:
                # weighted euclidean (human-perception-ish)
                d = 2 * (r - pr) ** 2 + 4 * (g - pg) ** 2 + 3 * (b - pb) ** 2
                if d < bd:
                    bd, best = d, (pr, pg, pb)
            dst[x, y] = (*best, 255)
    return out


def shift_hue(img, degrees: float, scale: float = 1.0):
    """Hue-rotate for locally deriving variants (growth stages, seasons) — the
    repo's documented 'derive locally rather than re-prompt' principle."""
    img = img.convert("RGBA")
    r, g, b, a = img.split()
    hsv = Image.merge("RGB", (r, g, b)).convert("HSV")
    h, s, v = hsv.split()
    h = h.point(lambda p: (p + int(degrees * 255 / 360)) % 256)
    s = s.point(lambda p: max(0, min(255, int(p * scale))))
    out = Image.merge("HSV", (h, s, v)).convert("RGB")
    out.putalpha(a)
    return out
