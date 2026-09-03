extends Node2D
# World — Hybrid A/B (Isan 20×16 + 3×3 lotus maze), EN, 16-color
# TASK-352: renamed from World. Orchestrates TimeManager + GridManager +
# MonkNPC + Player + HUD + Dialogue + Seasonal tint.

@onready var dialogue_label: Label = $DialogueLayer/Panel/DialogueLabel if has_node("DialogueLayer/Panel/DialogueLabel") else null
@onready var dialogue_panel: Panel = $DialogueLayer/Panel if has_node("DialogueLayer/Panel") else null
@onready var dialogue_portrait: TextureRect = $DialogueLayer/Panel/Portrait if has_node("DialogueLayer/Panel/Portrait") else null
@onready var tint_rect: ColorRect = $TintLayer/TintRect if has_node("TintLayer/TintRect") else null

var _dialogue_tween: Tween

# Speaker name -> portrait art. Keyed by the exact strings each script already
# passes to SignalBus.show_dialogue (Elder/Child/Handler/Monk/Trader/Buffalo).
# Speakers with no portrait (System, Camera, Farmer) just hide the slot.
const PORTRAIT_PATHS: Dictionary = {
	"Elder": "res://assets/ui/portraits/elder.png",
	"Child": "res://assets/ui/portraits/child.png",
	"Handler": "res://assets/ui/portraits/handler.png",
	"Monk": "res://assets/ui/portraits/monk.png",
	"Trader": "res://assets/ui/portraits/trader.png",
	"Buffalo": "res://assets/ui/portraits/buffalo.png",
}

func _ready() -> void:
	# world render first (TASK-007): builds layers/props/bounds into World now that
	# children are readied
	var wr := get_node_or_null("WorldRender")
	if wr and wr.has_method("build"):
		wr.build(self)
	# TASK-352: register the per-area render node so scene-tree-bound
	# lookups (`get_parent().get_node("WorldRender")`) can be replaced
	# with `SignalBus.world_render` across all area scripts.
	if wr != null:
		SignalBus.world_render = wr
	SignalBus.show_dialogue.connect(_on_show_dialogue)
	SignalBus.season_changed.connect(_on_season_tint)
	SignalBus.weather_changed.connect(_on_weather)
	# init tint
	_on_season_tint(GameData.current_season)
	# seed demo inventory for first Binthabat if empty (so new game can offer)
	if GameData.inventory.is_empty():
		GameData.add_item("rice_grain", 2)
		GameData.add_item("seed_rice", 3)
		# TASK-044 decision: machete ships in starting inventory (no equip
		# system; stem-felling gate checks has_item only).
		GameData.add_item("machete", 1)
	# TASK-352: if we just arrived via SceneLoader, find the matching door
	# in the "door" group and spawn the player at door + offset; otherwise
	# (fresh boot / loaded save with no pending warp) fall back to the
	# historical default of (480, 384) so existing saves keep their spawn.
	var pl := get_node_or_null("Player")
	if pl:
		# TASK-357: a save/load restore takes precedence over door-warp
		# resolution — SaveManager.load_game() sets this to the EXACT
		# position the save was made at, which may not be anywhere near a
		# door (a save can happen mid-farm, not just standing at an exit).
		if SignalBus.has_pending_load_position:
			pl.global_position = SignalBus.pending_load_position
			SignalBus.has_pending_load_position = false
		elif SignalBus.pending_warp_id != "":
			var door_node: Node = null
			for d in get_tree().get_nodes_in_group("door"):
				if d is Node2D and String((d as Node).get("warp_id")) == SignalBus.pending_warp_id:
					door_node = d
					break
			if door_node != null:
				pl.global_position = (door_node as Node2D).global_position + Vector2((door_node as Node).get("spawn_offset"))
			else:
				pl.global_position = Vector2(10 * 48, 8 * 48)
			# Consume the pending warp so a later unrelated scene load
			# doesn't misinterpret a stale value.
			SignalBus.pending_warp_id = ""
		else:
			pl.global_position = Vector2(10 * 48, 8 * 48)
	# TASK-038 (PO_INBOX directive #1): buffalo unlock — instance the dormant
	# TASK-020 scene into the pasture zone. Programmatic (not .tscn) so the
	# art lane's in-flight World.tscn sprint stays conflict-free.
	_ensure_trader()
	_ensure_buffalo()
	# TASK-039 (PO_INBOX directive #2): game-state flow — dormant
	# TitleScreen/PauseMenu now wired (boot on title, P/Esc pauses).
	_ensure_game_flow()
	# TASK-040 (PO_INBOX directive #3): festival wiring — Loy Krathong live.
	_ensure_festival()
	# TASK-041: debug perf probe (no-op in release via OS.is_debug_build() guard).
	_ensure_profiler_overlay()
	# TASK-044: banana harvest unlock at the existing banana prop (4,12).
	_ensure_banana_tree()
	# TASK-046: Songkran festival trigger (hot season day 3).
	_ensure_songkran()
	# TASK-319: Fishing competition festival (hot season day 15).
	_ensure_fishing_competition()
	# TASK-330: monsoon festival density — Asalha Bucha (monsoon day 5).
	_ensure_asalha_bucha()
	# TASK-330: Ok Phansa, end of the rains retreat (monsoon day 28).
	_ensure_ok_phansa()
	# TASK-048: cat companion follows the farmer.
	_ensure_companion()
	# TASK-049: chicken coop — daily egg (pasture edge).
	_ensure_chicken_coop()
	# TASK-050: fishing spot on the canal; rod ships in inventory (decision).
	_ensure_fishing_spot()
	# TASK-321: mining spot — stamina-gated, no tool requirement, always-on.
	_ensure_mining_spot()
	# TASK-337: mountain cave — secondary unlockable spot, gated on
	# GameData.mining_skill reaching cap. Run once at boot so a loaded save
	# with mining_skill already at 3 gets the spot immediately, then again
	# from the minute_ticked handler so a freshly-earned cap also unlocks
	# it without needing a reload.
	_ensure_mountain_cave()
	# TASK-343: deep canal bend (fishing) and sacred grove (wood) — the
	# other two unlockable areas. Same pattern as TASK-337: each gated on
	# an already-persisted stat (fishing_skill / companion_bond_tier),
	# checked at boot AND from the same minute_ticked handler so a loaded
	# save with the stat already met shows the spot immediately, and a
	# freshly-earned cap unlocks it without a reload. Do NOT add a second
	# minute_ticked subscription — extend the existing handler instead.
	_ensure_deep_canal()
	# TASK-357: sacred grove moved to CoastalArea (Phase-1 cluster split
	# — see CoastalArea.gd). Its gating logic + minute_ticked poll now
	# live there; removed from this file so the spot is created under
	# CoastalArea, not under World.
	# TASK-344: lotus maze shore (fishing, milestones-gated) — kept in
	# World. Coastal trading post moved to CoastalArea (Phase-1 cluster
	# split — see CoastalArea.gd); its gating logic + minute_ticked poll
	# now live there. Removed from this file.
	_ensure_lotus_maze_shore()
	SignalBus.minute_ticked.connect(_on_minute_ticked_unlocks)
	# TASK-332: repeatable side-quest noticeboard (separate from QuestLog).
	_ensure_noticeboard()
	# TASK-340: rival win/loss clock (PAIRS empty until TASK-342 wires
	# real candidates — inert but present so save/load and the daily
	# tick machinery are proven before any content depends on them).
	_ensure_rival_clock()
	# TASK-270: Wing Kwai buffalo race (mounted minigame).
	_ensure_buffalo_race()

func _ensure_rival_clock() -> void:
	if get_node_or_null("RivalClock") != null:
		return
	var script: GDScript = load("res://scripts/core/RivalClock.gd")
	if script == null:
		return
	var clock: Node = script.new()
	clock.name = "RivalClock"
	add_child(clock)

func _ensure_buffalo_race() -> void:
	if get_node_or_null("BuffaloRace") != null:
		return
	var script: GDScript = load("res://scripts/interactables/BuffaloRace.gd")
	if script == null:
		return
	var race: Node = script.new()
	race.name = "BuffaloRace"
	add_child(race)
	# TASK-052: peer NPCs Ek + Fah (romance candidates).
	_ensure_peer_npcs()
	# TASK-057: quest chains (QuestLog listens for objective events).
	_ensure_quest_log()
	# ISSUE-133: forest trees — wood gathering (axe bonus).
	_ensure_forest()
	# ISSUE-134: Lopburi monkey raid + Crop Truce (hot day 9).
	_ensure_lopburi()
	# TASK-303: race official stand — in-game entry to the Wing Kwai race.
	_ensure_race_starter()
	# TASK-304 scaffold (art): checkpoint flag course (z=-6, below actors).
	_ensure_race_course()

