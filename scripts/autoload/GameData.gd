extends Node

# GameData — Persistent game state autoload
# Holds stamina, harmony, inventory, and infrastructure state.

# Stamina
var max_stamina: float = 100.0
var current_stamina: float = 100.0:
	set(value):
		current_stamina = clamp(value, 0.0, max_stamina)
		SignalBus.stamina_changed.emit(current_stamina, max_stamina)

# Village harmony (Binthabat offering target)
var harmony: int = 0
var max_harmony: int = 100

# Inventory: item_id -> quantity
var inventory: Dictionary = {}

# Infrastructure: structure_id -> repaired bool
var infrastructure: Dictionary = {}

# Season helper — mirrors TimeManager.season
var current_season: String = "cool"  # hot | monsoon | cool
var current_weather: String = "clear"

func add_item(item_id: String, amount: int = 1) -> void:
	inventory[item_id] = inventory.get(item_id, 0) + amount

func remove_item(item_id: String, amount: int = 1) -> bool:
	if inventory.get(item_id, 0) < amount:
		return false
	inventory[item_id] -= amount
	if inventory[item_id] <= 0:
		inventory.erase(item_id)
	return true

func has_item(item_id: String, amount: int = 1) -> bool:
	return inventory.get(item_id, 0) >= amount

func add_harmony(amount: int) -> void:
	harmony = clamp(harmony + amount, 0, max_harmony)
	SignalBus.village_harmony_changed.emit(harmony)
	SignalBus.village_goodwill_changed.emit(harmony)

func repair_infrastructure(structure_id: String) -> void:
	infrastructure[structure_id] = true
	SignalBus.infrastructure_repaired.emit(structure_id)

func is_repaired(structure_id: String) -> bool:
	return infrastructure.get(structure_id, false)

func reset_stamina() -> void:
	current_stamina = max_stamina
