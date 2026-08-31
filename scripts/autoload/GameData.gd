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

# Binthabat morning offering (TASK-004)
var binthabat_yields: Dictionary = {
	"rice_grain": 3,
	"lotus_root": 5,
	"mango": 6,
	"sticky_rice": 4,
}
var daily_offerings: int = 0
var last_offering_day: int = -1

# Village dialogue / seasonal quest state (TASK-012) — cozy, no heavy exposition
var villager_talked_days: Dictionary = {} # npc_id -> last_day talked
var binthabat_streak: int = 0
var last_binthabat_day: int = -1

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

# --- Binthabat offering API (TASK-004) ---

func can_offer_today(day: int) -> bool:
	# One offering per calendar day. If the queried day differs from the last
	# offering day, the slot is free regardless of the counter value.
	if last_offering_day != day:
		return true
	return daily_offerings < 1

func offer_bin_thabat(item_id: String, day: int) -> int:
	# Returns harmony yield on success, 0 on failure.
	# Validates daily limit, item validity, and inventory ownership before
	# deducting the item, adding harmony, and emitting signals.
	if not can_offer_today(day):
		return 0
	if not binthabat_yields.has(item_id):
		return 0
	if not has_item(item_id, 1):
		return 0
	# Reset daily counter when the calendar rolls over.
	if last_offering_day != day:
		daily_offerings = 0
	var harmony_yield: int = int(binthabat_yields[item_id])
	# Inventory deduction must succeed after earlier check.
	if not remove_item(item_id, 1):
		return 0
	add_harmony(harmony_yield)
	daily_offerings += 1
	last_offering_day = day
	# TASK-012 streak: consecutive-day alms, no fail state, cozy bonus only.
	if last_binthabat_day == day - 1:
		binthabat_streak += 1
	elif last_binthabat_day != day:
		binthabat_streak = 1
	last_binthabat_day = day
	SignalBus.binthabat_offered.emit(item_id, harmony_yield)
	return harmony_yield
// TASK-023 typing hardening — typed accessors for gdlint clean
func get_inventory_item(id: String) -> int:
  return int(inventory.get(id, 0))
func get_infrastructure_state(id: String) -> bool:
  return bool(infrastructure.get(id, false))
