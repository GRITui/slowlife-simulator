# Art Design Plan — 5-skill pipeline applied to slowlife-simulator

Status: DRAFT on branch `art/pixel-pipeline-v1` — **not for merge to main until
the owner calls it.** Companion to `docs/art/pixel_art_pipeline.md` (the
16-bit pipeline + gap analysis). This plan maps the five newly-equipped skills
onto that pipeline and onto the remaining art batches in
`ops/art-asset-redesign-plan.md`.

## Skill → pipeline stage mapping

| Stage | Skill | Local install | Replaces / adds |
|---|---|---|---|
| 1. Concept generation | ComfyUI 0.34 (API mode, headless) | `~/ComfyUI` + SD1.5-fp16 | Alternative to the iPad Draw Things queue; same prompt failure-mode defenses apply |
| 2. Background isolation | rembg (u2net) | `~/.venvs/artpipe` | Replaces flood-fill / corner-key bg removal entirely (documented failure mode #8 class) |
| 3. Grid alignment & pixelation | PixelOE (contrast-aware) | `~/.venvs/artpipe` | Upgrades plain NEAREST downscale — expands contrast outlines BEFORE the 16× downsample |
| 4. Sprite animation & editing | LibreSprite 1.0 | `/Applications` | Manual keyframe polish / onion-skinning; scripted variant derivation lives in `palette.py` |
| 5. Autotiling & map assembly | Tiled 1.12 (+ CLI + tmxrasterizer) | `/Applications` | NEW capability: terrain bitmask autotiling + .tmx gate validation (no equivalent existed) |

Tooling lives in `tools/pixel_pipeline/` (see its README for usage).

## Grid & palette contract (repo canon, unchanged)

- Authoring grid: 16×16 strict for tiles; 16×24 for characters; 24/32 for
  compound props (owner amendment). NEAREST ×3 → 48px in-game display (`TILE=48`).
- Palette: quantize to the 16 named role ramps from `ART_STYLE_GUIDE.md`
  (`palette.py` builds highlight/base/shadow per role; 8–12 colors per asset).
- Binary alpha only — hard pixel edges, no AA fringe.

## What is already proven working (this branch, validated)

1. Stage 2+3 end-to-end: raw concept → u2net alpha matting → center-crop →
   content-bbox → PixelOE 16×16 → palette quantize → NEAREST ×3 =
   48×48 sprite, 11 colors, ~21% true transparency.
2. Stage 1 end-to-end on CPU: ComfyUI API txt2img with the defended prompt
   template (slow on 8GB/CPU — ~90s/step; run detached, or use the iPad Draw
   Things queue for batch work and this for single validation renders).
3. Stage 5: 16-combo blob terrain (grass/water corner wang) generated from two
   base tiles, .tmx passes `tiled_validate.py` gates (20×16, 48px), renders
   via tmxrasterizer, exports to JSON via Tiled CLI.

## Proposed application to remaining batches (from ops/art-asset-redesign-plan.md)

| Batch | Files | Approach |
|---|---|---|
| 7. Crops (growth stages) | ~84 | One clean generation per crop stage-1 stage → hue/scale-derive other stages locally (`palette.shift_hue`); stages 2–4 pattern already proven in the repo |
| 8. Items | ~155 | Outline-first 16×16; failure modes #4–#6 defenses from the start (`center_crop_frac`, bold-shapes language); rembg removes the #8 mangle class |
| 9. Character sprites | ~87 | Needs the keyframe decision flagged in the pipeline doc: generate one base keyframe (16×24) → animate in LibreSprite with onion-skinning → derive walk frames; Tiled-independent |
| Terrain/autotiling | — | NEW: blob-terrain tilesets authored in Tiled with corner terrain rules; 47-tile blob format available later if diagonal transitions ship |

## Known risks / notes

- 8GB RAM machine: ComfyUI runs CPU-only here (SD1.5 fits; SDXL does not).
  Keep checkpoint fp16; close other apps for batch runs.
- PixelOE kills thin features at 16× (thin ripples died in testing) — same
  lesson as repo failure mode #6: bold shapes in concepts; detail ON the
  16-grid afterwards, not before.
- rembg u2net occasionally keeps full-canvas masks on noisy/no-saliency
  inputs; verify alpha% per asset (gate: transparent% > 0 for icons).
- u2net.onnx must be fully downloaded before first use — a truncated model
  returns all-opaque masks silently (hit & diagnosed during setup).
- Tiled legacy terrain attrs survive .tmx/.tsx but not the CLI JSON export —
  terrain brushing happens in the Tiled GUI; JSON export is for engine import.
