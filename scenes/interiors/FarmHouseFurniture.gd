extends Node2D
## FarmHouseFurniture — TASK-374 Phase 1 + TASK-375 Phase 2. Toggleable
## furniture placement for FarmHouse's interior only.
##
## TASK-374 Phase 1: one item (floor_rug), no rotation.
## TASK-375 Phase 2: 4-direction rotation (T), two new items
## (floor_cushion, small_table), and a session-only "primed" item
## selection (Y) that cycles through OWNED furniture item ids only --
## mirrors TASK-350's _primed_seed_id pattern exactly (third reuse of
## the same shape in this codebase: seeds TASK-350, fishing gear
## TASK-359, furniture TASK-375).
##
## Design: press toggle_furniture_place_mode (F) to enter/exit place
## mode. While active, pressing interact places or picks up the primed
## item at the PLAYER'S OWN current cell -- same convention Player.gd's
## outdoor _try_grid_interact() already uses (floor(global_position /
## TILE)), not mouse-position targeting (this project has no
## mouse-driven UI convention; it's an iOS touch/keyboard target).
## Pressing rotate_furniture (T) while standing on a placed piece
## rotates it 90° clockwise (0->1->2->3->0 wraparound). Pressing
## cycle_furniture_item (Y) cycles which owned item is "primed" for
## the next place action. A player who never touches T or Y sees zero
## behavior change from Phase 1: _primed_furniture_id defaults to ""
## so the place/pickup branch falls back to floor_rug (the Phase 1
## default), and rotation only ever touches existing entries.
##
## Persistence: GameData.placed_furniture (location_id "farmhouse" ->
## Array<{item_id, cell, facing}>), additive, no SAVE_VERSION bump.
## `facing` is a 0..3 rotation index (0=0°, 1=90°, 2=180°, 3=270°).
## Old Phase 1 saves have entries without a `facing` key; every read
## site defends with `entry.get("facing", 0)` so the runtime contract
## is unchanged for them (see GameData.placed_furniture's own comment
## for the no-bump reasoning).

const TILE: int = 48
const GRID: Vector2i = Vector2i(6, 5)
const LOCATION_ID: String = "farmhouse"
const RUG_ITEM_ID: String = "floor_rug"

# TASK-375: item_id -> short display name used as the sprite node-name
# prefix (so "Rug_2_2" / "Cushion_2_2" / "Table_2_2" can coexist on
# the same grid without node-name collisions and the same sprite node
# can be looked up by either name). Texture paths are defined inline
# at the spawn site below -- this dict owns the node-name side only.
#
# TASK-391: five new catalogue entries (portrait, chair, bench, vase,
# radio). Placeable through the exact same owned-via-inventory /
# primed-item flow as the original three -- no new placement path.
const DISPLAY_NAMES: Dictionary = {
	"floor_rug": "Rug",
	"floor_cushion": "Cushion",
	"small_table": "Table",
	"wall_portrait": "Portrait",
	"wooden_chair": "Chair",
	"wooden_bench": "Bench",
	"ceramic_vase": "Vase",
	"transistor_radio": "Radio",
}

# TASK-391: locked interaction lines -- verbatim, do not paraphrase.
const PORTRAIT_LINE: String = "You look at the portrait for a moment longer than you meant to."
const SIT_LINE: String = "You sit a while. The day feels a little less long."
const VASE_FILLED_LINE: String = "The marigold brightens the room."
# Companion lines written for this task (not locked, but kept in the
# same quiet register): the sit cooldown, the vase's already-filled
# state, and the vase's empty-and-no-flower prompt.
const SIT_COOLDOWN_LINE: String = "You already rested here today. Best leave the seat a while."
const VASE_HAS_FLOWER_LINE: String = "The marigold is still there, keeping the room company."
const VASE_NEEDS_FLOWER_LINE: String = "The vase stands empty. A marigold would suit it."