func _ensure_race_starter() -> void:
	if get_node_or_null("RaceStarter") != null:
		return
	var scene: PackedScene = load("res://scenes/festival/RaceStarter.tscn")
	if scene == null:
		return
	var starter: Node2D = scene.instantiate() as Node2D
	if starter == null:
		return
	starter.name = "RaceStarter"
	starter.position = Vector2(216, 552) # beside checkpoint 1 flag (168,528)
	add_child(starter)

func _ensure_race_course() -> void:
	if get_node_or_null("WingKwaiCourse") != null:
		return
	var scene: PackedScene = load("res://scenes/festival/WingKwaiCourse.tscn")
	if scene == null:
		return
	var course: Node2D = scene.instantiate() as Node2D
	if course == null:
		return
	course.name = "WingKwaiCourse"
	course.z_index = -6
	add_child(course)

func _ensure_lopburi() -> void:
	if get_node_or_null("LopburiRaid") != null:
		return
	var script: GDScript = load("res://scenes/festival/LopburiRaid.gd")
	if script == null:
		return
	var raid: Node = script.new()
	raid.name = "LopburiRaid"
	add_child(raid)

func _ensure_forest() -> void:
	var scene: PackedScene = load("res://scenes/entities/ForestTree.tscn")
	if scene == null:
		return
	for cell: Vector2i in [Vector2i(18, 3), Vector2i(18, 5), Vector2i(19, 4)]:
		var name: String = "ForestTree%d_%d" % [cell.x, cell.y]
		if get_node_or_null(name) != null:
			continue
		var tree: Node2D = scene.instantiate() as Node2D
		if tree == null:
			continue
		tree.name = name
		tree.position = Vector2(cell.x * 48 + 24, (cell.y + 1) * 48)
		add_child(tree)

func _ensure_trader() -> void:
	if get_node_or_null("TraderNPC") != null:
		return
	var scene: PackedScene = load("res://scenes/entities/TraderNPC.tscn")
	if scene == null:
		return
	var trader: Node2D = scene.instantiate() as Node2D
	if trader == null:
		return
	trader.name = "TraderNPC"
	trader.position = Vector2(15 * 48 + 24, 8 * 48) # near market
	add_child(trader)

func _ensure_quest_log() -> void:
	if get_node_or_null("QuestLog") != null:
		return
	var script: GDScript = load("res://scripts/persistence/QuestLog.gd")
	if script == null:
		return
	var log: Node = script.new()
	log.name = "QuestLog"
	add_child(log)
	# Fah offers 'first_catch', Elder offers 'morning_merit' on first talk.
	var fah: Node = get_node_or_null("FahNPC")
	if fah != null and fah.has_signal("interacted"):
		pass # RomanceNPC talks via SignalBus; QuestLog exposes offer API.
	# TASK-055: Wan Sart ancestor-honoring trigger (cool day 5).
	_ensure_wansart()
	# TASK-056: goat — daily goat_milk (pasture, beside the coop).
	_ensure_goat()

func _ensure_goat() -> void:
	if get_node_or_null("Goat") != null:
		return
	var scene: PackedScene = load("res://scenes/entities/Goat.tscn")
	if scene == null:
		return
	var goat: Node2D = scene.instantiate() as Node2D
	if goat == null:
		return
	goat.name = "Goat"
	goat.position = Vector2(3 * 48 + 24, 14 * 48) # pasture SW, next to coop
	add_child(goat)

func _ensure_wansart() -> void:
	if get_node_or_null("WanSartTrigger") != null:
		return
	var script: GDScript = load("res://scenes/festival/WanSartTrigger.gd")
	if script == null:
		return
	var trigger: Node = script.new()
	trigger.name = "WanSartTrigger"
	add_child(trigger)

