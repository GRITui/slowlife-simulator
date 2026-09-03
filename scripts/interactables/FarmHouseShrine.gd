extends Node2D
## FarmHouseShrine — TASK-355. Small household spirit-house / weather
## shrine inside the FarmHouse. On interact, reads the
## TimeManager.next_weather forecast (via the existing
## SignalBus.time_manager registry — the same pattern every festival
## trigger already uses, see SongkranTrigger.gd:61) and shows a
## dialogue line naming tomorrow's weather. Thematically fits the
## Thai rural setting — a spirit house / small shrine is a natural
## way for a farmer to "ask the spirits" about tomorrow's weather,
## and avoids anachronisms like a TV/radio in a rural farmhouse.
## Same InteractArea + `interact` action convention as
## FarmHouseBed.gd / Door.gd / CarpenterUpgrade.gd.

var _player_in_range: bool = false

@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null
@onready var _sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var _prompt: Label = $PromptLabel if has_node("PromptLabel") else null

func _ready() -> void:
	add_to_group("farmhouse_shrine")
	if _area:
		_area.body_entered.connect(_on_body_entered)
		_area.body_exited.connect(_on_body_exited)
	if _prompt:
		_prompt.visible = false
		_prompt.text = "Press [E] to read the spirits"

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		_read_forecast()
		get_viewport().set_input_as_handled()

func _read_forecast() -> void:
	# Same SignalBus.time_manager access pattern every festival trigger
	# uses (see scenes/festival/SongkranTrigger.gd:61 and friends).
	var tm: Node = SignalBus.time_manager
	var forecast: String = ""
	if tm != null and "next_weather" in tm:
		forecast = String(tm.get("next_weather"))
	if forecast == "":
		# TimeManager hasn't bootstrapped yet (extremely unlikely inside
		# the FarmHouse, but be defensive) — fall back to a neutral
		# line so the player still gets useful feedback.
		SignalBus.show_dialogue.emit("Farmer", "The spirits are quiet today.")
		return
	SignalBus.show_dialogue.emit("Farmer", "Tomorrow looks like it'll be %s." % forecast)

func _on_body_entered(body: Node) -> void:
	if body == self:
		return
	if body.is_in_group("player") or body.name == "Player" or body is CharacterBody2D:
		_player_in_range = true
		if _prompt:
			_prompt.visible = true

func _on_body_exited(body: Node) -> void:
	if body == self:
		return
	if body.is_in_group("player") or body.name == "Player" or body is CharacterBody2D:
		_player_in_range = false
		if _prompt:
			_prompt.visible = false
