# Kenney art source packs (imported 2026-09-07)

Six CC0 (public domain) Kenney packs, imported raw for the full art-style
replacement tracked as `TASK-321` in `backlog.json`: three world/character
packs (`tiny_farm`, `tiny_dungeon`, `tiny_town`) plus three UI/icon packs
(`emotes`, `game_icons`, `ui_rpg`) added the same day to cover HUD, menus,
and dialogue reactions. Each world-pack subfolder keeps the
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

## emotes/ — speech-bubble / reaction icons (added 2026-09-07)

`Pixel/Style 1`...`Style 8/` — 8 pixel-art emote sets, 30 icons each, native
16x16px (matches the tile packs' scale, unlike the pack's Vector variants
which were skipped). Use for NPC mood bubbles, quest markers, dialogue
reactions (anger, alert, cash, heart, question mark, sleep, etc.). Pick one
style set for consistency rather than mixing across styles.

## game_icons/ — generic UI/inventory icon set (added 2026-09-07)

`PNG/Black/1x`, `PNG/White/1x` (50x50) and `.../2x` (100x100) — 105 icons
each color/scale, plus `Spritesheet/` packed atlases with XML metadata.
General-purpose icons (arrows, gear, heart, coin, bag, tools, etc.) for menus,
inventory slots, settings. Not farm-themed — this is the "everything else"
icon fallback pool alongside `ui_rpg/`.

## ui_rpg/ — RPG UI widgets (added 2026-09-07)

`PNG/` — 87 native-sized widgets: buttons (long/round/square, per-color +
pressed states), panels (incl. inset), stat bars (blue/green/red/yellow,
horizontal + vertical, with matching `barBack_*` frames — good fit for
health/stamina/hunger bars), arrows, cursors (hand/sword/gauntlet), and
check/cross/circle icons. `Spritesheet/` has the packed atlas + XML.
Maps directly onto the existing `assets/ui/` needs (hearts, buttons, panels).

## tiny_battle/ — water tile source (added 2026-09-07)

`Tiles/` — 198 tiles, **18x11 grid** (wider than the other packs' 12x11 —
don't reuse the standard `idx = row*12+col` math here, it's `row*18+col`).
Imported specifically to fix a gap: none of the other six packs contain a
real water tile, so pass 1 of `TASK-321` had used flat procedural-color
fallbacks for `assets/tilesets/canal.png`, `water_surface.png`, and
`water_lotuspond.png`. `tiny_battle/Tiles/tile_0037.png` (row 2, col 1 —
open lake water, no shoreline blending, confirmed via indexed-grid
inspection) now backs all three, 3x nearest-neighbor scaled like every
other tileset. Rest of the pack (roads, RTS-style unit/building icons,
faction-colored vehicles) is not used — kept for potential future
water-adjacent tiles (shore/dock edges) if needed.

## What this commit does NOT do yet

This commit only imports and documents the raw source packs. It does not
yet re-wire `assets/tilesets/`, `assets/characters/`, `assets/environment/`,
scenes, or `ART_STYLE_GUIDE.md`. That's the full-replace wiring work,
tracked as `TASK-321` — routed through the normal backlog/test-gate process
per this repo's `CLAUDE.md` rather than done ad hoc, since it touches the
locked palette, the y-sort perf budget (48/48, zero headroom per
`PO_INBOX.md`), and dozens of already-tested scenes.
