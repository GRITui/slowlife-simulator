# ART STYLE GUIDE: Thai Rural Countryside Sim

> **✓ Superseded 2026-09-07 — Kenney CC0 art-style replacement (`TASK-321`)**
> The soft-shaded custom palette/pipeline below (2026-08-31 Claude Design
> redesign) was fully replaced with Kenney CC0 asset packs, per owner
> decision. Tile metrics (48x48 grid, 48x72 characters, y-sort rules) are
> unchanged — only the source art and its sourcing/curation process changed.
> See **"Kenney CC0 Art Source (2026-09-07, supersedes palette above)"**
> near the end of this file for the current, load-bearing pipeline
> documentation. The palette table and soft-shading rules below are kept for
> historical reference only — do not use them to judge current art.

## Core Palette — soft-shaded, ~70 colors (Claude Design redesign, 2026-08-31)

> **✓ Superseded 2026-08-31** — The Claude Design redesign pass replaced every
> character/environment/tileset asset with softly-shaded art: measured directly
> from the shipped PNGs, the set now uses **73 unique opaque colors with zero
> exact matches** to the old flat 16-hex lock below. Shading is achieved with
> blended intermediate tones (highlight/base/shadow per hue), not a fixed
> per-pixel palette, so the old "enforced per-scene max 16" rule no longer
> applies. The 16 named roles still describe *where* each hue family is used —
> only the literal hex enforcement is gone. Anchor hexes below are the highest
> pixel-count representative for each role, measured across all of `assets/`.

| Color | Anchor Hex | Usage |
|-------|-----|-------|
| Rice White | #F2E6C4 | Background, cloth highlights |
| Jasmine Gold | #E0A23A | Sunlight, highlights |
| Pandan Green | #4F8A3D | Rice fields, vegetation base |
| Grass Green | #7FAE46 | Lighter grass, foliage highlight |
| Lotus Pink | #E08AA0 | Flowers, harmony |
| Clay Brown | #6A4A30 | Clay stove, mortar, dark wood |
| Ink Outline | #2B1C14 | Character/prop outlines, base shadow |
| Deep Shadow | #241A12 | Darkest shadow tone |
| Pha Khao Ma Gray | #B8B0A0 | Clothing, rope |
| Monsoon Blue | #3D5F80 | Rainy season, deep water |
| Canal Teal | #5FB6C9 | Canal/pond water mid tone |
| Hot Orange | #C9622F | Sun, heat accents |
| Skin/Wood Warm | #D99A68 | Skin tones, warm wood grain |
| Deep Navy | #274259 | Deepest water, night shadow |
| Dark Cloth | #3F3E40 | Dark cloth/shadow accents |
| Soil Tan | #D8C9A0 | Dry earth, plantable soil light |

**Rules**: 16 named hue-role anchors, each rendered with its own soft shading ramp (blended highlight → base → shadow) rather than a single flat hex. Warm for sunlight, cool for shade/water — unchanged from the original direction. Seasonal tinting still applied globally on top.

> **✓ Locked 2026-08-31 — Hybrid A/B (Isan Plain + Canal Maze)** — Flat 20×16 paddy grid (A) + single canal-maze water feature from B (lotus maze + dock/raft + sluice gate + canal tile + mango). See `ART_WORLD_VISION_V2.html#decision` and `.decision.json` for the world-layout decision (palette section above is now maintained separately, following the art redesign).

## 3/4 Perspective Art Rules (Canon REV 2 — locked 2026-08-31)

