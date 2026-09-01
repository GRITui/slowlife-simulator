extends Resource
class_name QuestData

# QuestData — TASK-053 quest-state primitive (PO_INBOX r6 #3).
# Pure Resource, mirrors CropData's shape: data only, zero logic.
# Chains/objectives content arrives later; this is the state-tracking
# primitive GameData.active_quests indexes by.

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var objectives: Array[String] = [] # ordered objective ids
@export var reward_item_id: String = ""
@export var reward_harmony: int = 0
@export var giver_npc_id: String = ""
