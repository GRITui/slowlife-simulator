extends CanvasLayer
## MarketShop — TASK-327 market panel: barter, sell-cheapest, and a
## selectable buy list (seeds + existing silver goods), opened by
## MarketStallNPC.interact() instead of the old blind auto-cascade.
## Registers via SignalBus.market_shop (registry pattern, mirrors
## SignalBus.grid_manager / time_manager). Touch-first: no keybind toggle.

const DialogueDBScript: GDScript = preload("res://scripts/narrative/DialogueDB.gd")

@onready var _barter_label: Label = $Panel/VBox/BarterRow/BarterLabel
@onready var _barter_button: Button = $Panel/VBox/BarterRow/BarterButton
@onready var _sell_label: Label = $Panel/VBox/SellRow/SellLabel
@onready var _sell_button: Button = $Panel/VBox/SellRow/SellButton
@onready var _buy_list: VBoxContainer = $Panel/VBox/BuyScroll/BuyList
@onready var _close_button: Button = $Panel/VBox/CloseButton

var _market: Node = null
var _season: String = "cool"
var _current_offer: Dictionary = {}

func _ready() -> void:
	visible = false
	SignalBus.market_shop = self
	_barter_button.pressed.connect(_on_barter_pressed)
	_sell_button.pressed.connect(_on_sell_pressed)
	_close_button.pressed.connect(close)

func _exit_tree() -> void:
	if SignalBus.market_shop == self:
		SignalBus.market_shop = null

## Called by MarketStallNPC.interact(). `market` is the MarketManager node.
func open(market: Node, season: String) -> void:
	_market = market
	_season = season
	_refresh()
	visible = true

func close() -> void:
	visible = false

func _refresh() -> void:
	_refresh_barter_row()
	_refresh_sell_row()
	_refresh_buy_list()

func _refresh_barter_row() -> void:
	_current_offer = {}
	if _market == null:
		_barter_label.text = "The stall is closed."
		_barter_button.disabled = true
		return
	var offers: Array[Dictionary] = _market.get_offers(_season)
	for candidate: Dictionary in offers:
		var have_id: String = String(candidate.get("have", ""))
		if not have_id.is_empty() and GameData.has_item(have_id, 1):
			_current_offer = candidate
			break
	if _current_offer.is_empty():
		_barter_label.text = "No trade today." if offers.is_empty() else "Nothing to barter with."
		_barter_button.disabled = true
	else:
		var have_id: String = String(_current_offer.get("have", ""))
		var want_id: String = String(_current_offer.get("want", ""))
		_barter_label.text = "%s -> %s" % [have_id.replace("_", " "), want_id.replace("_", " ")]
		_barter_button.disabled = false

func _refresh_sell_row() -> void:
	var sellable: String = GameData.cheapest_sellable()
	if sellable.is_empty():
		_sell_label.text = "Nothing to sell."
		_sell_button.disabled = true
	else:
		var price: int = GameData.get_sell_price(sellable, "market")
		_sell_label.text = "%s for %d silver" % [sellable.replace("_", " "), price]
		_sell_button.disabled = false

func _refresh_buy_list() -> void:
	for child: Node in _buy_list.get_children():
		child.queue_free()
	if _market == null:
		return
	var offers: Array[Dictionary] = _market.get_buy_offers(_season)
	for offer: Dictionary in offers:
		var item_id: String = String(offer.get("item", ""))
		var price: int = int(offer.get("price", 0))
		if item_id.is_empty() or price <= 0:
			continue
		var row: HBoxContainer = HBoxContainer.new()
		var label: Label = Label.new()
		label.text = "%s — %d silver" % [item_id.replace("_", " "), price]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var buy_btn: Button = Button.new()
		buy_btn.text = "Buy"
		buy_btn.custom_minimum_size = Vector2(60, 44)
		buy_btn.disabled = GameData.silver < price
		buy_btn.pressed.connect(_on_buy_pressed.bind(item_id, price))
		row.add_child(label)
		row.add_child(buy_btn)
		_buy_list.add_child(row)

func _on_barter_pressed() -> void:
	if _current_offer.is_empty():
		return
	var have_id: String = String(_current_offer.get("have", ""))
	var want_id: String = String(_current_offer.get("want", ""))
	if GameData.barter(have_id, want_id):
		var line: String = DialogueDBScript.get_market_line(_season, have_id, want_id)
		SignalBus.show_dialogue.emit("Trader", line)
	_refresh()

func _on_sell_pressed() -> void:
	var sellable: String = GameData.cheapest_sellable()
	if sellable.is_empty():
		return
	var gained: int = GameData.sell_item_premium(sellable, "market")
	if gained > 0:
		SignalBus.show_dialogue.emit("Trader", "Sold %s for %d silver at Market premium! (wallet %d)" % [sellable.replace("_", " "), gained, GameData.silver])
	_refresh()

func _on_buy_pressed(item_id: String, price: int) -> void:
	if GameData.silver < price:
		return
	if GameData.spend_silver(price):
		GameData.add_item(item_id, 1)
		SignalBus.show_dialogue.emit("Trader", "Bought %s for %d silver. (wallet %d)" % [item_id.replace("_", " "), price, GameData.silver])
	_refresh()