# TASK-391: (festival_day, season, display name) for the radio countdown.
# Day/season pairs read from each trigger's ACTUAL @export value +
# season gate (verified 2026-09-05), not guessed:
# SongkranTrigger festival_day=3/hot, FishingCompetitionTrigger=15/hot,
# LopburiRaid=9/hot, AsalhaBuchaTrigger=5/monsoon, OkPhansaTrigger=28/
# monsoon, FestivalManager (Loy Krathong)=7/cool, WanSartTrigger=5/cool.
const FESTIVAL_DATES: Array = [
	{"day": 3, "season": "hot", "name": "Songkran"},
	{"day": 15, "season": "hot", "name": "the Fishing Competition"},
	{"day": 9, "season": "hot", "name": "the Lopburi Raid"},
	{"day": 5, "season": "monsoon", "name": "Asalha Bucha"},
	{"day": 28, "season": "monsoon", "name": "Ok Phansa"},
	{"day": 7, "season": "cool", "name": "Loy Krathong"},
	{"day": 5, "season": "cool", "name": "Wan Sart"},
]

# Cells already occupied by other FarmHouse interactables (from
# FarmHouse.tscn's own node positions) — never a valid placement target.
const OCCUPIED_CELLS: Array = [
	Vector2i(3, 5),  # OutsideDoor (144, 240)
	Vector2i(1, 1),  # Bed (72, 72)
	Vector2i(4, 1),  # Shrine (216, 72)
	Vector2i(5, 2),  # ShrineStylePicker (264, 120)
	Vector2i(1, 2),  # BedStylePicker (72, 120) -- TASK-367
]

var _place_mode: bool = false

# TASK-375: session-only "primed" furniture item for the next place
# action. Mirrors Player.gd's _primed_seed_id (TASK-350). Lives on
# this script (not GameData) so it isn't accidentally serialized by
# SaveManager. Defaults to "" so a player who never presses Y is
# bit-for-bit unchanged from Phase 1: the place/pickup branch falls
# back to RUG_ITEM_ID when this is empty.
var _primed_furniture_id: String = ""

@onready var _hint: Label = $PlaceModeHint if has_node("PlaceModeHint") else null

func _ready() -> void:
	SignalBus.placed_furniture_changed.connect(_on_furniture_changed)
	_refresh_rugs()
	_update_hint()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_furniture_place_mode"):
		_place_mode = not _place_mode
		_update_hint()
		SignalBus.show_dialogue.emit("Farmer", "Place mode: %s." % ("on" if _place_mode else "off"))
		get_viewport().set_input_as_handled()
		return
	if not _place_mode:
		# TASK-391: outside place mode, interact talks to / uses whatever
		# placed piece the player is standing on (portrait, chair, vase,
		# radio...). Empty cells fall through WITHOUT consuming the event
		# so every other interact handler keeps working exactly as before.
		_try_interact_with_furniture()
		return
	if event.is_action_pressed("cycle_furniture_item"):
		_try_cycle_primed_furniture()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("rotate_furniture"):
		_try_rotate()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact"):
		_try_place_or_pickup()
		get_viewport().set_input_as_handled()

func _update_hint() -> void:
	if _hint:
		_hint.visible = _place_mode
		_hint.text = "Place mode — [E] place/pick up, [T] rotate, [Y] cycle item, [F] exit"

func _player_cell() -> Vector2i:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return Vector2i(-1, -1)
	var local_pos: Vector2 = player.global_position - global_position
	return Vector2i(floori(local_pos.x / TILE), floori(local_pos.y / TILE))