func _ensure_peer_npcs() -> void:
	var spots: Dictionary = {
		"EkNPC": {"scene": "res://scenes/entities/EkNPC.tscn", "pos": Vector2(13 * 48 + 24, 5 * 48)},
		"FahNPC": {"scene": "res://scenes/entities/FahNPC.tscn", "pos": Vector2(10 * 48 + 24, 12 * 48)},
		# TASK-335: third romance candidate — temple-lane market stall, clear
		# of NongTonNPC/SomchaiNPC at (2,2)/(3,2).
		"PloyNPC": {"scene": "res://scenes/entities/PloyNPC.tscn", "pos": Vector2(6 * 48 + 24, 2 * 48)},
		# TASK-341: 3 more romance candidates, bringing the total to 6.
		# Positions re-verified clear of every spot in this dict as of
		# this task (see docs/research/TASK-341-spec.md).
		"ChangNPC": {"scene": "res://scenes/entities/ChangNPC.tscn", "pos": Vector2(8 * 48 + 24, 2 * 48)},
		"KlongNPC": {"scene": "res://scenes/entities/KlongNPC.tscn", "pos": Vector2(3 * 48 + 24, 9 * 48)},
		"YaaNPC": {"scene": "res://scenes/entities/YaaNPC.tscn", "pos": Vector2(17 * 48 + 24, 7 * 48)},
		# TASK-058 schedules cover headman/vet movement; SCHEDULES keys match.
		"HeadmanNPC": {"scene": "res://scenes/entities/HeadmanNPC.tscn", "pos": Vector2(1 * 48 + 24, 3 * 48)},
		"VetNPC": {"scene": "res://scenes/entities/VetNPC.tscn", "pos": Vector2(2 * 48 + 24, 14 * 48)},
		# ISSUE-132: Phi Ta Khon villagers (festival hosts).
		"NongTonNPC": {"scene": "res://scenes/entities/NongTonNPC.tscn", "pos": Vector2(2 * 48 + 24, 2 * 48)},
		"SomchaiNPC": {"scene": "res://scenes/entities/SomchaiNPC.tscn", "pos": Vector2(3 * 48 + 24, 2 * 48)},
		# TASK-342: 6 rival NPCs, one per paired candidate. Positions
		# re-verified clear of every spot in this dict + the World scene's
		# own sprites (player/buffalo/coop/companion/etc) as of this task.
		"YaiNPC": {"scene": "res://scenes/entities/YaiNPC.tscn", "pos": Vector2(14 * 48 + 24, 4 * 48)},
		"OhmNPC": {"scene": "res://scenes/entities/OhmNPC.tscn", "pos": Vector2(9 * 48 + 24, 12 * 48)},
		"RungNPC": {"scene": "res://scenes/entities/RungNPC.tscn", "pos": Vector2(7 * 48 + 24, 3 * 48)},
		"NoteNPC": {"scene": "res://scenes/entities/NoteNPC.tscn", "pos": Vector2(9 * 48 + 24, 3 * 48)},
		"FonNPC": {"scene": "res://scenes/entities/FonNPC.tscn", "pos": Vector2(2 * 48 + 24, 9 * 48)},
		"BoonNPC": {"scene": "res://scenes/entities/BoonNPC.tscn", "pos": Vector2(18 * 48 + 24, 8 * 48)},
	}
	for npc_name: String in spots.keys():
		if get_node_or_null(npc_name) != null:
			continue
		var scene: PackedScene = load(String(spots[npc_name]["scene"]))
		if scene == null:
			continue
		var npc: Node2D = scene.instantiate() as Node2D
		if npc == null:
			continue
		npc.name = npc_name
		npc.position = spots[npc_name]["pos"]
		add_child(npc)

func _ensure_fishing_spot() -> void:
	if get_node_or_null("FishingSpot") != null:
		return
	var script: GDScript = load("res://scripts/interactables/FishingSpot.gd")
	if script == null:
		return
	var spot: Node2D = script.new() as Node2D
	if spot == null:
		return
	spot.name = "FishingSpot"
	spot.position = Vector2(11 * 48 + 24, 13 * 48 - 48) # canal row north bank
	add_child(spot)
	if GameData.inventory.is_empty() or not GameData.has_item("fishing_rod", 1):
		GameData.add_item("fishing_rod", 1)

func _ensure_mining_spot() -> void:
	if get_node_or_null("MiningSpot") != null:
		return
	var script: GDScript = load("res://scripts/interactables/MiningSpot.gd")
	if script == null:
		return
	var spot: Node2D = script.new() as Node2D
	if spot == null:
		return
	spot.name = "MiningSpot"
	# Tile (1, 3) — top-left corner, away from canal/fishing (col 11), pasture
	# (rows 12-15), temple (840, 168), and player spawn (480, 384). No sprite
	# for MVP — invisible interact zone, mirroring FishingSpot's own precedent.
	spot.position = Vector2(1 * 48 + 24, 3 * 48 + 24)
	add_child(spot)

