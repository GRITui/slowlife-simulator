extends Control
# SettingsScreen — TASK-017 placeholder ready for audio (TASK-021) volume sliders

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")

func _on_back_to_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/core/Main.tscn")
