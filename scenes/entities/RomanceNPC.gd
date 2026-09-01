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

## Gift first, then proposal check (romantic + krathong held), else talk.
func try_interact() -> bool:
	if GameData.married and GameData.spouse == npc_id:
		# TASK-282: marriage ceiling payoff — annual anniversary, cozy loop.
		var tm: Node = SignalBus.time_manager
		var year: int = int(tm.year()) if tm != null and tm.has_method("year") else 1
		var key: String = "anniversary_%d_%s" % [year, npc_id]
		if not GameData.active_quests.has(key):
			GameData.active_quests[key] = {"stage": 1, "objectives_done": []}
			GameData.add_silver(30)
			GameData.add_harmony(10)
			SignalBus.festival_triggered.emit("anniversary_" + npc_id)
			SignalBus.show_dialogue.emit(display_name, "Happy anniversary, year %d — I saved up for us. (+30 silver, +10 harmony)" % year)
		else:
			SignalBus.show_dialogue.emit(display_name, "Home is wherever the two of us stop working. Let's head in soon.")
		return true
	if _give_gift():
		return true
	if _check_proposal():
		return true
	_talk()
	return false

## TASK-059: proposal — romantic tier (>=90) + krathong held. Cozy, mutual:
## the NPC accepts and a small wedding fires via festival_triggered.
func _check_proposal() -> bool:
	if GameData.married or GameData.get_affinity(npc_id) < 90:
		return false
	if not GameData.has_item("krathong", 1):
		return false
	GameData.remove_item("krathong", 1)
	GameData.married = true
	GameData.spouse = npc_id
	GameData.add_affinity(npc_id, 10) # cap keeps it at 100
	GameData.add_harmony(20)
	SignalBus.festival_triggered.emit("wedding_" + npc_id)
	SignalBus.show_dialogue.emit(display_name, "Yes. Lanterns, family, the whole village — let's be married.")
	return true

func _give_gift() -> bool:
	var gift_id: String = ""
	for item_id: String in GameData.inventory.keys():
		if item_id in GameData.FOOD_ITEMS and int(GameData.inventory[item_id]) > 0:
			gift_id = item_id
			break
	if gift_id.is_empty():
		return false
	GameData.remove_item(gift_id, 1)
	# TASK-054: per-NPC preference table scales the affinity delta.
	var tier: String = DialogueDBScript.gift_tier(npc_id, gift_id)
	var delta: int = DialogueDBScript.gift_affinity(tier)
	GameData.add_affinity(npc_id, delta)
	var affinity: int = GameData.get_affinity(npc_id)
	match tier:
		"loved":
			SignalBus.show_dialogue.emit(display_name, "%s — you remembered! (affinity %d)" % [gift_id.replace("_", " "), affinity])
		"liked":
			SignalBus.show_dialogue.emit(display_name, "%s is nice of you. (affinity %d)" % [gift_id.replace("_", " "), affinity])
		_:
			SignalBus.show_dialogue.emit(display_name, "%s — thank you. (affinity %d)" % [gift_id.replace("_", " "), affinity])
	return true

func _talk() -> void:
	var tier: String = DialogueDBScript.get_affinity_tier(GameData.get_affinity(npc_id))
	var line: String = DialogueDBScript.get_line(npc_id, tier, _talk_count)
	_talk_count += 1
	SignalBus.show_dialogue.emit(display_name, line)
	_try_offer_quest()

func _try_offer_quest() -> void:
	var quest_logs: Array = get_tree().get_nodes_in_group("quest_log")
	if quest_logs.is_empty():
		return
	var quest_log: Node = quest_logs[0] as Node
	if quest_log != null and quest_log.has_method("offer_quest_for_giver"):
		quest_log.offer_quest_for_giver(npc_id)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = false