func _ensure_mountain_cave() -> void:
	# TASK-337: gated on GameData.mining_skill >= 3 (the cap). Derive the
	# unlock state live each call so a save from before this task ships
	# unlocks correctly the moment it loads — no persisted flag, no schema
	# bump. Called once from _ready() (covers loaded-save boot) and again
	# from the minute_ticked handler (covers freshly-earned cap in-session).
	if GameData.mining_skill < 3:
		return
	if get_node_or_null("MountainCaveSpot") != null:
		return
	var script: GDScript = load("res://scripts/interactables/MountainCaveSpot.gd")
	if script == null:
		return
	var spot: Node2D = script.new() as Node2D
	if spot == null:
		return
	spot.name = "MountainCaveSpot"
	# Tile (19, 14) — SE corner, verified clear of every other position in
	# World.gd / World.tscn. Centered in the tile (24, 24 offset) like the
	# other interactable spots. No sprite for MVP — invisible interact zone,
	# mirroring MiningSpot/Noticeboard's precedent.
	spot.position = Vector2(19 * 48 + 24, 14 * 48 + 24)
	add_child(spot)

func _on_minute_ticked_unlocks(_day: int, _hour: int, _minute: int) -> void:
	# TASK-337 + TASK-343 + TASK-344: lazy unlock poll. Cheap (one int
	# compare + get_node_or_null per spot per tick); runs even after the
	# spot already exists so it stays idempotent. World has no other
	# minute_ticked subscription of its own — every other system owns
	# its own — so this is intentionally the only one in this file.
	# TASK-357: sacred grove and coastal trading post moved to
	# CoastalArea; their lazy-unlock is now driven by CoastalArea's own
	# _on_minute_ticked_unlocks() handler (subscribed once in
	# CoastalArea._build_render). Removed from this poll so the spots
	# are only created under their new owning area, not under World.
	_ensure_mountain_cave()
	_ensure_deep_canal()
	_ensure_lotus_maze_shore()

func _ensure_deep_canal() -> void:
	# TASK-343: gated on GameData.fishing_skill >= 4 (the cap, the same
	# threshold as the master_angler milestone). Derive the unlock state
	# live each call so a save from before this task ships unlocks
	# correctly the moment it loads — no persisted flag, no schema bump.
	# Called once from _ready() (covers loaded-save boot) and again from
	# the minute_ticked handler (covers freshly-earned cap in-session).
	if GameData.fishing_skill < 4:
		return
	if get_node_or_null("DeepCanalSpot") != null:
		return
	var script: GDScript = load("res://scripts/interactables/DeepCanalSpot.gd")
	if script == null:
		return
	var spot: Node2D = script.new() as Node2D
	if spot == null:
		return
	spot.name = "DeepCanalSpot"
	# Tile (12, 14) — verified via headless ground_at() probe: tile
	# (12,14) is ground_grass (walkable) and its north neighbor (12,13)
	# is canal, satisfying _water_adjacent(). Clear of every other node's
	# position in World.gd / World.tscn. No sprite for MVP — invisible
	# interact zone, mirroring MiningSpot/Noticeboard/MountainCaveSpot's
	# precedent.
	spot.position = Vector2(12 * 48 + 24, 14 * 48)
	add_child(spot)

func _ensure_lotus_maze_shore() -> void:
	# TASK-344: gated on GameData.milestones_earned.size() >= 5 — every
	# TASK-331 milestone earned (deep_miner, master_angler, inseparable,
	# herd_keeper, storm_catch). The "completionist" capstone, not a
	# single-skill gate. Derive the unlock state live each call — no
	# persisted flag, no schema bump. Called once from _ready() (covers
	# loaded-save boot) and again from the minute_ticked handler.
	if (GameData.milestones_earned as Dictionary).size() < 5:
		return
	if get_node_or_null("LotusMazeShoreSpot") != null:
		return
	var script: GDScript = load("res://scripts/interactables/LotusMazeShoreSpot.gd")
	if script == null:
		return
	var spot: Node2D = script.new() as Node2D
	if spot == null:
		return
	spot.name = "LotusMazeShoreSpot"
	# Tile (13, 11) — verified via headless ground_at() probe: tile
	# (13,11) is plantable_soil (walkable) and its east neighbor
	# (14,11) is deep_pond (inside the lotus maze interior), satisfying
	# _water_adjacent(). The maze interior itself (cols 14-16 rows 10-12)
	# is non-walkable, so the spot sits on the walkable edge, mirroring
	# FishingSpot.gd's own water-adjacency check. No sprite for MVP —
	# invisible interact zone, same precedent as MiningSpot /
	# MountainCaveSpot / DeepCanalSpot / SacredGroveSpot.
	spot.position = Vector2(13 * 48 + 24, 11 * 48)
	add_child(spot)

