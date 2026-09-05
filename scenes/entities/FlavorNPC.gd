extends CharacterBody2D
## FlavorNPC — TASK-383. Minimal static background NPC: no schedule, no
## affinity, no gift system, no dialogue tiers. Interact cycles through
## exactly 3 fixed flavor lines round-robin. Exists purely for village
## liveliness/family lore — deliberately distinct from
## RomanceNPC.gd/VillagerNPC.gd/RivalNPC.gd's heavier mechanical systems.

const FlavorDialogueScript: GDScript = preload("res://scripts/narrative/FlavorDialogue.gd")

@export var npc_id: String = ""
@export var display_name: String = ""

var _player_in_range: bool = false
var _line_index: int = 0

@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null

func _ready() -> void:
	add_to_group("flavor_npc")
	if _area != null:
		_area.body_entered.connect(_on_body_entered)
		_area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		_talk()
		get_viewport().set_input_as_handled()

func _talk() -> void:
	var lines: Array = FlavorDialogueScript.FLAVOR_LINES.get(npc_id, [])
	if lines.is_empty():
		return
	SignalBus.show_dialogue.emit(display_name, String(lines[_line_index % lines.size()]))
	_line_index += 1

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = false
