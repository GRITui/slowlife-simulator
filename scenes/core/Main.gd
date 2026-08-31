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
	# Title/pause flow (TASK-017)
	_setup_title_pause_flow()
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
	# Show title on boot (skip if --screenshot)
	if not "--screenshot" in OS.get_cmdline_user_args():
		var title: Node = get_node_or_null("TitleScreen")
		if title and title.has_method("show_title"):
			title.show_title()
			get_tree().paused = true
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

func _setup_title_pause_flow() -> void:
	var title: Node = get_node_or_null("TitleScreen")
	if title:
		if title.has_signal("new_game_requested"):
			title.new_game_requested.connect(_on_new_game)
		if title.has_signal("continue_requested"):
			title.continue_requested.connect(_on_continue)
		if title.has_signal("settings_requested"):
			title.settings_requested.connect(_on_settings_from_title)
	var pause_menu: Node = get_node_or_null("PauseMenu")
	if pause_menu:
		if pause_menu.has_signal("resume_requested"):
			pause_menu.resume_requested.connect(_on_resume)
		if pause_menu.has_signal("quit_to_title_requested"):
			pause_menu.quit_to_title_requested.connect(_on_quit_to_title)
		if pause_menu.has_signal("settings_requested"):
			pause_menu.settings_requested.connect(_on_settings_from_pause)

func _on_new_game() -> void:
	GameData.inventory.clear()
	GameData.harmony = 0
	GameData.current_stamina = GameData.max_stamina
	GameData.infrastructure.clear()
	GameData.daily_offerings = 0
	GameData.last_offering_day = -1
	var tm: Node = get_node_or_null("TimeManager")
	if tm and tm.has_method("set_time"):
		tm.set_time(1, 6, 0)
		tm.set_season("cool")
	var gm: Node = get_node_or_null("GridManager")
	if gm and "plots" in gm:
		gm.plots.clear()
	get_tree().paused = false
	SignalBus.show_dialogue.emit("System", "New game started.")

func _on_continue() -> void:
	var SaveMgr: GDScript = load("res://scripts/persistence/SaveManager.gd") if ResourceLoader.exists("res://scripts/persistence/SaveManager.gd") else null
	if SaveMgr and SaveMgr.has_save("autosave"):
		var tm: Node = get_node_or_null("TimeManager")
		var gm: Node = get_node_or_null("GridManager")
		if SaveMgr.load_game("autosave", tm, gm):
			SignalBus.show_dialogue.emit("System", "Game loaded.")
		else:
			SignalBus.show_dialogue.emit("System", "Load failed.")
	else:
		SignalBus.show_dialogue.emit("System", "No save found — starting new game.")
		_on_new_game()
	get_tree().paused = false

func _on_quit_to_title() -> void:
	var title: Node = get_node_or_null("TitleScreen")
	if title and title.has_method("show_title"):
		title.show_title()
		get_tree().paused = true

func _on_resume() -> void:
	get_tree().paused = false

func _on_settings_from_title() -> void:
	SignalBus.show_dialogue.emit("System", "Settings — audio/video coming soon.")

func _on_settings_from_pause() -> void:
	SignalBus.show_dialogue.emit("System", "Settings — audio/video coming soon.")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		_capture_screenshot("user://screenshot_%s.png" % Time.get_datetime_string_from_system().replace(":", "").replace("-", "").replace(" ", "_"))

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