func _ensure_noticeboard() -> void:
	if get_node_or_null("Noticeboard") != null:
		return
	var script: GDScript = load("res://scripts/interactables/Noticeboard.gd")
	if script == null:
		return
	var board: Node2D = script.new() as Node2D
	if board == null:
		return
	board.name = "Noticeboard"
	# Tile (16, 9) — market lane, SE of the trader (15,8), clear of the
	# carpenter (18,8), the mango tree prop (17,10), temple lane (row 3),
	# and the maze pond (cols 14-16, rows 10-12). No sprite for MVP —
	# invisible interact zone, mirroring FishingSpot/MiningSpot's precedent.
	board.position = Vector2(16 * 48 + 24, 9 * 48)
	add_child(board)

func _ensure_chicken_coop() -> void:
	if get_node_or_null("ChickenCoop") != null:
		return
	var scene: PackedScene = load("res://scenes/entities/ChickenCoop.tscn")
	if scene == null:
		return
	var coop: Node2D = scene.instantiate() as Node2D
	if coop == null:
		return
	coop.name = "ChickenCoop"
	coop.position = Vector2(2 * 48 + 24, 14 * 48) # pasture SW corner
	add_child(coop)

func _ensure_companion() -> void:
	if get_node_or_null("CompanionNPC") != null:
		return
	var scene: PackedScene = load("res://scenes/entities/CatCompanion.tscn")
	if scene == null:
		return
	var cat: CharacterBody2D = scene.instantiate() as CharacterBody2D
	if cat == null:
		return
	cat.name = "CompanionNPC"
	cat.set("script", load("res://scenes/entities/CompanionNPC.gd"))
	cat.position = Vector2(10 * 48 + 24, 9 * 48)
	var wr: Node = get_node_or_null("WorldRender")
	if wr != null:
		cat.set("world_render", wr)
	add_child(cat)

func _ensure_songkran() -> void:
	if get_node_or_null("SongkranTrigger") != null:
		return
	var script: GDScript = load("res://scenes/festival/SongkranTrigger.gd")
	if script == null:
		return
	var trigger: Node = script.new()
	trigger.name = "SongkranTrigger"
	add_child(trigger)

func _ensure_fishing_competition() -> void:
	if get_node_or_null("FishingCompetitionTrigger") != null:
		return
	var script: GDScript = load("res://scenes/festival/FishingCompetitionTrigger.gd")
	if script == null:
		return
	var trigger: Node = script.new()
	trigger.name = "FishingCompetitionTrigger"
	add_child(trigger)

func _ensure_asalha_bucha() -> void:
	if get_node_or_null("AsalhaBuchaTrigger") != null:
		return
	var script: GDScript = load("res://scenes/festival/AsalhaBuchaTrigger.gd")
	if script == null:
		return
	var trigger: Node = script.new()
	trigger.name = "AsalhaBuchaTrigger"
	add_child(trigger)

func _ensure_ok_phansa() -> void:
	if get_node_or_null("OkPhansaTrigger") != null:
		return
	var script: GDScript = load("res://scenes/festival/OkPhansaTrigger.gd")
	if script == null:
		return
	var trigger: Node = script.new()
	trigger.name = "OkPhansaTrigger"
	add_child(trigger)

func _ensure_banana_tree() -> void:
	if get_node_or_null("BananaTree") != null:
		return
	var scene: PackedScene = load("res://scenes/entities/BananaTree.tscn")
	if scene == null:
		return
	var tree: Node2D = scene.instantiate() as Node2D
	if tree == null:
		return
	tree.name = "BananaTree"
	tree.position = Vector2(4 * 48 + 24, 13 * 48)
	add_child(tree)
	# TASK-029: crafting unlock — clay stove consumes recipes.json.
	_ensure_cooking_station()