func _is_valid_cell(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= GRID.x or cell.y >= GRID.y:
		return false
	return cell not in OCCUPIED_CELLS

func _try_place_or_pickup() -> void:
	var cell: Vector2i = _player_cell()
	if not _is_valid_cell(cell):
		SignalBus.show_dialogue.emit("Farmer", "Can't place a rug there.")
		return

	if GameData.has_placed_furniture_at(LOCATION_ID, cell):
		var entry: Dictionary = GameData.get_placed_furniture_at(LOCATION_ID, cell)
		var entry_item_id: String = String(entry.get("item_id", ""))
		if GameData.remove_placed_furniture(LOCATION_ID, entry_item_id, cell):
			GameData.add_item(entry_item_id, 1)
			SignalBus.show_dialogue.emit("Farmer", "Picked up the %s." %
				_display_name_for(entry_item_id).to_lower())
		return

	var item_id: String = _active_furniture_id()
	if not GameData.has_item(item_id, 1):
		# Soft-fail with the item's real name so the message makes
		# sense after the player starts cycling (Phase 1's "You don't
		# have a floor rug" line would be wrong for cushion/table).
		SignalBus.show_dialogue.emit("Farmer", "You don't have a %s to place." %
			_display_name_for(item_id).to_lower())
		return

	GameData.remove_item(item_id, 1)
	GameData.add_placed_furniture(LOCATION_ID, item_id, cell)
	SignalBus.show_dialogue.emit("Farmer", "Placed a %s." %
		_display_name_for(item_id).to_lower())

# TASK-375: which item a press of [E] will try to place / pick up.
# Returns _primed_furniture_id when it's set AND the player still owns
# >=1 of it (the cycle path always re-primes from owned items, so
# this is the common condition), otherwise falls back to floor_rug --
# the Phase 1 default that preserves behavior for a player who never
# touches the cycle action.
func _active_furniture_id() -> String:
	if _primed_furniture_id != "" and GameData.has_item(_primed_furniture_id, 1):
		return _primed_furniture_id
	return RUG_ITEM_ID

# TASK-375: rotate the piece the player is standing on, 90° clockwise.
# Wraps 0->1->2->3->0. Soft-fails with a dialogue line when the cell
# is empty (no exception, matching _try_place_or_pickup()'s tone for
# an invalid cell).
func _try_rotate() -> void:
	var cell: Vector2i = _player_cell()
	if not GameData.has_placed_furniture_at(LOCATION_ID, cell):
		SignalBus.show_dialogue.emit("Farmer", "Nothing to rotate here.")
		return
	var entry: Dictionary = GameData.get_placed_furniture_at(LOCATION_ID, cell)
	var current: int = int(entry.get("facing", 0))
	var new_facing: int = GameData.set_placed_furniture_facing(LOCATION_ID, cell, current + 1)
	if new_facing < 0:
		# Shouldn't be reachable (the has_placed_furniture_at check
		# above passes), but keep the soft-fail shape for safety.
		SignalBus.show_dialogue.emit("Farmer", "Nothing to rotate here.")
		return
	SignalBus.show_dialogue.emit("Farmer", "Rotated to %d°." % (new_facing * 90))

# TASK-375: cycle which owned furniture item is "primed" for the next
# place action. Same sorted-iteration / wrap-around / "no items" shape
# as Player.cycle_primed_seed() (TASK-350) and any future gear cycle
# (TASK-359) -- session-only state, deterministic order.
func _try_cycle_primed_furniture() -> void:
	var owned: Array[String] = []
	for item_id: String in DISPLAY_NAMES.keys():
		if GameData.has_item(String(item_id), 1):
			owned.append(String(item_id))
	owned.sort() # deterministic, not Dictionary iteration order
	if owned.is_empty():
		_primed_furniture_id = ""
		SignalBus.show_dialogue.emit("Farmer", "No furniture to place.")
		return
	var idx: int = owned.find(_primed_furniture_id)
	_primed_furniture_id = owned[(idx + 1) % owned.size()]
	SignalBus.show_dialogue.emit("Farmer", "Furniture selected: %s." %
		_display_name_for(_primed_furniture_id))

func _display_name_for(item_id: String) -> String:
	# Returns the short display name ("Rug" / "Cushion" / "Table") for
	# dialogue + sprite-node-name use. Falls back to a title-cased
	# derivation so an unrecognized item id still produces a reasonable
	# line ("Floor_rug" -> "Floor Rug").
	if DISPLAY_NAMES.has(item_id):
		return String(DISPLAY_NAMES[item_id])
	var parts: PackedStringArray = item_id.split("_")
	var out: String = ""
	for part: String in parts:
		if part == "":
			continue
		if out != "":
			out += " "
		out += part.capitalize()
	return out if out != "" else item_id

func _texture_path_for(item_id: String) -> String:
	# TASK-375: per-item texture lookup. floor_rug keeps the existing
	# mohom_cloth.png (Phase 1's choice). floor_cushion reuses
	# pha_khao_ma.png -- a second existing cloth texture in
	# assets/environment/ (also used as the bed's "basic" decor).
	# small_table reuses clay_stove.png -- nothing table-shaped exists
	# in assets/environment/ or props/, so we follow this project's
	# established placeholder-art precedent (e.g. the tiny invisible
	# Sprite2D convention in FarmHouseShrineStylePicker.tscn) and pick
	# the closest neutral furniture-shaped prop already in the project.
	match item_id:
		"floor_rug": return "res://assets/environment/mohom_cloth.png"
		"floor_cushion": return "res://assets/environment/pha_khao_ma.png"
		"small_table": return "res://assets/environment/clay_stove.png"
		# TASK-391 art cleanup (2026-09-05, owner playtest finding): the
		# original placeholder reuses (portrait->bamboo_wall_tall,
		# chair->market_stall, bench->clay_stove_tall, radio->
		# structure_wall_cap) were genuinely jarring mismatches. Generated
		# real dedicated sprites via Draw Things txt2img (confirmed
		# working, unlike the earlier-diagnosed broken img2img path),
		# background-removed + cropped + resized to this project's 48px-
		# wide convention. ceramic_vase keeps water_jar.png -- that reuse
		# was already a good fit, no replacement needed.
		"wall_portrait": return "res://assets/environment/wall_portrait.png"
		"wooden_chair": return "res://assets/environment/wooden_chair.png"
		"wooden_bench": return "res://assets/environment/wooden_bench.png"
		"ceramic_vase": return "res://assets/environment/water_jar.png"
		"transistor_radio": return "res://assets/environment/transistor_radio.png"
	return "res://assets/environment/mohom_cloth.png"

# TASK-391: interact with an already-placed piece (outside place mode).
# Only consumes the input event when the player is actually standing on
# a placed piece; empty cells return quietly so other systems (bed,
# shrine, doors) keep receiving the event untouched.
func _try_interact_with_furniture() -> void:
	var cell: Vector2i = _player_cell()
	if not GameData.has_placed_furniture_at(LOCATION_ID, cell):
		return
	var entry: Dictionary = GameData.get_placed_furniture_at(LOCATION_ID, cell)
	interact_with_furniture(String(entry.get("item_id", "")), cell)
	get_viewport().set_input_as_handled()

# TASK-391: interaction dispatch for placed furniture. Mirrors
# FlavorNPC._talk()'s established shape: one shared function, several
# `if item_id == "x"` special-cased branches layered above a generic
# fallback for pieces with no interaction (rug/cushion/table).
func interact_with_furniture(item_id: String, cell: Vector2i) -> void:
	if item_id == "wall_portrait":
		SignalBus.show_dialogue.emit("Farmer", PORTRAIT_LINE)
		return
	if item_id == "wooden_chair" or item_id == "wooden_bench":
		_interact_sit(cell)
		return
	if item_id == "ceramic_vase":
		_interact_vase(cell)
		return
	if item_id == "transistor_radio":
		_interact_radio()
		return
	SignalBus.show_dialogue.emit("Farmer", "The %s sits where you left it." %
		_display_name_for(item_id).to_lower())

func _current_day() -> int:
	# Same "once per day" day-source as FlavorNPC._current_day() and
	# ForageNode._current_day() -- SignalBus.time_manager's current day.
	var tm: Node = SignalBus.time_manager
	if tm != null and "day" in tm:
		return int(tm.day)
	return 1

# TASK-391: per-instance dict key. A plain "%d,%d" STRING, never a raw
# Vector2i -- SaveManager's TASK-375 review documented that Vector2i
# stringifies to "(x, y)" through JSON and never parses back, which
# would silently break every lookup after a save/load round-trip.
func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]

