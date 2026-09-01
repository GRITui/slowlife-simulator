extends CharacterBody2D
## RomanceNPC — TASK-052. Peer NPCs (Niran/Fah) with affinity-driven
## dialogue tiers + v1 gift-giving (any FOOD_ITEMS item, +10 affinity).
## VillagerNPC contract mirror (Area2D proximity + interact), SignalBus-only.

const DialogueDBScript: GDScript = preload("res://scripts/narrative/DialogueDB.gd")

@export var npc_id: String = "niran"
@export var display_name: String = "Niran"

var _player_in_range: bool = false
var _talk_count: int = 0

@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null

func _ready() -> void:
	add_to_group("villager_npc")
	add_to_group("romance_candidate")
	if _area != null:
		_area.body_entered.connect(_on_body_entered)
		_area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		try_interact()
		get_viewport().set_input_as_handled()

## Gift first (if holding food), otherwise tiered conversation.
func try_interact() -> bool:
	if _give_gift():
		return true
	_talk()
	return false

func _give_gift() -> bool:
	var gift_id: String = ""
	for item_id: String in GameData.inventory.keys():
		if item_id in GameData.FOOD_ITEMS and int(GameData.inventory[item_id]) > 0:
			gift_id = item_id
			break
	if gift_id.is_empty():
		return false
	GameData.remove_item(gift_id, 1)
	GameData.add_affinity(npc_id, 10)
	var affinity: int = GameData.get_affinity(npc_id)
	SignalBus.show_dialogue.emit(display_name, "A gift? %s — thank you. (affinity %d)" % [gift_id.replace("_", " "), affinity])
	return true

func _talk() -> void:
	var tier: String = DialogueDBScript.get_affinity_tier(GameData.get_affinity(npc_id))
	var line: String = DialogueDBScript.get_line(npc_id, tier, _talk_count)
	_talk_count += 1
	SignalBus.show_dialogue.emit(display_name, line)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = false
