extends StaticBody2D
## MarketStallNPC — TASK-025 Evening Market Stall (Cozy Gameplay)
## Attached to MarketStall.tscn root. Handles proximity + "interact" input,
## resolves the current season's offer via MarketManager, and delegates the
## 1:1 barter to GameData.barter(). Mirror of MonkNPC's interaction
## contract (Area2D proximity + `interact` action); zero combat, no gold,
## no fail state. All UI coupling goes through SignalBus.show_dialogue.

const DialogueDBScript: GDScript = preload("res://scripts/narrative/DialogueDB.gd")

var _player_in_range: bool = false

@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null
@onready var _market: Node = $MarketManager if has_node("MarketManager") else null

func _ready() -> void:
	add_to_group("market_stall")
	if _area:
		_area.body_entered.connect(_on_body_entered)
		_area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		_try_barter()
		get_viewport().set_input_as_handled()

func _barter_step() -> void:
	# ISSUE-135 silver economy: full counter flow is
	# 1) barter (if fulfillable) -> 2) sell cheapest held -> 3) buy offer.
	_barter_step()
	if _market == null:
		SignalBus.show_dialogue.emit("Trader", "The stall is closed. Come back at dusk.")
		return
	var season: String = _current_season()
	var offers: Array[Dictionary] = _market.get_offers(season)
	if offers.is_empty():
		SignalBus.show_dialogue.emit("Trader", "No trade today. Come back another time.")
		return
	# TASK-047: multiple goods per season — trade the first offer the player
	# can actually fulfill; fall back to the first offer for the soft-fail
	# nudge (keeps the cozy guidance without arbitrary gating).
	var offer: Dictionary = offers[0]
	for candidate: Dictionary in offers:
		if GameData.has_item(String(candidate.get("have", "")), 1):
			offer = candidate
			break
	var have_id: String = String(offer.get("have", ""))
	var want_id: String = String(offer.get("want", ""))
	if have_id.is_empty() or want_id.is_empty():
		SignalBus.show_dialogue.emit("Trader", "No trade today. Come back another time.")
		return
	# Soft-fail first: if the player lacks the offering item, surface the
	# cozy nudge without ever attempting the swap (no inventory mutation).
	if not GameData.has_item(have_id, 1):
		SignalBus.show_dialogue.emit("Trader", "Not enough to trade.")
		return
	var ok: bool = GameData.barter(have_id, want_id)
	if ok:
		var line: String = DialogueDBScript.get_market_line(season, have_id, want_id)
		SignalBus.show_dialogue.emit("Trader", line)
	else:
		# Defensive: any other soft-fail (shouldn't happen given has_item
		# check above, but keeps the contract tight).
		SignalBus.show_dialogue.emit("Trader", "Not enough to trade.")

func _current_season() -> String:
	# Read from GameData mirror (kept in sync by TimeManager._ready and
	# _rotate_season). Fall back to "cool" so the test gate is deterministic
	# when the autoload is detached.
	if "current_season" in GameData:
		return String(GameData.current_season)
	return "cool"

# --- Proximity ---

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") or body.name == "Player" or body is CharacterBody2D:
		if body != self:
			_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") or body.name == "Player" or body is CharacterBody2D:
		if body != self:
			_player_in_range = false

## ISSUE-135: full market flow — barter, then sell cheapest held, then buy.
func _try_barter() -> void:
	if _market == null:
		SignalBus.show_dialogue.emit("Trader", "The stall is closed. Come back at dusk.")
		return
	var season: String = _current_season()
	# 1) Barter step (existing contract).
	var offers: Array[Dictionary] = _market.get_offers(season)
	for candidate: Dictionary in offers:
		var have_id: String = String(candidate.get("have", ""))
		if not have_id.is_empty() and GameData.has_item(have_id, 1):
			_barter_step()
			return
	# 2) Sell step: cheapest sellable held item -> silver.
	var sellable: String = GameData.cheapest_sellable()
	if not sellable.is_empty():
		var gained: int = GameData.sell_item(sellable)
		if gained > 0:
			SignalBus.show_dialogue.emit("Trader", "Sold %s for %d silver. (wallet %d)" % [sellable.replace("_", " "), gained, GameData.silver])
			return
	# 3) Buy step: first affordable silver offer.
	var buy_offers: Array[Dictionary] = _market.get_buy_offers(season)
	for offer: Dictionary in buy_offers:
		var price: int = int(offer.get("price", 0))
		if GameData.silver >= price and price > 0:
			var item: String = String(offer.get("item", ""))
			if GameData.spend_silver(price):
				GameData.add_item(item, 1)
				SignalBus.show_dialogue.emit("Trader", "Bought %s for %d silver. (wallet %d)" % [item.replace("_", " "), price, GameData.silver])
				return
	SignalBus.show_dialogue.emit("Trader", "Nothing to trade today — sell some harvest first.")
