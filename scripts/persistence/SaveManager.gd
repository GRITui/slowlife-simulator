class_name SaveManager
extends Node
# SaveManager — ENGINE-003 persistence layer (@data-persistence)
# Greenfield save/load state machine + JSON schema for player/world state.
# Decoupled via SignalBus (save_completed / load_completed / save_failed).
# All callers supply TimeManager + GridManager; GameData is autoload.

const SAVE_VERSION: int = 1
const SAVE_DIR: String = "user://saves"
const SAVE_EXTENSION: String = ".json"

# JSON schema (v1) — versioned so future migrations can branch on `version`.
# {
#   "version": 1,
#   "timestamp": "2026-08-31T11:00:00",
#   "player": {
#     "stamina": {"current": 100.0, "max": 100.0},
#     "harmony": 0, "max_harmony": 100,
#     "inventory": {"rice_grain": 2},
#     "infrastructure": {"sluice_gate": true},
#     "season": "cool", "weather": "clear",
#     "binthabat": {"daily_offerings": 0, "last_offering_day": -1}
#   },
#   "time": {
#     "day": 1, "hour": 6, "minute": 0, "days_in_season": 0,
#     "season": "cool", "weather": "clear", "accum_minutes": 0.0,
#     "stamina_multiplier": 1.0
#   },
#   "grid": {
#     "grid_size": [20, 16], "maze_origin": [14, 10],
#     "plots": {"(5, 5)": {"id": "jasmine_rice", "stage": 1, "minutes": 0, "watered": false}},
#     "season": "cool", "weather": "clear"
#   },
#   "player_pos": [320, 256],
#   "meta": {"slot": "slot_1", "playtime_seconds": 0.0}
# }

static func get_save_path(slot: String) -> String:
	var safe := slot.strip_edges()
	if safe.is_empty():
		safe = "autosave"
	var sanitized := ""
	for c in safe:
		if (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or (c >= "0" and c <= "9") or c == "_" or c == "-":
			sanitized += c
		else:
			sanitized += "_"
	return "%s/%s%s" % [SAVE_DIR, sanitized, SAVE_EXTENSION]

static func ensure_save_dir() -> bool:
	var dir := DirAccess.open("user://")
	if dir == null:
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
		return DirAccess.open(SAVE_DIR) != null
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		var err := DirAccess.make_dir_recursive_absolute(SAVE_DIR)
		return err == OK
	return true

static func get_schema() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"required_top_keys": ["version", "timestamp", "player", "time", "grid"],
		"player_keys": ["stamina", "harmony", "inventory", "infrastructure", "season", "weather", "binthabat"],
		"time_keys": ["day", "hour", "minute", "days_in_season", "season", "weather"],
		"grid_keys": ["grid_size", "maze_origin", "plots", "season", "weather"],
	}

static func validate_save(data: Dictionary) -> bool:
	if not data.has("version"):
		return false
	var ver: Variant = data["version"]
	if typeof(ver) != TYPE_INT and typeof(ver) != TYPE_FLOAT:
		return false
	if int(ver) != SAVE_VERSION:
		return false
	for k in get_schema()["required_top_keys"]:
		if not data.has(k):
			return false
	var player: Dictionary = data["player"]
	for k in get_schema()["player_keys"]:
		if not player.has(k):
			return false
	var stamina: Dictionary = player["stamina"]
	if not stamina.has("current") or not stamina.has("max"):
		return false
	var time: Dictionary = data["time"]
	for k in get_schema()["time_keys"]:
		if not time.has(k):
			return false
	# JSON numbers parse as float — accept int or float for time fields
	for tk in ["day", "hour", "minute", "days_in_season"]:
		if time.has(tk):
			var v: Variant = time[tk]
			if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
				return false
	var grid: Dictionary = data["grid"]
	for k in get_schema()["grid_keys"]:
		if not grid.has(k):
			return false
	if typeof(grid["grid_size"]) != TYPE_ARRAY or grid["grid_size"].size() != 2:
		return false
	if typeof(grid["plots"]) != TYPE_DICTIONARY:
		return false
	return true

