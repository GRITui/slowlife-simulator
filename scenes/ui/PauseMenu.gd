extends CanvasLayer
# PauseMenu — TASK-017: Esc / P pauses without breaking TimeManager/stamina
# SignalBus-decoupled, cozy palette.

var is_paused: bool = false:
	set(v):
		is_paused = v
		_update_pause()

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		is_paused = not is_paused
		get_viewport().set_input_as_handled()

func _update_pause() -> void:
	get_tree().paused = is_paused
	visible = is_paused
	if is_paused:
		SignalBus.show_dialogue.emit("System", "Paused")

func _on_resume_pressed() -> void:
	is_paused = false

func _on_settings_pressed() -> void:
	# keep paused, switch to settings overlay
	get_tree().change_scene_to_file("res://scenes/ui/SettingsScreen.tscn")

func _on_quit_to_title_pressed() -> void:
	is_paused = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
