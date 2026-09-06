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
# non-square authoring grid (characters 16x24 -> 48x72):
$PY tools/pixel_pipeline/pixelate.py raw.png out.png --grid 16 --grid-h 24 --scale 3
# seamless tile (block-first; prints a seam metric gate):
$PY tools/pixel_pipeline/pixelate.py raw.png tile.png --grid 16 --scale 3 --tile --thickness 0
# from a running ComfyUI (http://127.0.0.1:8188):
$PY tools/pixel_pipeline/generate.py --subject "clay stove on a wooden bench" --out /tmp/stove.png
# Tiled terrain demo: 16-combo blob tileset from two base tiles + 20x16 map + preview
$PY tools/pixel_pipeline/make_terrain_demo.py --grass tile_grass.png --water tile_water.png --out /tmp/terrain_demo
# validate a .tmx against repo canon gates (20x16, 48px):
$PY tools/pixel_pipeline/tiled_validate.py map.tmx
```

## Status

- [x] rembg + PixelOE installed and smoke-tested
- [x] Tiled 1.12.2 + tmxrasterizer (brew cask)
- [x] LibreSprite 1.0 (/Applications, GitHub release arm64 build)
- [x] ComfyUI cloned to ~/ComfyUI, deps installed, SD1.5 fp16 checkpoint
      downloaded; stage-1 CPU render verified end-to-end
- [x] Stage 2+3 validated: 48x48 sprite w/ true alpha, 11 colors; 48x72
      character grid; block-first tile path with seam gate
- [x] Stage 5 validated: 16-combo corner-wang terrain, .tmx passes
      `tiled_validate.py`, tmxrasterizer preview, Tiled CLI JSON roundtrip
      (see `docs/art/pixel_pipeline_validation/`)
- [ ] Batch production runs (blocked on owner art-direction call)
- Note: 16-tile corner format cannot round small features' shores — use the
  47-tile blob format when diagonal shore transitions are needed.

