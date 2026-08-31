extends CanvasLayer
# PauseMenu — TASK-017 pause menu + settings flow
# Handles pause (ESC), resume, settings, quit to title

signal resume_requested
signal settings_requested
signal quit_to_title_requested

var is_paused: bool = false

@onready var resume_btn: Button = $Panel/VBox/ResumeBtn if has_node("Panel/VBox/ResumeBtn") else null
@onready var settings_btn: Button = $Panel/VBox/SettingsBtn if has_node("Panel/VBox/SettingsBtn") else null
@onready var quit_btn: Button = $Panel/VBox/QuitBtn if has_node("Panel/VBox/QuitBtn") else null

func _ready() -> void:
	layer = 15
	visible = false
	if resume_btn and not resume_btn.pressed.is_connected(_on_resume):
		resume_btn.pressed.connect(_on_resume)
	if settings_btn and not settings_btn.pressed.is_connected(_on_settings):
		settings_btn.pressed.connect(_on_settings)
	if quit_btn and not quit_btn.pressed.is_connected(_on_quit):
		quit_btn.pressed.connect(_on_quit)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if visible:
			_on_resume()
		else:
			# Only auto-pause if not on title screen
			var title: Node = get_parent().get_node_or_null("TitleScreen") if get_parent() else null
			if title == null or not title.visible:
				_pause_game()
		get_viewport().set_input_as_handled()

func _pause_game() -> void:
	is_paused = true
	visible = true
	get_tree().paused = true
	SignalBus.pause_toggled.emit(true)
	if resume_btn:
		resume_btn.grab_focus()

func _on_resume() -> void:
	is_paused = false
	visible = false
	get_tree().paused = false
	SignalBus.pause_toggled.emit(false)
	emit_signal("resume_requested")

func _on_settings() -> void:
	emit_signal("settings_requested")

func _on_quit() -> void:
	is_paused = false
	get_tree().paused = false
	SignalBus.pause_toggled.emit(false)
	visible = false
	emit_signal("quit_to_title_requested")

func is_game_paused() -> bool:
	return is_paused
