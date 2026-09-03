extends Node2D
## FarmHouseBed — TASK-355. Bed interactable inside the FarmHouse that
## advances the day to 06:00 (via TimeManager.advance_to_next_day, which
## runs the same rollover branch the passive minute-tick does — season
## check + forecast flip + new forecast roll all fire), restores full
## stamina, persists via SaveManager, and emits a short dialogue line.
## Follows the same InteractArea + `interact` action convention as
## Door.gd and CarpenterUpgrade.gd.

var _player_in_range: bool = false

@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null
@onready var _sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var _prompt: Label = $PromptLabel if has_node("PromptLabel") else null

func _ready() -> void:
	add_to_group("farmhouse_bed")
	if _area:
		_area.body_entered.connect(_on_body_entered)
		_area.body_exited.connect(_on_body_exited)
	if _prompt:
		_prompt.visible = false
		_prompt.text = "Press [E] to sleep"

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		_sleep()
		get_viewport().set_input_as_handled()

func _sleep() -> void:
	# 1. Advance to next day at 06:00. Goes through _advance_minute's
	#    rollover branch (season check + next_weather -> current_weather
	#    swap + new forecast), not the raw set_time() setter.
	var tm: Node = SignalBus.time_manager
	if tm != null and tm.has_method("advance_to_next_day"):
		tm.advance_to_next_day(6)
	# 2. Full stamina restore.
	GameData.reset_stamina()
	# 3. Persist. Mirror how World.gd's pause menu invokes SaveManager:
	#    a child SaveManager instance (the World.gd pattern uses
	#    _ensure_save_manager() because SaveManager is NOT a project
	#    autoload — see SaveManager.gd header note about it being
	#    "headless-safe" and only constructed on demand). FarmHouse is
	#    an interior, so reuse the same child-of-caller pattern.
	_try_save()
	# 4. Dialogue line — same shape as CarpenterUpgrade / SluiceGate.
	SignalBus.show_dialogue.emit("Farmer", "You sleep soundly. A new day begins.")

func _try_save() -> void:
	# Mirror World.gd._ensure_save_manager() — a child-of-caller
	# pattern because SaveManager is not a project autoload. Returns
	# silently on failure; the dialogue line still fires so the player
	# gets feedback either way (matches the pause-menu UX).
	if get_node_or_null("SaveManager") != null:
		_save_via_existing()
		return
	var script: GDScript = load("res://scripts/persistence/SaveManager.gd")
	if script == null:
		return
	var manager: Node = script.new()
	manager.name = "SaveManager"
	add_child(manager)
	manager.save_game()

func _save_via_existing() -> void:
	var sm: Node = get_node("SaveManager")
	if sm != null and sm.has_method("save_game"):
		sm.save_game()

func _on_body_entered(body: Node) -> void:
	if body == self:
		return
	if body.is_in_group("player") or body.name == "Player" or body is CharacterBody2D:
		_player_in_range = true
		if _prompt:
			_prompt.visible = true

func _on_body_exited(body: Node) -> void:
	if body == self:
		return
	if body.is_in_group("player") or body.name == "Player" or body is CharacterBody2D:
		_player_in_range = false
		if _prompt:
			_prompt.visible = false