# TASK-391: sit on a placed chair/bench. Once per real day PER PLACED
# INSTANCE (mirrors ForageNode's day-cooldown shape via
# GameData.furniture_sit_last_day). Success grants a small flat +5
# harmony -- the modest capped-small-bonus feel of
# GameData.record_weekly_engagement()'s +1..+5 range, deliberately not
# a stat swing that could compete with the bed's full-restore sleep.
func _interact_sit(cell: Vector2i) -> void:
	var key: String = _cell_key(cell)
	var day: int = _current_day()
	if int(GameData.furniture_sit_last_day.get(key, -1)) == day:
		SignalBus.show_dialogue.emit("Farmer", SIT_COOLDOWN_LINE)
		return
	GameData.furniture_sit_last_day[key] = day
	GameData.add_harmony(5)
	SignalBus.show_dialogue.emit("Farmer", SIT_LINE)

# TASK-391: put a marigold in a placed vase. Per-instance flower state in
# GameData.vase_has_flowers (string-keyed, see _cell_key). Filling
# consumes exactly 1 marigold, once; a filled vase stays filled (repeat
# interacts show the already-done line, mirroring FlavorNPC's
# post-one-shot normal-cycle fallback register); an empty vase with no
# marigold held prompts for a flower instead of silently doing nothing.
func _interact_vase(cell: Vector2i) -> void:
	var key: String = _cell_key(cell)
	if bool(GameData.vase_has_flowers.get(key, false)):
		SignalBus.show_dialogue.emit("Farmer", VASE_HAS_FLOWER_LINE)
		return
	if not GameData.has_item("marigold", 1):
		SignalBus.show_dialogue.emit("Farmer", VASE_NEEDS_FLOWER_LINE)
		return
	GameData.remove_item("marigold", 1)
	GameData.vase_has_flowers[key] = true
	SignalBus.show_dialogue.emit("Farmer", VASE_FILLED_LINE)

