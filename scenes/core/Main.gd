extends Node2D
# Main — Hybrid A/B (Isan 20×16 + 3×3 lotus maze), EN, 16-color
# Orchestrates TimeManager + GridManager + MonkNPC + Player + HUD + Dialogue + Seasonal tint.

@onready var dialogue_label: Label = $DialogueLayer/Panel/DialogueLabel if has_node("DialogueLayer/Panel/DialogueLabel") else null
@onready var dialogue_panel: Panel = $DialogueLayer/Panel if has_node("DialogueLayer/Panel") else null
@onready var tint_rect: ColorRect = $TintLayer/TintRect if has_node("TintLayer/TintRect") else null

var _dialogue_tween: Tween

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
