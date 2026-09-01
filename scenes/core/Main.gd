extends Node2D
# Main — Hybrid A/B (Isan 20×16 + 3×3 lotus maze), EN, 16-color
# Orchestrates TimeManager + GridManager + MonkNPC + Player + HUD + Dialogue + Seasonal tint.

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
	# world render first (TASK-007): builds layers/props/bounds into Main now that
	# children are readied
	var wr := get_node_or_null("WorldRender")
	if wr and wr.has_method("build"):
		wr.build(self)
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
	# position player near home center
	var pl := get_node_or_null("Player")
	if pl:
		pl.global_position = Vector2(10 * 48, 8 * 48)
	# TASK-038 (PO_INBOX directive #1): buffalo unlock — instance the dormant
	# TASK-020 scene into the pasture zone. Programmatic (not .tscn) so the
	# art lane's in-flight Main.tscn sprint stays conflict-free.
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
	# TASK-048: cat companion follows the farmer.
	_ensure_companion()
	# TASK-049: chicken coop — daily egg (pasture edge).
	_ensure_chicken_coop()
	# TASK-050: fishing spot on the canal; rod ships in inventory (decision).
	_ensure_fishing_spot()
	# TASK-270: Wing Kwai buffalo race (mounted minigame).
	_ensure_buffalo_race()

func _ensure_buffalo_race() -> void:
	if get_node_or_null("BuffaloRace") != null:
		return
	var script: GDScript = load("res://scripts/interactables/BuffaloRace.gd")
	if script == null:
		return
	var race: Node = script.new()
	race.name = "BuffaloRace"
	add_child(race)
	# TASK-052: peer NPCs Niran + Fah (romance candidates).
	_ensure_peer_npcs()
	# TASK-057: quest chains (QuestLog listens for objective events).
	_ensure_quest_log()
	# ISSUE-133: forest trees — wood gathering (axe bonus).
	_ensure_forest()
	# ISSUE-134: Lopburi monkey raid + Crop Truce (hot day 9).
	_ensure_lopburi()

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
		"NiranNPC": {"scene": "res://scenes/entities/NiranNPC.tscn", "pos": Vector2(13 * 48 + 24, 5 * 48)},
		"FahNPC": {"scene": "res://scenes/entities/FahNPC.tscn", "pos": Vector2(10 * 48 + 24, 12 * 48)},
		# TASK-058 schedules cover headman/vet movement; SCHEDULES keys match.
		"HeadmanNPC": {"scene": "res://scenes/entities/HeadmanNPC.tscn", "pos": Vector2(1 * 48 + 24, 3 * 48)},
		"VetNPC": {"scene": "res://scenes/entities/VetNPC.tscn", "pos": Vector2(2 * 48 + 24, 14 * 48)},
		# ISSUE-132: Phi Ta Khon villagers (festival hosts).
		"NongTonNPC": {"scene": "res://scenes/entities/NongTonNPC.tscn", "pos": Vector2(2 * 48 + 24, 2 * 48)},
		"SomchaiNPC": {"scene": "res://scenes/entities/SomchaiNPC.tscn", "pos": Vector2(3 * 48 + 24, 2 * 48)},
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
