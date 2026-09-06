# tools/pixel_pipeline — AI art pipeline (ComfyUI → rembg → PixelOE)

Owner-directed 5-skill pipeline (2026-09-06) complementing the existing
Draw Things queue (see `docs/art/pixel_art_pipeline.md` for the manual
pipeline and its gap analysis — read that first; the failure-mode defenses
here are inherited from it).

## Stages

| # | Skill | Tool | What it does here |
|---|-------|------|-------------------|
| 1 | AI Concept Generation | ComfyUI (local, API mode) | SD1.5 txt2img concept renders; pixel-art LoRA slot; prompts pre-defended against pipeline failure modes #3/#4/#7/#9/#10 |
| 2 | Background Isolation | rembg (u2net) | True alpha matting — replaces corner-key/flood-fill bg removal (fixes failure mode #8 class bugs) |
| 3 | Grid Alignment & Pixelation | PixelOE | Contrast-aware downscale to the 16px authoring grid without blurring/crushing outlines |
| 4 | Sprite Animation & Editing | LibreSprite (/Applications) | Manual onion-skin polish of keyframes; variant derivation (hue-shift) is scripted in `palette.py` |
| 5 | Autotiling & Map Assembly | Tiled 1.12 (/Applications) | Terrain bitmask rules for the 16-tile blob set; CLI validation via `tiled --export-map`; render previews via `tmxrasterizer` |

## Grid contract (repo canon)

Authoring grid 16×16 (tiles: strict, no exceptions) → NEAREST ×3 → 48×48
in-game (`TILE=48` in `WorldRender.gd`). Characters 16×24 → 48×72. Compound
objects may step up to 24/32 per the owner amendment. Palette quantization
targets the 16 named role ramps in `ART_STYLE_GUIDE.md` (`palette.py`).

## Usage

```bash
PY=~/.venvs/artpipe/bin/python
# one asset (concept PNG -> 48x48 repo-ready sprite):
$PY tools/pixel_pipeline/pixelate.py raw.png out.png --grid 16 --scale 3
# seamless tile:
$PY tools/pixel_pipeline/pixelate.py raw.png tile.png --grid 16 --scale 3 --tile
# from a running ComfyUI (http://127.0.0.1:8188):
$PY tools/pixel_pipeline/generate.py --subject "clay stove on a wooden bench" --out /tmp/stove.png
```

## Status

- [x] rembg + PixelOE installed and smoke-tested
- [x] Tiled 1.12.2 + tmxrasterizer (brew cask)
- [x] LibreSprite 1.0 (/Applications, GitHub release arm64 build)
- [x] ComfyUI cloned to ~/ComfyUI, deps installed; needs an SD1.5-class
      checkpoint in `~/ComfyUI/models/checkpoints/` (8GB RAM machine —
      fp16 v1-5 recommended) before stage 1 runs