# TASK-391: listen to a placed radio. Repeatable, no cooldown -- the
# message is assembled from LIVE state on every call (forecast, festival
# countdown, headman quest hint), never memoized. Exactly ONE
# show_dialogue emit (this project has no dialogue queue -- a second
# emit would overwrite the first).
func _interact_radio() -> void:
	SignalBus.show_dialogue.emit("Radio", _radio_message())

# TASK-391: build the radio's combined message from live state: (1)
# tomorrow's forecast read directly off SignalBus.time_manager.
# next_weather (already rolled and kept current -- no other query
# needed), (2) days until the next festival across all 7 (day, season)
# pairs in FESTIVAL_DATES, (3) a hint about a currently-active
# headman-given quest if one exists, omitted entirely otherwise.
# Written as one natural message, not three labeled fields.
func _radio_message() -> String:
	var tm: Node = SignalBus.time_manager
	var forecast: String = ""
	if tm != null and "next_weather" in tm:
		forecast = String(tm.next_weather)
	var parts: Array[String] = []
	if forecast == "":
		parts.append("The forecast is just static tonight.")
	else:
		parts.append("Tomorrow looks %s." % forecast)
	var next: Dictionary = _next_festival()
	if not next.is_empty():
		var days: int = int(next.get("days", 0))
		var fname: String = String(next.get("name", "the festival"))
		if days <= 0:
			parts.append("%s is today." % fname)
		else:
			parts.append("%s comes in %d %s." % [fname, days, "day" if days == 1 else "days"])
	var hint: String = _headman_quest_hint()
	if hint != "":
		parts.append(hint)
	return " ".join(parts)

# TASK-391: minimum days-from-now across all 7 (festival_day, season)
# pairs, given the CURRENT day/season. Uses TimeManager's real season
# order (seasons Array) and season length, so the wraparound is correct
# across a season boundary AND a full year wraparound -- not just the
# same-season case. Each (day, season) pair recurs once per year, so a
# same-season festival whose day already passed is ~a year away, not
# negative. Returns {"name": String, "days": int}.
func _next_festival() -> Dictionary:
	var tm: Node = SignalBus.time_manager
	var day: int = 1
	var season: String = "cool"
	if tm != null:
		if "day" in tm:
			day = int(tm.day)
		if "current_season" in tm:
			season = String(tm.current_season)
	var season_len: int = 30
	if tm != null and "season_duration_days" in tm:
		season_len = maxi(int(tm.season_duration_days), 1)
	var order: Array = ["hot", "monsoon", "cool"]
	if tm != null and "seasons" in tm:
		var live: Array = (tm.seasons as Array).duplicate()
		if not live.is_empty():
			order = live
	var dos: int = ((day - 1) % season_len) + 1
	if tm != null and tm.has_method("day_of_season"):
		dos = int(tm.call("day_of_season"))
	var cur_idx: int = maxi(order.find(season), 0)
	var year_len: int = season_len * maxi(order.size(), 1)
	var best: Dictionary = {}
	for entry: Dictionary in FESTIVAL_DATES:
		var fday: int = int(entry.get("day", 1))
		var fseason: String = String(entry.get("season", "cool"))
		var ahead: int = (order.find(fseason) - cur_idx + order.size()) % order.size()
		var delta: int
		if ahead == 0:
			delta = fday - dos
			if delta < 0:
				# Already passed this season -- next occurrence is a
				# full year out (rest of this season + the other two
				# full seasons + fday into the next occurrence).
				delta = (season_len - dos) + (order.size() - 1) * season_len + fday
		else:
			# Rest of this season + full seasons in between + fday.
			delta = (season_len - dos) + (ahead - 1) * season_len + fday
		if best.is_empty() or delta < int(best.get("days", 0)):
			best = {"name": String(entry.get("name", "the festival")), "days": delta}
	return best

