extends CanvasLayer
# TitleScreen — TASK-017 title screen + settings flow
# Shows on boot, handles New Game / Continue / Settings

signal new_game_requested
signal continue_requested
signal settings_requested

@onready var new_game_btn: Button = $Panel/VBox/NewGameBtn if has_node("Panel/VBox/NewGameBtn") else null
@onready var continue_btn: Button = $Panel/VBox/ContinueBtn if has_node("Panel/VBox/ContinueBtn") else null
@onready var settings_btn: Button = $Panel/VBox/SettingsBtn if has_node("Panel/VBox/SettingsBtn") else null
@onready var quit_btn: Button = $Panel/VBox/QuitBtn if has_node("Panel/VBox/QuitBtn") else null

func _ready() -> void:
	layer = 20
	if continue_btn:
		# Disable Continue if no save exists
		var has_save: bool = false
		if Engine.has_singleton("SaveManager") or ResourceLoader.exists("res://scripts/persistence/SaveManager.gd"):
			var SaveMgr: GDScript = load("res://scripts/persistence/SaveManager.gd")
			has_save = SaveMgr.has_save("autosave") if SaveMgr else false
		continue_btn.disabled = not has_save
		if has_save:
			continue_btn.tooltip_text = "Continue from autosave"
	if new_game_btn and not new_game_btn.pressed.is_connected(_on_new_game):
		new_game_btn.pressed.connect(_on_new_game)
	if continue_btn and not continue_btn.pressed.is_connected(_on_continue):
		continue_btn.pressed.connect(_on_continue)
	if settings_btn and not settings_btn.pressed.is_connected(_on_settings):
		settings_btn.pressed.connect(_on_settings)
	if quit_btn and not quit_btn.pressed.is_connected(_on_quit):
		quit_btn.pressed.connect(_on_quit)

func _on_new_game() -> void:
	emit_signal("new_game_requested")
	hide_title()

func _on_continue() -> void:
	emit_signal("continue_requested")
	hide_title()

func _on_settings() -> void:
	emit_signal("settings_requested")

func _on_quit() -> void:
	get_tree().quit()

func show_title() -> void:
	visible = true
	if new_game_btn:
		new_game_btn.grab_focus()

func hide_title() -> void:
	visible = false
