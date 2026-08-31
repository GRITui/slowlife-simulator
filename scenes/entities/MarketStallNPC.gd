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

func _try_barter() -> void:
	if _market == null:
		SignalBus.show_dialogue.emit("Trader", "The stall is closed. Come back at dusk.")
		return
	var season: String = _current_season()
	var offers: Array[Dictionary] = _market.get_offers(season)
	if offers.is_empty():
		SignalBus.show_dialogue.emit("Trader", "No trade today. Come back another time.")
		return
	var offer: Dictionary = offers[0]
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