extends CharacterBody2D

const DialogueDBScript: GDScript = preload("res://scripts/narrative/DialogueDB.gd")

# MonkNPC — Binthabat morning alms monk (TASK-004, seasonal passes TASK-012)
# Hybrid A/B temple lane east. Zero combat.
# Interacts via Area2D proximity + "interact" (E/Space).
# Presence window: 05:00 - 07:30, driven by SignalBus.minute_ticked.

@export var temple_position: Vector2 = Vector2(400, 100)
@export var walk_speed: float = 40.0

var is_present: bool = false
var has_received_offering_today: bool = false
var current_day: int = -1

var _player_in_range: bool = false
var _target_position: Vector2 = Vector2(400, 100)
var _monk_talk_count: int = 0

func _ready() -> void:
	add_to_group("monk_npc")
	_target_position = temple_position
	SignalBus.minute_ticked.connect(_on_minute_ticked)
	if has_node("InteractArea"):
		var area: Area2D = $InteractArea as Area2D
		area.body_entered.connect(_on_interact_area_body_entered)
		area.body_exited.connect(_on_interact_area_body_exited)
	visible = is_present
	# Sync with existing TimeManager instance via SignalBus registry (ENGINE-006).
	var tm := SignalBus.time_manager
	if tm != null:
		_on_minute_ticked(tm.day, tm.hour, tm.minute)

func _physics_process(delta: float) -> void:
	if not is_present:
		velocity = Vector2.ZERO
		return
	var dist := global_position.distance_to(_target_position)
	if dist > 2.0:
		var dir := ( _target_position - global_position ).normalized()
		velocity = dir * walk_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		global_position = _target_position

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if not is_present:
		return
	if event.is_action_pressed("interact"):
		var item_id: String = _get_best_offer_item()
		var offered: bool = interact(item_id)
		if not offered:
			_try_offer_quest()
		get_viewport().set_input_as_handled()

func _try_offer_quest() -> void:
	var quest_logs: Array = get_tree().get_nodes_in_group("quest_log")
	if quest_logs.is_empty():
		return
	var quest_log: Node = quest_logs[0] as Node
	if quest_log != null and quest_log.has_method("offer_quest_for_giver"):
		quest_log.offer_quest_for_giver("monk")

func _try_complete_talk_objective() -> void:
	var quest_logs: Array = get_tree().get_nodes_in_group("quest_log")
	if quest_logs.is_empty():
		return
	var quest_log: Node = quest_logs[0] as Node
	if quest_log != null and quest_log.has_method("on_npc_talked"):
		quest_log.on_npc_talked("monk")

# --- Time window ---

func _on_minute_ticked(day: int, hour: int, minute: int) -> void:
	# Track day rollover and reset daily flag.
	if day != current_day:
		current_day = day
		has_received_offering_today = false
	var in_window := _is_bin_thabat_window(hour, minute)
	if in_window and not is_present:
		_arrive()
	elif not in_window and is_present:
		_depart()

func _is_bin_thabat_window(hour: int, minute: int) -> bool:
	# Prefer TimeManager.is_morning_bin_thabat_window() when available.
	var tm := SignalBus.time_manager
	if tm != null and tm.has_method("is_morning_bin_thabat_window"):
		return tm.is_morning_bin_thabat_window()
	var total: int = hour * 60 + minute
	return total >= 5 * 60 and total <= 7 * 60 + 30

func _arrive() -> void:
	is_present = true
	visible = true
	_target_position = temple_position
	# If far from temple (e.g. after depart), snap or walk in.
	# Start slightly off-temple for walk animation if desired.
	if global_position.distance_to(temple_position) > 300.0:
		global_position = temple_position - Vector2(0, 80.0)
	# Ensure collision enabled when present.
	if has_node("CollisionShape2D"):
		($CollisionShape2D as CollisionShape2D).disabled = false

func _depart() -> void:
	is_present = false
	visible = false
	velocity = Vector2.ZERO
	if has_node("CollisionShape2D"):
		($CollisionShape2D as CollisionShape2D).disabled = true

# --- Interaction ---

func interact(player_offer_item_id: String) -> bool:
	if not is_present:
		SignalBus.show_dialogue.emit("Monk", "The monk has not yet arrived. Please come between 05:00 and 07:30.")
		return false
	if has_received_offering_today:
		# Seasonal after-offering flavor (TASK-012) — keep Sadhu keyword for legacy.
		var season_a: String = GameData.current_season if "current_season" in GameData else "cool"
		var idle_line: String = DialogueDBScript.get_monk_seasonal_idle(season_a, _monk_talk_count)
		_monk_talk_count += 1
		SignalBus.show_dialogue.emit("Monk", "Sadhu... I have already received alms today. %s" % idle_line)
		return false
	if player_offer_item_id.is_empty():
		var season_b: String = GameData.current_season if "current_season" in GameData else "cool"
		var hint: String = DialogueDBScript.get_seasonal_line("monk", season_b, false, _monk_talk_count)
		_monk_talk_count += 1
		# Fallback to original hint if DB returns generic idle
		if hint == "...":
			hint = "Bring jasmine rice or lotus... an offering of merit will bring harmony."
		SignalBus.show_dialogue.emit("Monk", hint)
		return false
	if not GameData.binthabat_yields.has(player_offer_item_id):
		SignalBus.show_dialogue.emit("Monk", "This is not suitable for alms. Bring jasmine rice or lotus...")
		return false
	var day_to_use: int = current_day if current_day != -1 else 1
	# Delegate validation, inventory removal, harmony award, and emission to GameData.
	var result: int = GameData.offer_bin_thabat(player_offer_item_id, day_to_use)
	if result > 0:
		has_received_offering_today = true
		var thanks: String = DialogueDBScript.get_monk_thanks(player_offer_item_id, result, GameData.current_season if "current_season" in GameData else "cool")
		SignalBus.show_dialogue.emit("Monk", thanks)
		return true
	else:
		if not GameData.can_offer_today(day_to_use):
			SignalBus.show_dialogue.emit("Monk", "Sadhu... already received today. Return tomorrow morning.")
		elif not GameData.has_item(player_offer_item_id, 1):
			SignalBus.show_dialogue.emit("Monk", "You do not have %s to offer." % player_offer_item_id)
		else:
			SignalBus.show_dialogue.emit("Monk", "The offering could not be made.")
		return false

func _get_best_offer_item() -> String:
	# Auto-select first valid offering the player actually owns.
	for id in GameData.binthabat_yields.keys():
		if GameData.has_item(id as String, 1):
			return id as String
	return ""

# --- Proximity ---

func _on_interact_area_body_entered(body: Node) -> void:
	# Accept any body in "player" group or named Player; fallback to any CharacterBody2D.
	if body.is_in_group("player") or body.name == "Player" or body is CharacterBody2D:
		# Distinguish from self
		if body != self:
			_player_in_range = true

func _on_interact_area_body_exited(body: Node) -> void:
	if body.is_in_group("player") or body.name == "Player" or body is CharacterBody2D:
		if body != self:
			_player_in_range = false

