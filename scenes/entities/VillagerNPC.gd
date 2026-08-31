extends CharacterBody2D
## VillagerNPC — TASK-012 generic village NPC (elder / child / handler)
## Seasonal dialogue passes + Binthabat event-tree hints, no heavy exposition.
## Decoupled via SignalBus.show_dialogue. Y-sort friendly, cozy ambient only.

const DialogueDBScript: GDScript = preload("res://scripts/narrative/DialogueDB.gd")

@export var npc_id: String = "elder" ## elder | child | handler
@export var display_name: String = "Elder"
@export var idle_texture: Texture2D

var _player_in_range: bool = false
var _talk_count: int = 0
var _last_talk_day: int = -1

@onready var _sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null

func _ready() -> void:
	add_to_group("villager_npc")
	add_to_group(npc_id)
	if _area:
		_area.body_entered.connect(_on_body_entered)
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

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") or body.name == "Player" or body is CharacterBody2D:
		if body != self:
			_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") or body.name == "Player" or body is CharacterBody2D:
		if body != self:
			_player_in_range = false