**Decision**: Option B (3/4 perspective) selected over top-down (see `docs/art_direction/perspective_A_B_comparison.png`). Implementation is "3/4 via art + Y-sort" — **NO camera squash**. Orthographic Camera2D hard center-locked on Player (issue #5 REV 2).

### Tile Metrics

> **✓ Resolution bump 2026-08-31** — Base tile 32x32 → **48x48** (1.5x) following the
> Claude Design art redesign pass. Characters, tilesets, environment props all
> upscaled 1.5x in lockstep (`TILE` in WorldRender.gd, `cell_size` in GridManager.gd,
> Player clamp/interact-cell math, spawn coordinates, collision shapes). UI bar/prompt
> art in `assets/ui/` was redesigned independently and is not yet wired into HUD.tscn,
> so it carries its own dimensions and is not part of this scale.

- **Ground**: flat 48x48 top-down tiles (existing tilesets unchanged in ratio, upscaled 1.5x)
- **Verticals** (walls, trees, standing props): tall art with front faces
- **Characters**: 48x72 front-facing sprites (was 32x48)

### Tall Art Spec (supersedes 48x48 base for verticals)

| Asset | Size | Notes |
|-------|------|-------|
| bamboo_wall_tall | 48x96 | Front face + green cap, edge ring |
| structure_wall_front | 48x48 | Hut/temple/hall/toolshed facades |
| structure_wall_cap | 48x24 | Roof cap |
| mango_tree | 48x72 | Trunk + canopy |
| banana_circle | 48x48 | — |
| sluice_gate | 48x48 | Repairable infrastructure |
| clay_stove | 48x48 | — |
| dock/raft | 48x48 | Stays flat — on water |

### Y-Sort Rules

- Standing sprites + characters share one Y-sorted layer; sort origin at feet/base
- Ground/water/crops render below the Y-sorted layer
- Player renders behind walls/trees when above, in front when below

### Camera & Zoom

- Player pinned to exact screen center (drag margins OFF, position smoothing OFF)
- **Zoom 2.2 provisional** (12.9 rows visible, bamboo ring frames both sides) — final lock at TASK-008 with real tall art
- Palette unchanged (16-color Hybrid A/B)

### References

- `docs/art_direction/canon_34_draft_B.png` (canon target)
- `docs/art_direction/archived_topdown_option_A.png` (archive)
- `docs/art_direction/zoom_framing_comparison.png`
- GitHub issue #5 REV 2

## Tile Set Specifications

- **Base size**: 48x48 pixels (16x16 → 32x32 → 48x48; resolution bump 2026-08-31, see Tile Metrics above)
- **Grid**: Top-down staggered grid, offset (24, 12)
- **Categories needed**: Ground, Environment, Structures, Interactive, Decor
- **Animations**: Crop growth (4 frames), water flow (3-frame loop), wind vegetation (subtle shift)
- **Naming convention**: `tilesets/ground_ricepaddy.png`, `tilesets/water_lotuspond.png`, etc.
- **Note (REV 2)**: verticals (walls, trees, standing props) are superseded by the tall-art spec in "3/4 Perspective Art Rules (Canon REV 2)" above — ground tiles remain 48x48
## Environmental Assets

### Core Thai Rural Elements

| Asset | Description |
|-------|-------------|
| Clay Stove | Central cooking hearth, wood fire animated |
| Lotus Pond | Water feature with pink lotus flowers, green lily pads |
| Rice Paddy | Primary crop field, rice stalks at growth stages |
| Bamboo thicket | Natural boundary, tall bamboo stalks |
| Banana circle | Garden area, banana plants in clusters |
| Mo Hom cloth | Traditional maroon patterned fabric |
| Pha Khao Ma | Gray checkered traditional skirt/robe |
| Buffalo | Water buffalo, grazing animation, can be fed |

### Hybrid A/B — Locked World Add-ons (2026-08-31)

| Add-on | Description | Source |
|--------|-------------|--------|
| Lotus Maze Pond | Small canal-loop islet inside the plain, 3×3 lotus maze for Monsoon Lotus Root harvest | B |
| Canal Dock + Raft | Stilt-side dock + ferry raft (visual, no nav yet) | B |
| Sluice Gate | Repairable infrastructure on maze edge → unlocks Pandan seed (Reverse pillar) | B |
| Mango Tree | Single late-unlock tree at maze corner | B |

**World Layout (Hybrid A/B):**

```
[bamboo wall][  lotus pond (NW)  ][temple lane → E]
[ buffalo pasture (S) ][  20×16 rice paddies (center, flat)  ][ home + toolshed ]
[ banana circle ][ well ][ village hall ]   +  lotus maze islet (3×3) inset at paddy SE
[dock/raft][sluice gate][mango tree]  (maze add-ons)
```

### Seasonal Variations

| Season | Color Tint | Changes |
|--------|-----------|---------|
| Monsoon | Blue-ish (20%) | Water everywhere, lush green, rain particles |
| Hot | Orange tint (25%) | Dry grass, cracked earth, golden sunlight |
| Cool | Teal tint (15%) | Lush but mild green, clear skies, harvest full |
## Character Design Guidelines

### Player Character (Farmer)
- **Size**: 48x72 pixels sprite (was 32x48 pre-redesign); collision shape 21x30
- **Color scheme**: Mo Hom maroon accents, Pha Khao Ma gray elements
- **Animations needed**: Idle (4 frames), Walk (8 frames), Hoe/plant (4 frames), Harvest (4 frames), Carrying crop
- **Palette**: Maroon (Mo Hom) + Gray (Pha Khao Ma #B8B0A0) + skin tone #D99A68

### NPC Design
- **Village Elder**: Traditional Thai hat, walking stick, warm colors
- **Child NPC**: Smaller sprite, carrying basket or toy
- **Buffalo Handler**: Traditional outfit, leading buffalo
- **Temple Priest**: Orange/ saffron robes, calm expression

### Animation Frame Counts
- **Idle**: 4 frames (loop, subtle breathing)
- **Walk**: 8 frames (loop, alternating leg movement)
- **Action** (hoe, harvest, cook): 4 frames (one-shot)
## UI Design Specifications

### Core Principles
- **SignalBus-driven**: All UI updates via signalbus architecture
- **Minimal clutter**: Hide unnecessary elements, focus on essential info
- **Cozy aesthetics**: Rounded corners, soft shadows, warm colors
- **Scalable**: PC (default 100%) & Mobile (scale down 80%)

### Required UI Elements

| Element | Size | Design Notes |
|---------|------|--------------|
| Energy Bar (`assets/ui/energy_bar.png`) | 128x28 | Green→Yellow→Red gradient, SignalBus: `player/energy_changed` |
| Crop Progress | 150x12 | Bar showing growth stage, current crop icon — not yet delivered as a redesigned asset |
| Village Goodwill (`assets/ui/harmony_bar.png`) | 128x28 | Heart icons or harmony symbols, SignalBus: `village/goodwill_changed` |
| Season Display (`assets/ui/season_display.png`) | 128x32 | Text + small seasonal icon (Monsoon/Hot/Cool) |
| Inventory Slot (`assets/ui/inventory_slot.png`) | 48x48 | Border when empty, item icon when filled |
| Action Prompt (`assets/ui/action_prompt.png`) | 48x48 | Bottom-center, "Press E to harvest" etc. |

> **Note**: these five PNGs were redesigned at their own new dimensions (not the
> 1.5x world-tile scale above — UI is screen-space, not world-space) but are
> not yet wired into `HUD.tscn`, which currently renders bars/prompt via plain
> `ProgressBar`/`ColorRect` nodes. Wiring them in is unstarted follow-up work.

### UI Color Usage
- **Background**: Rice White (#F2E6C4) with 90% opacity
- **Accents**: Jasmine Gold for positive, Lotus Pink for harmony/bonus
- **Text**: Mo Maroon for headings, Pandan Green for subtitles
- **Borders**: Clay Brown (#6A4A30) 1px rounded

### Font Recommendations
- **Primary**: Clean pixel font with Thai script support
- **Size**: 12px body, 16px headings, 20px menus
- **Color**: Dark text on light background (contrast 4.5:1 minimum)
## Seasonal System Visuals
## Godot 4 Project Structure

### Recommended Directory Layout
```
/project/
  .godot
  assets/
    tilesets/       # ground_ricepaddy.png, water_lotuspond.png, etc.
    characters/     # farmer_idle_01-04.png, buffalo_grazing_01-04.png
    environment/    # clay_stove.png, lotus_pond.png, banana_circle.png
    ui/             # energy_bar.png, inventory_slot.png, etc.
    fonts/          # pixel_font.ttf (Thai script supported)
    audio/          # ambient sounds, cooking sfx
  src/
    scenes/         # main.tscn, player.tscn, village.tscn
    scripts/
      gameday.gd    # Season/day/night cycle implementation
      signalbus.gd  # Central signalbus singleton
      player.gd     # Player character control
      village.gd    # Village goodwill/ management
      crops.gd      # Crop growth cycle
    autoload.gd     # Global singletons (SignalBus)
  ProjectSettings/
  scenes/
    main.tscn
    player.tscn
    village.tscn
  README.md
```

### Key Godot 4 Configurations
- **Rendering**: 2D canvas items, pixel art friendly (filter = POINT)
- **Import settings**: compress_mode = DISABLED (development), max_size = 256 (UI)
- **Project Settings → Language**: GDScript 4.x
- **Autoload**: SignalBus singleton (name: "SignalBus", path: "res://src/scripts/signalbus.gd")

### SignalBus Architecture (Simplified Core Signals)
- `player/energy_changed` (int new_energy)
- `player/stamina_changed` (int new_stamina)
- `village/goodwill_changed` (int new_goodwill)
- `crop/growth_progress` (int progress, max_stage)
- `season/changed` (enum: MONSOON, HOT, COOL)
- `ui/update_energy` (int energy)
- `ui/update_goodwill` (int goodwill)
- `ui/update_season` (enum season)

### Monsoon Season (Jun-Sep)
- **Color**: Blue-ish global tint (20%)
- **Water**: everywhere, shallow water tiles
- **Particles**: Rain falling (2px semi-transparent drops)
- **Crops**: Accelerated growth from rain
- **Festivals**: Binthabat (temple offerings) visual cues

### Hot Season (Mar-May)
- **Color**: Orange-golden tint (25%)
- **Crops**: May wilt without watering
- **Visual**: Heat haze at screen top
- **Grass**: Yellow/brown coloration
- **Water**: Critical gameplay element to manage

### Cool Season (Oct-Feb)
- **Color**: Teal-calm tint (15%)
- **Crops**: Full growth, harvest-ready
- **Visual**: Clear skies, gentle lighting
- **Festivals**: Harvest celebrations, temple events
- **Goodwill**: Higher base village harmony
---

## Kenney CC0 Art Source (2026-09-07, supersedes palette above)

Full replace of the shipped custom Thai-countryside art with Kenney CC0
(public domain) packs, tracked as `TASK-321`. This section is the
load-bearing documentation for current art — the palette table earlier in
this file describes the prior pipeline and is historical only.

### Source packs

Seven world/character packs plus three UI/icon packs, imported raw into
`assets/kenney/` and documented per-pack in `assets/kenney/README.md`:

| Pack | Covers |
|---|---|
| `tiny_farm` | terrain, crops (multi-stage growth), farm objects, animals, 2 static farmer icons |
| `tiny_dungeon` | character/NPC single-frame art, small items (potions/weapons/shields/keys) |
| `tiny_town` | buildings, trees/bushes, stone & brick walls — no characters |
| `tiny_battle` | water tile source only (`tile_0037.png`, open lake water) — 18x11 grid, different index math (`row*18+col`) than the other packs' 12x11 |
| `emotes` | 8 pixel-art 16x16 reaction-icon sets for NPC mood bubbles/dialogue |
| `game_icons` | 105 generic B/W icons (1x/2x) for menus/inventory |
| `ui_rpg` | 87 RPG UI widgets (buttons, panels, stat bars, cursors) mapping onto `assets/ui/` |

### Scale convention

Native tile size is **16x16px**; shipped grid is **48x48px** (3x). Scale is
applied via node `scale` / TileSet pixel size — never by pre-upscaling PNGs
— which keeps nearest-neighbor filtering crisp and matches the rest of the
project's pixel-art handling.

### Character-sprite compositing convention

Overworld NPC/player sprites are single Kenney tiles scaled and pasted
bottom-aligned onto a transparent canvas, not full redraws:

- **Standard canvas**: 48x72. Tile scaled 3x to 48x48 (scale = canvas
  width / 16), pasted at `x=0, y=canvas_height-48=24`.
- **Smaller canvas** (e.g. child NPCs): 32x48. Tile scaled 2x to 32x32,
  pasted at `x=0, y=48-32=16`.
- **General rule**: canvas height = 1.5 x canvas width; scale factor =
  canvas width / 16. One legacy exception (`nong_ton_idle_01.png`, 40x58)
  preserves an original pre-Kenney custom-sprite dimension and was
  deliberately left alone rather than forced onto the 16-multiple grid.

### Known gap: player character animation

No pack contains a multi-frame directional walk-cycle. Decision: use a
single `tiny_dungeon` character frame, horizontally flipped for left/right
facing, same frame reused for up/down — no real walk-cycle.

### Known gap: water tiles

None of the six original packs had a real water tile; `tiny_battle` was
imported specifically to fix this (`tile_0037.png` backs `canal.png`,
`water_surface.png`, `water_lotuspond.png`).

### Pipeline history

1. **Pass 1** (automated): all 426 previously-deleted asset files
   (tilesets, characters, environment incl. `crops/`, items, ui) regenerated
   from the Kenney packs and written back to their **original paths at
   their original pixel dimensions** — this is why no scene (`.tscn`)
   or script (`.gd`) file needed any path changes; every `res://assets/...`
   reference the codebase already had kept working unmodified. Picks were
   category-level, not hand-curated per file (round-robin pools).
2. **Pass 2, items** (`assets/items/`): 157 Thai-food/ingredient icons
   re-substituted with closer semantic matches across the full pool
   (produce baskets, potions for soups, size-tiered weapons for
   fish/shrimp, crystals/shields for ritual items) instead of the pass-1
   single-pool round-robin.
3. **Pass 2, water**: `tiny_battle` added, canal/pond/water-surface tiles
   backed by real water art instead of a flat-color procedural fallback.
4. **Pass 2, characters** (2026-09-07): audited `assets/characters/` and
   found 14 sprite files (`boon`, `ek`, `note`, `npc_priest` idle+walk,
   `npc_child` walk) had been pass-1-substituted with weapon/item icons
   instead of humanoid art — a genuine content bug, not a style choice.
   Re-composited each from a correct humanoid `tiny_dungeon` tile
   (rogue/villager/knight/priest-like/child-sized figures), preserving
   each file's exact existing dimensions.

### Scene/resource re-wiring status

Audited 2026-09-07: there are **no `SpriteFrames` or `TileSet` `.tres`
resources** in this project — every character and tileset texture is
referenced by a direct `res://assets/...` path, either as a `.tscn`
`ext_resource` (characters, crop data) or as a string path in a `.gd`
dictionary (`WorldRender.gd`'s tileset map, `VillagerNPC.gd`'s per-NPC
portrait map). Since pass 1 preserved every file's original path, and a
full scan of every `res://assets/*.png` / `*.tres` reference across all
`.tscn`/`.tres`/`.gd` files found zero missing/broken paths, **no scene
re-wiring was needed** — the path-stability decision in pass 1 made this
a non-issue by construction.

### Test gates

`tests/test_asset_shading.gd`'s dimension-preservation check applies to
every `.png` under `assets/items`, `assets/environment`, `assets/characters`,
`assets/particles` (must match `assets/.pre_pass_alpha_snapshot.json`);
its 6 `SPOT_CHECKS` files carry an additional opaque-color-count and
alpha-invariant check. Any future re-substitution pass must preserve exact
existing dimensions per file and must run `godot --headless --import`
before the test suites (the `.import` cache is gitignored and stale
metadata for a changed PNG can make headless `load()` return null).
