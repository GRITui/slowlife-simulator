extends StaticBody2D
## MarketStallNPC — TASK-025 Evening Market Stall (Cozy Gameplay)
## Attached to MarketStall.tscn root. Handles proximity + "interact" input,
## which opens the MarketShop panel (TASK-327) for barter/sell/buy choices.
## Mirror of MonkNPC's interaction contract (Area2D proximity + `interact`
## action); zero combat, no gold, no fail state.

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
		_open_shop()
		get_viewport().set_input_as_handled()

## TASK-327: interact opens the selectable shop panel (MarketShop) instead
## of the old blind barter->sell->buy-first-affordable cascade — a 24-crop
## seed catalog needs the player to actually choose, not auto-pick. The
## panel calls GameData.barter()/sell_item_premium()/spend_silver()+add_item()
## directly per player choice; see scenes/ui/MarketShop.gd.
func _open_shop() -> void:
	if SignalBus.market_shop == null:
		SignalBus.show_dialogue.emit("Trader", "The stall is closed. Come back at dusk.")
		return
	SignalBus.market_shop.open(_market, _current_season())

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
