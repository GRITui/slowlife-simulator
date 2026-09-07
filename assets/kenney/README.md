# Kenney art source packs (imported 2026-09-07)

Three CC0 (public domain) Kenney packs, imported raw for the full art-style
replacement tracked as `TASK-321` in `backlog.json`. Each subfolder keeps the
pack's own `LICENSE.txt`, `Tilesheet.txt`, `Preview.png` (full sheet sample),
`Tiles/` (individual 16x16 PNGs, easiest to reference by name), and
`Tilemap/` (packed sheet, for TileSet atlas import).

Native tile size is **16x16px**; the shipped grid is **48x48px** (see
`ART_STYLE_GUIDE.md`). Scale factor is **3x** — apply via node `scale` or
TileSet pixel size, not by pre-upscaling the PNGs (keeps nearest-neighbor
crisp, matches how the rest of the project's pixel art is handled).

## tiny_farm/ — primary source for terrain, crops, farm objects, animals

- Terrain: grass, tilled soil (multiple wetness stages), dirt path, wood
  plank floor, fences
- Crops: carrot, tomato, cabbage, pumpkin, corn, wheat — each with multiple
  growth-stage tiles
- Objects: crates, barrels, tools, well, sign, watering can
- Buildings: barn (two roof colors), silo
- Animals: sheep, cow, chicken
- Character: one static ~16x16 farmer icon only — **no walk-cycle, no
  directional frames**. Not sufficient alone for the player sprite.

## tiny_dungeon/ — source for character/NPC frames + small items

- Characters: knight, mage, rogue, villager, several NPC/monster variants —
  each a **single static front-ish-facing frame**, no animation frames.
- Items: potions, weapons, shields, keys.
- Also has dungeon-specific terrain/props (not needed for this farm game).

## tiny_town/ — source for buildings/structures + trees

- Terrain, trees/bushes, stone & brick building walls, roofs, doors, arches,
  fences, tools. No characters.

## Known gap: player character animation

None of the three packs contain a multi-frame directional walk-cycle like
the current custom `player_walk_*` sprites (48x72, 4-directional, animated).
Decision made 2026-09-07 with the project owner: use a single `tiny_dungeon`
character frame for the player, **horizontally flipped for left/right
facing, same frame reused for up/down** — directional facing without a real
walk-cycle. See `TASK-321` for the wiring scope.

## What this commit does NOT do yet

This commit only imports and documents the raw source packs. It does not
yet re-wire `assets/tilesets/`, `assets/characters/`, `assets/environment/`,
scenes, or `ART_STYLE_GUIDE.md`. That's the full-replace wiring work,
tracked as `TASK-321` — routed through the normal backlog/test-gate process
per this repo's `CLAUDE.md` rather than done ad hoc, since it touches the
locked palette, the y-sort perf budget (48/48, zero headroom per
`PO_INBOX.md`), and dozens of already-tested scenes.
