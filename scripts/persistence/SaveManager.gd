extends Node
# SaveManager — ENGINE-003 JSON schema for player/world state, headless-safe
const SAVE_PATH: String = "user://savegame.json"
func save_game() -> bool:
  var data: Dictionary = {
    "player_pos": [480,384],
    "inventory": GameData.inventory,
    "harmony": GameData.harmony,
    "season": GameData.current_season
  }
  var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
  if f == null: return false
  f.store_string(JSON.stringify(data))
  return true
func load_game() -> bool:
  if not FileAccess.file_exists(SAVE_PATH): return false
  var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
  if f == null: return false
  var j: Variant = JSON.parse_string(f.get_as_text())
  if j is Dictionary:
    if "inventory" in j: GameData.inventory = j["inventory"]
    if "harmony" in j: GameData.harmony = int(j["harmony"])
    SignalBus.show_dialogue.emit("System", "Game loaded.")
    return true
  return false
