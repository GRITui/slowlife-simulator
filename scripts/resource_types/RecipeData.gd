extends Resource
class_name RecipeData

# RecipeData — TASK-013 cooking via mortar & pestle + clay stove
# Data-driven from data/recipes/recipes.json; also supports .tres export.

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var inputs: Dictionary = {} # item_id -> amount
@export var stamina_cost: float = 5.0
@export var harmony_reward: int = 5
@export var requires_infrastructure: String = ""
@export var season: String = ""

func can_craft(inventory: Dictionary, infrastructure: Dictionary) -> bool:
	if requires_infrastructure != "" and not infrastructure.get(requires_infrastructure, false):
		return false
	for item_id in inputs:
		if inventory.get(item_id, 0) < int(inputs[item_id]):
			return false
	return true

func craft(inventory: Dictionary) -> bool:
	for item_id in inputs:
		if inventory.get(item_id, 0) < int(inputs[item_id]):
			return false
	for item_id in inputs:
		inventory[item_id] -= int(inputs[item_id])
		if inventory[item_id] <= 0:
			inventory.erase(item_id)
	return true
