"""Stages 2+3 of the art pipeline: background isolation + grid alignment/pixelation.

  raw concept (512px) -> rembg (u2net alpha matting)
    -> defensive center-crop (failure mode #5)
    -> content-bbox crop
    -> PixelOE contrast-aware pixelize to the authoring grid (16/24/32; tiles strict 16)
    -> repo palette quantization (palette.py ramps)
    -> binary alpha cleanup
    -> NEAREST upscale to display size (authoring * scale)

Replaces the repo's documented corner-sampled color-key background removal
(gap-analysis failure mode #8: border-seeded flood-fill deletes edge-touching
subjects; corner-average keys fail on noisy backgrounds) with a real
segmentation model, and replaces naive NEAREST downscaling (which blurs or
crushes outlines) with PixelOE's contrast-aware expansion.
"""
from __future__ import annotations

import argparse
import sys
from io import BytesIO
from pathlib import Path

from PIL import Image

from palette import build_ramp_palette, quantize_image


def rembg_cutout(img: Image.Image, model: str = "u2net") -> Image.Image:
    """Stage 2: AI background matting to true alpha. No flood-fill, no color keys."""
    from rembg import remove, new_session

    session = new_session(model)
    buf = BytesIO()
    img.convert("RGBA").save(buf, "PNG")
    out = remove(buf.getvalue(), session=session)
    return Image.open(BytesIO(out)).convert("RGBA")


def center_crop_frac(img: Image.Image, frac: float) -> Image.Image:
    """Failure mode #5 defense: strip edge decoration unconditionally."""
    w, h = img.size
    cw, ch = int(w * frac), int(h * frac)
    left, top = (w - cw) // 2, (h - ch) // 2
    return img.crop((left, top, left + cw, top + ch))


def content_bbox(img: Image.Image, alpha_threshold: int = 16) -> Image.Image:
    """Tightest crop around non-transparent pixels."""
    alpha = img.getchannel("A")
    bbox = alpha.point(lambda p: 255 if p > alpha_threshold else 0).getbbox()
    if not bbox:
        return img
    return img.crop(bbox)


def pixeloe_downscale(img: Image.Image, grid_w: int, grid_h: int | None = None,
                      outline_thickness: int = 2) -> Image.Image:
    """Stage 3: PixelOE contrast-aware pixelize to the authoring grid.

    PixelOE expands contrast edges BEFORE downsampling, so silhouettes survive
    where naive NEAREST would crush them (failure mode #6's soft side). Runs on
    the opaque composite over white so cell colors stay clean; alpha is
    re-derived from the pre-pixelization matte afterwards (BOX-average +
    threshold = majority-opaque cells stay opaque).

    grid_h None -> square grid_w x grid_w. Legacy pixeloe (v0.1.4) API:
    pixelize(img_bgr, mode='contrast', target_size=(w,h), pixel_size=1) -> raw grid.
    """
    import numpy as np
    from pixeloe.legacy.pixelize import pixelize

    grid_h = grid_h or grid_w

    # composite over white for the weight/outline computation
    flat = Image.new("RGBA", img.size, (255, 255, 255, 255))
    flat.alpha_composite(img)
    rgb = np.asarray(flat.convert("RGB"))[:, :, ::-1].copy()  # RGB->BGR (cv2)
    px_arr = pixelize(
        rgb,
        mode="contrast",
        target_size=(grid_w, grid_h),
        patch_size=16,
        pixel_size=1,          # return the raw authoring grid, we upscale ourselves
        thickness=outline_thickness,
        color_matching=True,
    )
    px = Image.fromarray(px_arr[:, :, ::-1])  # BGR->RGB

    # re-derive alpha: a cell stays opaque if the majority of its source
    # pixels were opaque (BOX downscale + threshold)
    small_alpha = img.getchannel("A").resize((grid_w, grid_h), Image.BOX)
    px = px.convert("RGBA")  # single conversion; modify and return THIS image
    pa = px.load()
    sa = small_alpha.load()
    for y in range(grid_h):
        for x in range(grid_w):
            r, g, b, _ = pa[x, y]
            pa[x, y] = (r, g, b, 255) if sa[x, y] >= 128 else (r, g, b, 0)
    return px


def process(
    raw: Image.Image,
    grid: int = 16,
    grid_h: int | None = None,
    scale: int = 3,
    center_frac: float = 0.75,
    is_tile: bool = False,
    palette=None,
    thickness: int = 2,
) -> Image.Image:
    """Full stage 2+3. Tiles skip bbox crop (must stay full-bleed seamless)."""
    if is_tile:
        # block-first: no background removal, no bbox — quantize + pixelize full-bleed
        px = pixeloe_downscale(raw.convert("RGB").convert("RGBA"), grid, grid_h, thickness)
    else:
        cut = rembg_cutout(raw)
        cut = center_crop_frac(cut, center_frac)
        cut = content_bbox(cut)
        # normalize longest side to a fixed box so `grid` is the true output width
        px = pixeloe_downscale(cut, grid, grid_h, thickness)
    px = quantize_image(px, palette)
    if scale > 1:
        px = px.resize((px.width * scale, px.height * scale), Image.NEAREST)
    return px


def main() -> int:
    ap = argparse.ArgumentParser(description="Stage 2+3: cutout + pixelize + palette")
    ap.add_argument("input")
    ap.add_argument("output")
    ap.add_argument("--grid", type=int, default=16, help="authoring grid width (tiles: 16 strict)")
    ap.add_argument("--grid-h", type=int, default=None, help="authoring grid height (default: square)")
    ap.add_argument("--scale", type=int, default=3, help="NEAREST display scale (repo TILE=48 -> 3x)")
    ap.add_argument("--center-frac", type=float, default=0.75)
    ap.add_argument("--thickness", type=int, default=2, help="PixelOE outline expansion thickness")
    ap.add_argument("--tile", action="store_true", help="seamless tile mode (block-first, full-bleed)")
    ap.add_argument("--skip-rembg", action="store_true", help="input already has alpha")
    ap.add_argument("--model", default="u2net", help="rembg segmentation model")
    args = ap.parse_args()

    raw = Image.open(args.input)
    if args.tile:
        out = process(raw, args.grid, args.grid_h, args.scale, is_tile=True, thickness=args.thickness)
    elif args.skip_rembg:
        cut = content_bbox(center_crop_frac(raw.convert("RGBA"), args.center_frac))
        px = pixeloe_downscale(cut, args.grid, args.grid_h, args.thickness)
        px = quantize_image(px)
        out = px.resize((px.width * args.scale, px.height * args.scale), Image.NEAREST) if args.scale > 1 else px
    else:
        out = process(raw, args.grid, args.grid_h, args.scale, args.center_frac, thickness=args.thickness)

    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    out.save(args.output)
    colors = out.getcolors(maxcolors=100000)
    print(f"OK {args.output}: {out.size[0]}x{out.size[1]}, {len(colors) if colors else '>100k'} colors")
    return 0


if __name__ == "__main__":
    sys.exit(main())