func _ensure_cooking_station() -> void:
	if get_node_or_null("CookingStation") != null:
		return
	var scene: PackedScene = load("res://scenes/interactables/CookingStation.tscn")
	if scene == null:
		return
	var station: Node2D = scene.instantiate() as Node2D
	if station == null:
		return
	station.name = "CookingStation"
	# Hall floor zone (rect 6,14,3,2): cell (7,15), Y-sorted.
	station.position = Vector2(7 * 48 + 24, 16 * 48)
	add_child(station)

func _ensure_festival() -> void:
	if get_node_or_null("FestivalManager") != null:
		return
	var script: GDScript = load("res://scenes/festival/FestivalManager.gd")
	if script == null:
		return
	var manager: Node = script.new()
	manager.name = "FestivalManager"
	add_child(manager)

func _ensure_profiler_overlay() -> void:
	if get_node_or_null("ProfilerOverlay") != null:
		return
	var overlay: CanvasLayer = load("res://scripts/core/ProfilerOverlay.gd").new()
	overlay.name = "ProfilerOverlay"
	add_child(overlay)

func _ensure_game_flow() -> void:
	if get_node_or_null("TitleScreen") == null:
		var title_scene: PackedScene = load("res://scenes/ui/TitleScreen.tscn")
		if title_scene != null:
			var title: CanvasLayer = title_scene.instantiate() as CanvasLayer
			title.name = "TitleScreen"
			add_child(title)
			_wire_title_buttons(title)
	if get_node_or_null("PauseMenu") == null:
		var pause_scene: PackedScene = load("res://scenes/ui/PauseMenu.tscn")
		if pause_scene != null:
			var pause: CanvasLayer = pause_scene.instantiate() as CanvasLayer
			pause.name = "PauseMenu"
			add_child(pause)
			_wire_pause_buttons(pause)

func _wire_title_buttons(title: CanvasLayer) -> void:
	var new_game: BaseButton = title.find_child("NewGame", true, false) as BaseButton
	if new_game != null:
		new_game.pressed.connect(_on_new_game)
	var settings_btn: BaseButton = title.find_child("Settings", true, false) as BaseButton
	if settings_btn != null:
		settings_btn.pressed.connect(_on_toggle_settings)
	var quit_btn: BaseButton = title.find_child("Quit", true, false) as BaseButton
	if quit_btn != null:
		quit_btn.pressed.connect(_on_quit_app)

func _wire_pause_buttons(pause: CanvasLayer) -> void:
	var resume: BaseButton = pause.find_child("Resume", true, false) as BaseButton
	if resume != null:
		resume.pressed.connect(_on_resume)
	var quit_btn: BaseButton = pause.find_child("Quit", true, false) as BaseButton
	if quit_btn != null:
		quit_btn.pressed.connect(_on_quit_to_title)
	# ENGINE-013: save/load entry points (SaveManager instanced lazily).
	var save_btn: BaseButton = pause.find_child("Save", true, false) as BaseButton
	if save_btn != null:
		save_btn.pressed.connect(_on_save_game)
	var load_btn: BaseButton = pause.find_child("Load", true, false) as BaseButton
	if load_btn != null:
		load_btn.pressed.connect(_on_load_game)

func _ensure_save_manager() -> Node:
	if get_node_or_null("SaveManager") != null:
		return get_node("SaveManager")
	var script: GDScript = load("res://scripts/persistence/SaveManager.gd")
	if script == null:
		return null
	var manager: Node = script.new()
	manager.name = "SaveManager"
	add_child(manager)
	return manager

func _on_save_game() -> void:
	var sm: Node = _ensure_save_manager()
	if sm != null and sm.save_game():
		SignalBus.show_dialogue.emit("System", "Progress saved.")
	else:
		SignalBus.show_dialogue.emit("System", "Could not save right now.")

func _on_load_game() -> void:
	var sm: Node = _ensure_save_manager()
	if sm != null and sm.load_game():
		SignalBus.show_dialogue.emit("System", "Progress loaded.")
	else:
		SignalBus.show_dialogue.emit("System", "No save found.")

func _is_title_up() -> bool:
	var title: CanvasLayer = get_node_or_null("TitleScreen") as CanvasLayer
	return title != null and title.visible

func _on_new_game() -> void:
	var title: CanvasLayer = get_node_or_null("TitleScreen") as CanvasLayer
	if title != null:
		title.visible = false
	GameData.reset_stamina()
	SignalBus.show_dialogue.emit("System", "A new morning in the village.")

