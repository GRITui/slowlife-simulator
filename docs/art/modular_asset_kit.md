# Modular Asset Kit Convention

Owner direction (2026-09-05): stop generating one bespoke Draw Things image
per object. Build a small set of shared **base** textures, then derive
variants from them with cheap local recolor/retrim (PIL) instead of a new
paid generation per object — same idea as flat-pack furniture: a handful of
parts (panel, plank, trim, cap) that recombine into many finished pieces.

## Why

- Every new prop this session so far (`wooden_chair.png`, `wooden_bench.png`,
  `transistor_radio.png`, `wall_portrait.png`, `garden_bush.png`,
  `garden_flowers.png`, the interior floor/wall textures) was its own
  Draw Things round trip — real compute cost, and each one is a fresh shot
  at the model that can drift in palette/style from its neighbors.
- The interior floor/wall "tone it down" request today was solved with a
  single local PIL pass (desaturate + reduce contrast + resize) on the
  *existing* generated images, not a regeneration — same output quality,
  zero extra Draw Things calls. That's the pattern to generalize.

## The kit shape

1. **Base textures** (generate once, reuse everywhere): a plain wood-plank
   panel, a woven-bamboo/mat panel, a plain stone/clay panel, a plain cloth
   panel. These are the `farmhouse_floor.png` / `farmhouse_wall_interior.png`
   pair already shipped — treat them as the first two kit pieces, not
   one-offs.
2. **Trim/accent pieces** (small, generate once): a corner cap, an edge
   plank, a joint/seam strip. Composited (Pillow `Image.paste` with alpha,
   or a Godot `NinePatchRect`/tiled `Sprite2D` pair) onto a base panel to
   read as a distinct object — a crate vs. a market-stall counter vs. a
   fence post can share the same wood-panel base with different trim.
3. **Variants via local processing, not regeneration:**
   - Recolor: `ImageEnhance.Color` / a direct HSV hue-shift (PIL
     `Image.convert("HSV")`, roll the H channel) to get a "painted red
     shutter" from a "plain wood shutter" base.
   - Tone: `ImageEnhance.Contrast`/`Brightness` — exactly what was just
     used to calm the interior floor/wall from their first generation.
   - Wear/age: a light noise or darken-multiply pass for "weathered" vs.
     "new" without a second model call.

## Where to apply this next (candidates, not yet done)

Ordered by how much bespoke-generation duplication they'd currently save:
- **Exterior fences/posts** (`assets/environment/` — check for existing
  fence art first; likely candidate for a plank-base + post-trim kit).
- **Market/trading-post stall variants** (`market_stall.png` and similar —
  several buildings currently reuse one texture uncomfortably; a base
  counter panel + per-vendor trim/awning-color variant would fit better
  than either reuse-as-is or a fresh generation per stall).
- **Crates/storage props** — a single wood-panel base + metal-band trim
  overlay covers crate/barrel/chest variants.
- **Garden props** (`garden_bush.png`/`garden_flowers.png`, shipped today)
  — could become a base pot/planter + swappable foliage-color trim instead
  of two fully separate generations, if more planter variants are needed
  later.

## Rule going forward

Before dispatching a new Draw Things generation for *any* prop: check
whether an existing base texture in `assets/environment/` or
`assets/tilesets/` gets there with a PIL recolor/retrim pass instead. Only
generate fresh when no existing base is structurally close (a genuinely new
silhouette, not just a new color/texture).