static func export_state(p_time_manager: Node = null, p_grid_manager: Node = null) -> Dictionary:
	var tm: Node = p_time_manager if p_time_manager else _find_time_manager()
	var gm: Node = p_grid_manager if p_grid_manager else _find_grid_manager()
	var gd: Node = Engine.get_main_loop().root.get_node_or_null("GameData") if Engine.get_main_loop() and Engine.get_main_loop().has_method("get_root") else null
	if gd == null:
		gd = _find_gamedata()
	var now := Time.get_datetime_string_from_system(false, true)
	var player_block := {
		"stamina": {
			"current": float(gd.current_stamina) if gd and "current_stamina" in gd else 100.0,
			"max": float(gd.max_stamina) if gd and "max_stamina" in gd else 100.0,
		},
		"harmony": int(gd.harmony) if gd and "harmony" in gd else 0,
		"max_harmony": int(gd.max_harmony) if gd and "max_harmony" in gd else 100,
		"inventory": (gd.inventory.duplicate(true) if gd and "inventory" in gd else {}),
		"infrastructure": (gd.infrastructure.duplicate(true) if gd and "infrastructure" in gd else {}),
		"season": String(gd.current_season) if gd and "current_season" in gd else "cool",
		"weather": String(gd.current_weather) if gd and "current_weather" in gd else "clear",
		"binthabat": {
			"daily_offerings": int(gd.daily_offerings) if gd and "daily_offerings" in gd else 0,
			"last_offering_day": int(gd.last_offering_day) if gd and "last_offering_day" in gd else -1,
		},
	}
	var time_block := {
		"day": int(tm.day) if tm and "day" in tm else 1,
		"hour": int(tm.hour) if tm and "hour" in tm else 6,
		"minute": int(tm.minute) if tm and "minute" in tm else 0,
		"days_in_season": int(tm._days_in_season) if tm and "_days_in_season" in tm else 0,
		"season": String(tm.current_season) if tm and "current_season" in tm else String(player_block["season"]),
		"weather": String(tm.current_weather) if tm and "current_weather" in tm else String(player_block["weather"]),
		"accum_minutes": float(tm._accum_minutes) if tm and "_accum_minutes" in tm else 0.0,
		"stamina_multiplier": float(tm.stamina_drain_multiplier) if tm and "stamina_drain_multiplier" in tm else 1.0,
	}
	var grid_block: Dictionary
	if gm and gm.has_method("serialize"):
		grid_block = gm.serialize()
	else:
		grid_block = {
			"grid_size": Vector2i(20, 16),
			"maze_origin": Vector2i(14, 10),
			"plots": {},
			"season": String(player_block["season"]),
			"weather": String(player_block["weather"]),
		}
	if grid_block.has("grid_size") and grid_block["grid_size"] is Vector2i:
		grid_block["grid_size"] = [grid_block["grid_size"].x, grid_block["grid_size"].y]
	if grid_block.has("maze_origin") and grid_block["maze_origin"] is Vector2i:
		grid_block["maze_origin"] = [grid_block["maze_origin"].x, grid_block["maze_origin"].y]
	var player_pos_arr: Array = []
	var player_node := _find_player()
	if player_node and "global_position" in player_node:
		var pos: Vector2 = player_node.global_position
		player_pos_arr = [pos.x, pos.y]
	var out := {
		"version": SAVE_VERSION,
		"timestamp": now,
		"player": player_block,
		"time": time_block,
		"grid": grid_block,
		"player_pos": player_pos_arr,
		"meta": {"slot": "", "playtime_seconds": 0.0},
	}
	return out