func _on_toggle_settings() -> void:
	var settings: CanvasLayer = get_node_or_null("Settings") as CanvasLayer
	if settings != null:
		settings.visible = not settings.visible

func _on_quit_app() -> void:
	get_tree().quit()

func _on_resume() -> void:
	get_tree().paused = false
	SignalBus.game_paused_changed.emit(false)
	var pause: CanvasLayer = get_node_or_null("PauseMenu") as CanvasLayer
	if pause != null:
		pause.visible = false

func _on_quit_to_title() -> void:
	get_tree().paused = false
	SignalBus.game_paused_changed.emit(false)
	var pause: CanvasLayer = get_node_or_null("PauseMenu") as CanvasLayer
	if pause != null:
		pause.visible = false
	var title: CanvasLayer = get_node_or_null("TitleScreen") as CanvasLayer
	if title != null:
		title.visible = true

func _toggle_pause() -> void:
	if _is_title_up():
		return
	var pause: CanvasLayer = get_node_or_null("PauseMenu") as CanvasLayer
	if pause == null:
		return
	pause.visible = not pause.visible
	get_tree().paused = pause.visible
	SignalBus.game_paused_changed.emit(get_tree().paused)

func _ensure_buffalo() -> void:
	if get_node_or_null("Buffalo") != null:
		return
	var scene: PackedScene = load("res://scenes/entities/Buffalo.tscn")
	if scene == null:
		return
	var buffalo: Node2D = scene.instantiate() as Node2D
	if buffalo == null:
		return
	buffalo.name = "Buffalo"
	# Pasture zone (rect 0,10,9,6): cell (4,12) center-bottom, y-sorted.
	buffalo.position = Vector2(4 * 48 + 24, 13 * 48)
	add_child(buffalo)
	# monk on temple lane E (cell 17,3), warm start at cool season 06:00
	if "--screenshot" in OS.get_cmdline_user_args():
		for i in 20:
			await get_tree().process_frame
		var out := "user://screenshot_auto.png"
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--screenshot-out="):
				out = arg.trim_prefix("--screenshot-out=")
		_capture_screenshot(out)
		get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		_capture_screenshot("user://screenshot_%s.png" % Time.get_datetime_string_from_system().replace(":", "").replace("-", "").replace(" ", "_"))
	# TASK-039: pause toggle on P / Esc.
	if event is InputEventKey and event.pressed and (event.keycode == KEY_P or event.keycode == KEY_ESCAPE):
		_toggle_pause()

func _capture_screenshot(path: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("Screenshot saved: %s" % path)
	SignalBus.show_dialogue.emit("Camera", "Screenshot saved.")

func _on_show_dialogue(speaker: String, text: String) -> void:
	if dialogue_label == null or dialogue_panel == null:
		print("[%s] %s" % [speaker, text])
		return
	dialogue_label.text = "%s: %s" % [speaker, text]
	dialogue_panel.visible = true
	if dialogue_portrait:
		var portrait_path: String = String(PORTRAIT_PATHS.get(speaker, ""))
		if portrait_path != "" and ResourceLoader.exists(portrait_path):
			dialogue_portrait.texture = load(portrait_path) as Texture2D
			dialogue_portrait.visible = true
		else:
			dialogue_portrait.visible = false
	if _dialogue_tween:
		_dialogue_tween.kill()
	_dialogue_tween = create_tween()
	dialogue_panel.modulate.a = 1.0
	_dialogue_tween.tween_interval(3.5)
	_dialogue_tween.tween_property(dialogue_panel, "modulate:a", 0.0, 0.6)
	_dialogue_tween.tween_callback(func(): dialogue_panel.visible = false)

func _on_season_tint(season: String) -> void:
	if tint_rect == null:
		return
	match season:
		"hot":
			tint_rect.color = Color(1.0, 0.6, 0.2, 0.18) # Hot Orange 25% approx
		"monsoon":
			tint_rect.color = Color(0.13, 0.59, 0.95, 0.14) # Monsoon Blue 20%
		"cool":
			tint_rect.color = Color(0.0, 0.59, 0.53, 0.08) # Cool Teal 15%
		_:
			tint_rect.color = Color(0,0,0,0)

func _on_weather(_weather: String) -> void:
	pass