# TASK-391: short hint about a currently-active headman-given quest, or
# "" when there is none (the caller omits this part entirely -- no
# placeholder). Active-quest state is GameData.active_quests (quest_id
# -> {...}); giver lookup goes through the live QuestLog's chains
# (group "quest_log", loaded from data/quests/quests.json), never a
# hardcoded quest id. Completed quests are skipped -- a paid-out quest
# is not "currently active" even though it lingers in active_quests
# (see QuestLog's own Phase 3 audit note on that).
# Verified 2026-09-05: no quest in quests.json currently has
# giver_npc_id "headman", so the omit-path is the live behavior until a
# headman quest ships -- the hint path is covered by tests via an
# injected chain, not live data.
func _headman_quest_hint() -> String:
	var active: Dictionary = GameData.active_quests
	if active.is_empty():
		return ""
	if not is_inside_tree():
		return ""
	var ql: Node = get_tree().get_first_node_in_group("quest_log")
	if ql == null or not ql.has_method("get_chain"):
		return ""
	for quest_id: String in active.keys():
		if GameData.is_quest_complete(quest_id):
			continue
		var chain: Dictionary = ql.call("get_chain", quest_id) as Dictionary
		if String(chain.get("giver_npc_id", "")) != "headman":
			continue
		var title: String = String(chain.get("display_name", String(quest_id).replace("_", " ")))
		return "The headman still waits on '%s'." % title
	return ""

func _on_furniture_changed(location_id: String, item_id: String, cell: Vector2i, is_placed: bool) -> void:
	if location_id != LOCATION_ID:
		return
	var sprite_name: String = "%s_%d_%d" % [_display_name_for(item_id), cell.x, cell.y]
	# Resolve the current facing for this cell (if any). Used to
	# (re)apply rotation_degrees whenever the sprite (re)spawns --
	# whether it's the first place, a pickup-then-replace cycle, or
	# the rotation itself (which re-emits the placed signal).
	var facing: int = 0
	if is_placed:
		var entry: Dictionary = GameData.get_placed_furniture_at(LOCATION_ID, cell)
		facing = int(entry.get("facing", 0))
	if is_placed:
		if has_node(sprite_name):
			# Already live (rotation re-emit, or refresh) -- just
			# update rotation_degrees in case it changed.
			var existing: Sprite2D = get_node(sprite_name) as Sprite2D
			if existing != null:
				existing.rotation_degrees = float(facing) * 90.0
			return
		var sprite := Sprite2D.new()
		sprite.name = sprite_name
		sprite.texture = load(_texture_path_for(item_id))
		sprite.position = Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE / 2.0)
		sprite.rotation_degrees = float(facing) * 90.0
		add_child(sprite)
	else:
		if has_node(sprite_name):
			get_node(sprite_name).queue_free()

func _refresh_rugs() -> void:
	# Re-materialize any furniture already placed (e.g. loaded from a
	# save) that doesn't have a live sprite yet. The signal handler
	# does the actual spawn; we just drive it with the persisted data
	# so old saves re-appear at the right rotation.
	var list: Array = GameData.placed_furniture.get(LOCATION_ID, [])
	for entry: Dictionary in list:
		_on_furniture_changed(LOCATION_ID, String(entry.get("item_id", "")), entry.get("cell", Vector2i.ZERO), true)
