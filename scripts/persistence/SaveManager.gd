extends Node
# SaveManager — ENGINE-003 JSON schema for player/world state, headless-safe.
# TASK-026: versioned schema (SAVE_VERSION) + v1->v2 migration + int coercion
# + default-on-add for new fields (krathong). Dynamic GameData/SignalBus
# lookups keep this script parse-safe under `godot --headless --script`.

const SAVE_PATH: String = "user://savegame.json"
const SAVE_VERSION: int = 2

# Dynamic autoload helpers — safe in main scene, --script, and packaged export.
func _gd() -> Node:
	return Engine.get_main_loop().root.get_node("GameData")

func _sb() -> Node:
	return Engine.get_main_loop().root.get_node("SignalBus")

func save_game() -> bool:
	var gd: Node = _gd()
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"player_pos": [480, 384],
		"inventory": gd.inventory,
		"harmony": gd.harmony,
		"season": gd.current_season,
		# TASK-027 a11y prefs (additive v2 fields, tolerate absence on old saves)
		"font_scale": gd.font_scale,
		"high_contrast": gd.high_contrast,
		# ISSUE-135 silver wallet (additive v2 field)
		"silver": gd.silver,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data))
	return true

# Migrate any older payload to SAVE_VERSION shape. Pure function: returns a
# new Dictionary, never mutates the input. Idempotent for v=2 payloads.
func migrate(data: Dictionary) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	var version: int = int(out.get("version", 1))
	# v1 -> v2: tag version, coerce JSON-float inventory/harmony to int,
	# default-add any new fields that didn't exist in older saves.
	if version < 2:
		var inv: Dictionary = out.get("inventory", {}) as Dictionary
		var fixed: Dictionary = {}
		for item_id: String in inv.keys():
			fixed[item_id] = int(inv[item_id])
		# Default-on-add: new v2 fields must exist on every migrated save so
		# callers can use `inventory[key]` without `.get(key, 0)` everywhere.
		if not fixed.has("krathong"):
			fixed["krathong"] = 0
		out["inventory"] = fixed
		out["harmony"] = int(out.get("harmony", 0))
		out["version"] = 2
	return out

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var j: Variant = JSON.parse_string(f.get_as_text())
	if j is Dictionary:
		var data: Dictionary = migrate(j as Dictionary)
		var gd: Node = _gd()
		var sb: Node = _sb()
		gd.inventory.clear()
		var inv: Dictionary = data.get("inventory", {}) as Dictionary
		for item_id: String in inv.keys():
			gd.inventory[item_id] = int(inv[item_id])
		gd.harmony = int(data.get("harmony", 0))
		gd.current_season = String(data.get("season", "cool"))
		# TASK-027: restore a11y prefs when present (old saves keep defaults).
		gd.font_scale = float(data.get("font_scale", 1.0))
		gd.high_contrast = bool(data.get("high_contrast", false))
		gd.silver = int(data.get("silver", 0))
		sb.show_dialogue.emit("System", "Game loaded.")
		return true
	return false