static func import_state(data: Dictionary, p_time_manager: Node = null, p_grid_manager: Node = null) -> bool:
	if not validate_save(data):
		push_warning("SaveManager: validate_save failed — rejecting import (version %s)" % str(data.get("version", "?")))
		return false
	var tm: Node = p_time_manager if p_time_manager else _find_time_manager()
	var gm: Node = p_grid_manager if p_grid_manager else _find_grid_manager()
	var gd: Node = _find_gamedata()
	var player: Dictionary = data["player"]
	var time: Dictionary = data["time"]
	var grid: Dictionary = data["grid"]
	if gd:
		var stamina: Dictionary = player["stamina"]
		gd.max_stamina = float(stamina["max"])
		gd.current_stamina = float(stamina["current"])
		gd.harmony = int(player["harmony"])
		# JSON numbers parse as float — coerce inventory counts back to int
		var inv_raw: Dictionary = player["inventory"] as Dictionary
		var inv_conv: Dictionary = {}
		for k in inv_raw.keys():
			inv_conv[k] = int(inv_raw[k])
		gd.inventory = inv_conv
		gd.infrastructure = (player["infrastructure"] as Dictionary).duplicate(true)
		gd.current_season = String(player["season"])
		gd.current_weather = String(player["weather"])
		var binth: Dictionary = player["binthabat"]
		gd.daily_offerings = int(binth["daily_offerings"])
		gd.last_offering_day = int(binth["last_offering_day"])
	if tm:
		if tm.has_method("set_time"):
			tm.set_time(int(time["day"]), int(time["hour"]), int(time["minute"]))
		else:
			tm.day = int(time["day"])
			tm.hour = int(time["hour"])
			tm.minute = int(time["minute"])
		tm._days_in_season = int(time.get("days_in_season", 0))
		tm._accum_minutes = float(time.get("accum_minutes", 0.0))
		var season: String = String(time["season"])
		if tm.has_method("set_season"):
			tm.set_season(season)
		else:
			tm.current_season = season
		tm.current_weather = String(time["weather"])
		if tm.has_method("_apply_season_effects"):
			tm._apply_season_effects()
	if gm:
		var plots: Dictionary = grid["plots"]
		if gm.has_method("apply_save_plots"):
			gm.apply_save_plots(plots)
		else:
			if "plots" in gm:
				gm.plots.clear()
			for key in plots.keys():
				var cell := _parse_cell_key(String(key))
				if cell == Vector2i(-999, -999):
					continue
				var entry: Dictionary = plots[key]
				var crop_id: String = String(entry.get("id", ""))
				if crop_id.is_empty():
					continue
				var crop: Resource = load("res://data/crops/%s.tres" % crop_id)
				if crop == null:
					crop = load(crop_id) as Resource
				if crop == null:
					continue
				if gm.has_method("create_plot_state"):
					var ps: Variant = gm.create_plot_state(crop, int(entry.get("stage", 0)), int(entry.get("minutes", 0)), bool(entry.get("watered", false)), int(entry.get("planted_day", -1)), int(entry.get("wilt_minutes", 0)))
					gm.plots[cell] = ps
		gm.current_season = String(grid.get("season", String(player["season"])))
		gm.current_weather = String(grid.get("weather", String(player["weather"])))
	if data.has("player_pos") and data["player_pos"] is Array and data["player_pos"].size() == 2:
		var player_node := _find_player()
		if player_node and "global_position" in player_node:
			var arr: Array = data["player_pos"]
			player_node.global_position = Vector2(float(arr[0]), float(arr[1]))
	return true

