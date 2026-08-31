extends Control
# TitleScreen — TASK-017 game-state flow: title/start, new game, settings, quit
# Cozy Thai rural palette, SignalBus-decoupled transitions.

func _ready() -> void:
	# Ensure input focus for keyboard
	if has_node("VBox/NewGameButton"):
		$VBox/NewGameButton.grab_focus()

func _on_new_game_pressed() -> void:
	# SignalBus-driven transition (centralized, no scattered change_scene)
	SignalBus.show_dialogue.emit("System", "Starting new game...")
	get_tree().change_scene_to_file("res://scenes/core/Main.tscn")

func _on_continue_pressed() -> void:
	# ENGINE-003 save/load will handle Continue; for now just start
	if GameData.infrastructure.is_empty() and GameData.inventory.is_empty():
		SignalBus.show_dialogue.emit("System", "No save yet — starting new game.")
	_on_new_game_pressed()
	else:
		get_tree().change_scene_to_file("res://scenes/core/Main.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/SettingsScreen.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
