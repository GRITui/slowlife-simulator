# ART STYLE GUIDE: Thai Rural Countryside Sim

## Core Palette (16 colors — Hybrid A/B, 4 extra for water/mist)
| Color | Hex | Usage |
|-------|-----|-------|
| Rice White | #F5F0E8 | Background, clouds |
| Jasmine Yellow | #FDD835 | Sunlight, highlights |
| Pandan Green | #AED581 | Rice fields, vegetation |
| Lotus Pink | #F48FB1 | Flowers, harmony |
| Clay Brown | #8D6E63 | Clay stove, mortar |
| Mo Hom Maroon | #6A1B9A | Traditional cloth accents |
| Pha Khao Ma Gray | #757575 | Clothing, rope |
| Monsoon Blue | #2196F3 | Rainy season, water |
| Cool Teal | #009688 | Cool season, water |
| Hot Orange | #FF9800 | Sun, heat |
| Rice Gold | #FFE0B2 | Skin tones, UI accents |
| Sky Cyan | #E0F7FA | Daytime sky |
| Canal Teal | #4DB6AC | Canal water mid (Hybrid B) |
| Mist Lavender | #B39DDB | Cool fog/mist overlay |
| Deep Pond | #1565C0 | Lotus maze depth |
| Wood Amber | #A1887F | Dock/teak wood grain |

**Rules**: Base 12 + 4 extenders for water/mist/wood (Hybrid B pull). Warm for sunlight, cool for shade/water. Seasonal tinting applied globally. Enforced per-scene max 16.

> **✓ Locked 2026-08-31 — Hybrid A/B (Isan Plain + Canal Maze), updated 16-color** — Flat 20×16 paddy grid (A) + single canal-maze water feature from B (lotus maze + dock/raft + sluice gate + canal tile + mango). Palette now 16-color to accommodate Canal Teal / Mist Lavender / Deep Pond / Wood Amber. See `ART_WORLD_VISION_V2.html#decision` and `.decision.json`.
## Tile Set Specifications

- **Base size**: 32x32 pixels (scaled from 16x16 originals)
- **Grid**: Top-down staggered grid, offset (16, 8)
- **Categories needed**: Ground, Environment, Structures, Interactive, Decor
- **Animations**: Crop growth (4 frames), water flow (3-frame loop), wind vegetation (subtle shift)
- **Naming convention**: `tilesets/ground_ricepaddy.png`, `tilesets/water_lotuspond.png`, etc.
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
- **Size**: 32x48 pixels (including collision)
- **Color scheme**: Mo Hom maroon accents, Pha Khao Ma gray elements
- **Animations needed**: Idle (4 frames), Walk (8 frames), Hoe/plant (4 frames), Harvest (4 frames), Carrying crop
- **Palette**: Maroon (Mo Hom) + Gray (Pha Khao Ma) + skin tone #FFE0B2

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
| Energy Bar | 200x12 | Green→Yellow→Red gradient, SignalBus: `player/energy_changed` |
| Crop Progress | 150x12 | Bar showing growth stage, current crop icon |
| Village Goodwill | 180x12 | Heart icons or harmony symbols, SignalBus: `village/goodwill_changed` |
| Season Display | 100x12 | Text + small seasonal icon (Monsoon/Hot/Cool) |
| Inventory Slot | 32x32 | Border when empty, item icon when filled |
| Action Prompt | 200x32 | Bottom-center, "Press E to harvest" etc. |

### UI Color Usage
- **Background**: Rice White (#F5F0E8) with 90% opacity
- **Accents**: Jasmine Yellow for positive, Lotus Pink for harmony/bonus
- **Text**: Mo Maroon for headings, Pandan Green for subtitles
- **Borders**: Clay Brown (#8D6E63) 1px rounded

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