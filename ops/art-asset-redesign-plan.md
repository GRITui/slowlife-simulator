# Art asset redesign — batch plan

Full-game visual redesign, dispatched to the Draw Things queue (iPad M2,
`tools/drawthings_queue_runner.py`) **one category batch at a time** —
serialized on purpose (Draw Things drops a second concurrent request) and
reviewed batch-to-batch rather than dumped all at once, so a bad prompt
template gets caught before it burns hours of generation on the whole
category. Owner instruction 2026-09-04: "Queue all assets batch by batch."

Counts below are real image files only (`.import` metadata and `.tres`
particle resources excluded — those aren't image-generation targets).

## Batch status

| # | Category | Files | Status |
|---|---|---|---|
| 1 | NPC/animal portraits (part 1) | 6 (elder, child, handler, monk, trader, buffalo) | DONE (2026-09-03) |
| 2 | NPC/animal portraits (part 2) | 7 (fah, headman, niran, vet, somchai, nong_ton, monkey) | DONE (2026-09-05, all 7 in assets/ui/portraits/) |
| 3 | UI bars/frames + hearts/icons | 10 (action_prompt, crop_progress_bar_fill/under, energy_bar, harmony_bar, inventory_slot, season_display, heart_empty/full, silver_coin) | DONE (2026-09-05) — heart_empty/full/silver_coin needed a re-gen (first pass's Draw Things output wasn't real alpha, baked-in background) + local flood-fill removal, not a straight copy-in like the other 7 |
| 4 | Tilesets | 9 (canal, ground_dryearth/grass/ricepaddy, plantable_soil, structure_floor/wall, water_lotuspond/surface) | DONE (2026-09-05) — see caveats below |
| 5 | Environment (festival + props) | 3 (merchant_cart, wing_kwai_flag, wing_kwai_official_stand) | pending |
| 6 | Environment (general, ~25 files) | ~25 (bamboo/banana/durian trees, dock, clay stove, etc.) | pending |
| 7 | Crops (growth stages, ~84 files) | ~84 | pending, large — may need its own sub-batches |
| 8 | Items (~155 files) | ~155 | pending, large — may need its own sub-batches |
| 9 | Characters (sprites, ~87 files) | ~87 | pending, large — sprite sheets, not single portraits; needs its own prompt approach (multi-frame, not single bust) |

## Process per batch
1. Write `tools/drawthings_queue/pending/*.json` prompt files for the batch.
2. Run `python3 tools/drawthings_queue_runner.py` (or let the n8n-triggered
   run pick it up).
3. Spot-check `done/*.png` outputs before queuing the next batch — catches
   model quirks (e.g. the confirmed FLUX.1-Kontext literal-prompt-reading
   issue) early.
4. Update this table's Status column.

## Model note (2026-09-04): FLUX.1 [schnell] under consideration

Owner is evaluating a switch from the current FLUX.1 Kontext checkpoint to
FLUX.1 [schnell] for speed (4 steps vs. 20-30) on the M2 iPad's memory
budget. `tools/drawthings_queue_runner.py` now supports the schnell-specific
payload fields (`cfg_scale`, `sampler_name`, `shift`, `zero_negative_prompt`)
as OPT-IN per-prompt-file overrides — see that script's module docstring.
**This is a code-level readiness change only.** The actual model swap
happens inside the Draw Things app on the iPad itself; nothing here
switches it automatically. Do not set the schnell-tuned fields on any
prompt file until the loaded checkpoint is actually confirmed as schnell —
its 4-step/cfg~1.0 regime is tuned for that specific distillation and will
produce broken output against Kontext.

If/when the switch happens, write prompts (Stage 8's construction step
wherever that lives — an n8n workflow if one exists, or by hand as today)
as natural-language descriptive paragraphs rather than comma-separated tag
lists — schnell responds much better to sentences than to SDXL-style tag
soup. E.g. prefer "A cozy hand-drawn cottage in a forest, slowlife indie
game style, clean lines, vibrant colors" over "masterpiece, best quality,
8k, house". This is in addition to, not a replacement for, the existing
literal-prompt-reading caution already noted below for Kontext.

## Batch 4 caveats (2026-09-05)

At schnell's 4-6 step regime, several tileset prompts didn't produce a
usable result on the first pass and needed 1-2 retries with stronger
prompts/negative-prompts, plus two (`plantable_soil`, `water_surface`)
were ultimately salvaged with local PIL processing (hue-shift, crop+tile)
rather than a clean generation — logged here rather than silently
shipped as if they were straightforward:
- `plantable_soil`: first pass added plants/sky/perspective it was told
  not to; second pass came out looking like glowing lava. Final version
  is the lava pass hue-shifted from red to brown locally.
- `water_surface`: two generation passes came out as flat color bands /
  a mosaic pattern, not water. Final version is a crop of a clean
  rippled-water region from one of those passes, tiled/resized.
- `ground_ricepaddy` shipped with a real caveat: the generation reads as
  a perspective/receding-rows shot rather than a flat top-down tile like
  the rest of the set. Usable (clear improvement over the flat placeholder)
  but a candidate for a follow-up regen if it looks off in-engine.
- `canal` is on the dark/murky side of the palette — acceptable but also
  a candidate for a lighter follow-up pass if it reads too dark in-game.

## Notes
- Batches 7-9 are large enough that they should be split into sub-batches
  of similar size to batches 1-6 (roughly 5-15 images) rather than queued
  as one giant drop, to keep the review checkpoint meaningful.
- Batch 9 (character sprites) needs a different prompt strategy than the
  portrait batches — these are multi-frame walk/idle sheets, not single
  bust portraits, and Draw Things' single-image txt2img endpoint doesn't
  natively produce a sprite sheet — needs a design decision before
  dispatch, not just a prompt list. Flag this to the owner when reached.