static func save_game(slot: String, p_time_manager: Node = null, p_grid_manager: Node = null) -> bool:
	if not ensure_save_dir():
		push_warning("SaveManager: could not ensure save dir '%s'" % SAVE_DIR)
		_signal_failed(slot, "ensure_save_dir failed")
		return false
	var data := export_state(p_time_manager, p_grid_manager)
	data["meta"]["slot"] = slot
	var path := get_save_path(slot)
	var json := JSON.stringify(data, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var err := FileAccess.get_open_error()
		push_warning("SaveManager: open for write failed '%s' err %d" % [path, err])
		_signal_failed(slot, "open failed err %d" % err)
		return false
	file.store_string(json)
	file.close()
	_signal_saved(slot)
	return true

static func load_game(slot: String, p_time_manager: Node = null, p_grid_manager: Node = null) -> bool:
	var path := get_save_path(slot)
	if not FileAccess.file_exists(path):
		push_warning("SaveManager: no save at '%s'" % path)
		_signal_failed(slot, "file not found")
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_signal_failed(slot, "open for read failed")
		return false
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: JSON parse failed for '%s'" % path)
		_signal_failed(slot, "json parse failed")
		return false
	var dict: Dictionary = parsed as Dictionary
	if not import_state(dict, p_time_manager, p_grid_manager):
		_signal_failed(slot, "import_state failed (schema mismatch)")
		return false
	_signal_loaded(slot)
	return true

static func has_save(slot: String) -> bool:
	return FileAccess.file_exists(get_save_path(slot))

static func list_saves() -> Array:
	var out: Array = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return out
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(SAVE_EXTENSION):
			out.append(fname.trim_suffix(SAVE_EXTENSION))
		fname = dir.get_next()
	dir.list_dir_end()
	return out

static func delete_save(slot: String) -> bool:
	var path := get_save_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var err := DirAccess.remove_absolute(path)
	return err == OK

# --- Signals (decoupled) ---

static func _signal_saved(slot: String) -> void:
	var sb := _find_signalbus()
	if sb and sb.has_signal("save_completed"):
		sb.emit_signal("save_completed", slot)

static func _signal_loaded(slot: String) -> void:
	var sb := _find_signalbus()
	if sb and sb.has_signal("load_completed"):
		sb.emit_signal("load_completed", slot)

static func _signal_failed(slot: String, reason: String) -> void:
	var sb := _find_signalbus()
	if sb and sb.has_signal("save_failed"):
		sb.emit_signal("save_failed", slot, reason)

# --- Finders (decoupled from scene) ---

static func _find_signalbus() -> Node:
	if Engine.get_main_loop() == null:
		return null
	var root: Node = Engine.get_main_loop().root if Engine.get_main_loop().has_method("get_root") else null
	if root == null:
		return null
	var sb := root.get_node_or_null("SignalBus")
	if sb:
		return sb
	for c in root.get_children():
		if c.has_signal("save_completed") or c.has_signal("minute_ticked"):
			return c
	return null

static func _find_gamedata() -> Node:
	if Engine.get_main_loop() == null:
		return null
	var root: Node = Engine.get_main_loop().root
	var gd := root.get_node_or_null("GameData")
	if gd:
		return gd
	for c in root.get_children():
		if c.has_method("add_item") and c.has_method("has_item"):
			return c
	return null

static func _find_time_manager() -> Node:
	if Engine.get_main_loop() == null:
		return null
	var root: Node = Engine.get_main_loop().root
	var direct := root.get_node_or_null("/root/TimeManager")
	if direct:
		return direct
	var scene: Node = Engine.get_main_loop().current_scene if "current_scene" in Engine.get_main_loop() else null
	if scene:
		var found := scene.find_child("TimeManager", true, false)
		if found:
			return found
	for c in root.get_children():
		if c.has_method("set_time") and c.has_method("set_season"):
			return c
	return null

static func _find_grid_manager() -> Node:
	if Engine.get_main_loop() == null:
		return null
	var root: Node = Engine.get_main_loop().root
	var scene: Node = Engine.get_main_loop().current_scene if "current_scene" in Engine.get_main_loop() else null
	if scene:
		var found := scene.find_child("GridManager", true, false)
		if found:
			return found
	for c in root.get_children():
		if c.has_method("is_plantable") and c.has_method("plant"):
			return c
	return null

static func _find_player() -> Node:
	if Engine.get_main_loop() == null:
		return null
	var root: Node = Engine.get_main_loop().root
	var scene: Node = Engine.get_main_loop().current_scene if "current_scene" in Engine.get_main_loop() else null
	if scene:
		var found := scene.find_child("Player", true, false)
		if found:
			return found
	for c in root.get_children():
		if c.is_in_group("player"):
			return c
	return null

static func _parse_cell_key(s: String) -> Vector2i:
	s = s.strip_edges()
	if s.begins_with("(") and s.ends_with(")"):
		s = s.substr(1, s.length() - 2)
	var parts := s.split(",")
	if parts.size() != 2:
		return Vector2i(-999, -999)
	var x := int(parts[0].strip_edges())
	var y := int(parts[1].strip_edges())
	return Vector2i(x, y)
