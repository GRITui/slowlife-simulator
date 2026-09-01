extends CharacterBody2D
## VillagerNPC — TASK-012 generic village NPC (elder / child / handler)
## Seasonal dialogue passes + Binthabat event-tree hints, no heavy exposition.
## Decoupled via SignalBus.show_dialogue. Y-sort friendly, cozy ambient only.

const DialogueDBScript: GDScript = preload("res://scripts/narrative/DialogueDB.gd")
const ScheduleDBScript: GDScript = preload("res://scripts/narrative/ScheduleDB.gd")

@export var npc_id: String = "elder" ## elder | child | handler
@export var display_name: String = "Elder"
@export var idle_texture: Texture2D

var _player_in_range: bool = false
var _talk_count: int = 0
var _last_talk_day: int = -1

@onready var _sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null

var _schedule_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("villager_npc")
	add_to_group(npc_id)
	# TASK-058: drift toward the schedule waypoint (only for scheduled NPCs).
	if not ScheduleDBScript.SCHEDULES.has(npc_id):
		set_physics_process(false)
	else:
		_schedule_pos = ScheduleDBScript.waypoint_for(npc_id, _current_hour()) * 48.0 + Vector2(24, 24)
		global_position = _schedule_pos

func _current_hour() -> int:
	var tm: Node = SignalBus.time_manager
	if tm != null and "hour" in tm:
		return int(tm.hour)
	return 6

## TASK-058: cozy waypoint drift — called from _physics_process. Static
## NPCs (unscheduled) skip this entirely via set_physics_process(false).
func _physics_process(_delta: float) -> void:
	var tm: Node = SignalBus.time_manager
	if tm != null:
		var target: Vector2 = ScheduleDBScript.waypoint_for(npc_id, int(tm.hour)) * 48.0 + Vector2(24, 24)
		if target != _schedule_pos:
			_schedule_pos = target
		var dist: float = global_position.distance_to(_schedule_pos)
		if dist > 8.0:
			velocity = (_schedule_pos - global_position).normalized() * 40.0
			move_and_slide()
		else:
			velocity = Vector2.ZERO
	if _area:
		if not _area.body_entered.is_connected(_on_body_entered):
			_area.body_entered.connect(_on_body_entered)
		if not _area.body_exited.is_connected(_on_body_exited):
			_area.body_exited.connect(_on_body_exited)
	if _sprite:
		if idle_texture != null:
			_sprite.texture = idle_texture
		else:
			# Headless-safe fallback: pick per-npc idle texture if none assigned.
			var path: String = ""
			match npc_id:
				"elder": path = "res://assets/characters/npc_elder_idle_01.png"
				"child": path = "res://assets/characters/npc_child_idle_01.png"
				"handler": path = "res://assets/characters/npc_handler_idle_01.png"
				_: path = "res://assets/characters/npc_elder_idle_01.png"
			if ResourceLoader.exists(path):
				var tex: Texture2D = load(path) as Texture2D
				if tex:
					_sprite.texture = tex
	# Seasonal tint sync is handled by Main; NPCs just idle.
	# Ensure collision shape is enabled.
	if has_node("CollisionShape2D"):
		($CollisionShape2D as CollisionShape2D).disabled = false

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		talk()
		get_viewport().set_input_as_handled()

func talk() -> void:
	var season: String = GameData.current_season if "current_season" in GameData else "cool"
	var tm: Node = SignalBus.time_manager
	var day: int = 1
	if tm and "day" in tm:
		day = int(tm.day)
	# Daily cooldown hint: if talked today, rotate line but don't block.
	var is_new_day: bool = day != _last_talk_day
	if is_new_day:
		_last_talk_day = day
	# Binthabat streak check — has player offered today?
	var binthabat_done: bool = false
	if "last_offering_day" in GameData and "daily_offerings" in GameData:
		binthabat_done = int(GameData.last_offering_day) == day and int(GameData.daily_offerings) > 0
	var line: String = DialogueDBScript.get_seasonal_line(npc_id, season, binthabat_done, _talk_count)
	_talk_count += 1
	SignalBus.show_dialogue.emit(display_name, line)
	# Track per-NPC talk for quests (no reward loop — cozy only).
	if "villager_talked_days" in GameData:
		# GameData.villager_talked_days is Dictionary npc_id -> last_day
		var d: Dictionary = GameData.villager_talked_days as Dictionary
		d[npc_id] = day
	# TASK-310: Offer quest for this giver if available.
	_try_offer_quest()

func _try_offer_quest() -> void:
	var quest_logs: Array = get_tree().get_nodes_in_group("quest_log")
	if quest_logs.is_empty():
		return
	var quest_log: Node = quest_logs[0] as Node
	if quest_log != null and quest_log.has_method("offer_quest_for_giver"):
		quest_log.offer_quest_for_giver(npc_id)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") or body.name == "Player" or body is CharacterBody2D:
		if body != self:
			_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") or body.name == "Player" or body is CharacterBody2D:
		if body != self:
			_player_in_range = false
# ENGINE-008 NavGrid consumer stub
