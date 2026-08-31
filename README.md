# slowlife-simulator

## Project Setup & Getting Started

### Prerequisites
- Godot 4.x installed
- GDScript 4.x knowledge

### Project Structure
```
/slowlife-game/
  project.godot          # Godot project configuration
  ART_STYLE_GUIDE.md     # Art style guide (created)
  scripts/autoload/
      SignalBus.gd       # Central signalbus singleton
      gameday.gd         # Season/day/night cycle
      player.gd          # Player character control
    scenes/              # Godot scenes
      main.tscn          # Main game scene
  workflows/
    ai-agent-autonomous.yml
  PROJECT_VISION.md      # Project vision & rules
  README.md
```

### Running the Project
1. Open Godot 4
2. Select "Import" and choose `/Users/grit/slowlife-game/project.godot`
3. Or drag `project.godot` onto Godot icon
4. Click "Project Settings" → "Autoload" to register SignalBus
5. Run the game (F6 or ▶️ button)

### SignalBus Autoload Setup
1. Open Project Settings (gear icon)
2. Autoload tab
3. Click "Add Singleton"
4. **Name**: `SignalBus`
5. **Path**: `res://scripts/autoload/SignalBus.gd`
6. Click "Add"

### Current Systems Implemented
- Color palette (12 colors, Thai countryside inspired)
- Tile set specifications (32x32, top-down staggered)
- Environmental assets list (clay stove, lotus pond, rice paddy, etc.)
- Character design guidelines (farmer, NPCs, animations)
- UI design specifications (energy bar, goodwill, seasonal display)
- Seasonal system visuals (monsoon/hot/cool with color tints)
- Godot 4 project structure
- SignalBus singleton architecture
- Game day/night & season cycle
- Player energy management

### Next Steps (Prioritized)
1. **Art Asset Creation** - Start with tile set (rice fields, water, structures)
2. **Player Character Sprites** - Create idle/walk animations (32x48px)
3. **Environmental Props** - Clay stove, lotus pond, bamboo, banana circle
4. **UI Implementation** - Energy bar, goodwill display using SignalBus
5. **Seasonal System** - Full Godot implementation with visual changes
6. **Crop Growth Cycle** - Growth stages animation & harvesting

### Art Style Reference
- **Palette**: Rice White, Jasmine Yellow, Pandan Green, Lotus Pink, Clay Brown, Mo Hom Maroon, Pha Khao Ma Gray, Monsoon Blue, Cool Teal, Hot Orange, Rice Gold, Sky Cyan
- **Style**: Top-down 2D pixel art, cozy atmospheric lighting, clean palettes
- **Theme**: Authentic Thai rural countryside - culture through environment, food, mechanics, clothing
- **No combat**: Focus on crop cycles, energy management, village goodwill, seasonal festivals

### Cultural Elements Included
- **Mo Hom**: Traditional maroon Thai cloth
- **Pha Khao Ma**: Gray checkered traditional skirt
- **Clay stove & mortar & pestle**: Core cooking mechanics
- **Lotus pond**: Water feature with harvesting
- **Rice paddy**: Primary crop field
- **Seasonal festivals**: Tied to monsoon/hot/cool cycles
- **Binthabat**: Temple offerings for village harmony