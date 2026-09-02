extends Node2D
## CoastalTradingPost — TASK-344 (Sprint 5 final). The last of the 5
## unlockable areas. Deliberately different in kind from every prior
## unlockable area: NOT a gather spot — a better SELLING option. A
## trading post by the coast that comes looking for the player once
## they've shipped enough goods that the coastal traders come looking
## for them. One item per interact, sold at a +25% premium over base
## (between the cart's base rate and the existing "+15% market" /
## "+45% specialty" tiers). Sells the PRICIEST held sellable, not the
## cheapest — the mirror of TraderNPC's _try_trader_sell(), which sells
## the cheapest. Soft-fail dialogue when nothing is sellable. No new
## persisted GameData field — the gate reads lifetime_items_shipped
## (already persisted via TASK-326's shipping-milestone stamina
## progression), specifically the 200-ships threshold that lands at
## stamina_tier 4 (cap), framing this as the natural capstone of the
## shipping economy.

@export var spot_name: String = "Coastal Trading Post"
## Proximity radius (matches SluiceGate/CarpenterUpgrade/MiningSpot InteractArea).
@export var interact_radius: float = 56.0
## Channel string for GameData.sell_item_premium — "coastal" maps to
## ceil(base * 1.25) in GameData.get_sell_price().
const _CHANNEL: String = "coastal"

var _player_in_range: bool = false
var _area: Area2D = null

func _ready() -> void:
	add_to_group("coastal_trading_post")
	_build_interact_area()

func _build_interact_area() -> void:
	# Build the InteractArea programmatically (the @onready path is
	# always null because nothing ever adds the child — fix that here).
	_area = Area2D.new()
	_area.name = "InteractArea"
	_area.collision_layer = 0
	_area.collision_mask = 1 # player layer
	_area.monitorable = true
	_area.monitoring = true
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = interact_radius
	var collider: CollisionShape2D = CollisionShape2D.new()
	collider.shape = shape
	collider.debug_color = Color(0.2, 0.55, 0.7, 0.32)
	_area.add_child(collider)
	add_child(_area)
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)

## Sell the single most valuable currently-held sellable item at the
## "coastal" +25% premium. Mirrors TraderNPC._try_trader_sell()'s shape
## (one item per interact, no new UI) but inverted: priciest, not
## cheapest, at a better rate. Soft-fails with dialogue when nothing
## is held — no mutation, no item removed, no silver added.
func trade() -> bool:
	var item: String = GameData.priciest_sellable()
	if item.is_empty():
		SignalBus.show_dialogue.emit(spot_name, "Nothing to trade yet. The coastal boats want goods worth the trip.")
		return false
	var gained: int = GameData.sell_item_premium(item, _CHANNEL)
	if gained <= 0:
		SignalBus.show_dialogue.emit(spot_name, "Nothing to trade yet. The coastal boats want goods worth the trip.")
		return false
	SignalBus.show_dialogue.emit(spot_name, "Coastal post: sold %s for %d silver. (coastal premium)" % [
		item.replace("_", " "), gained])
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		trade()
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = false