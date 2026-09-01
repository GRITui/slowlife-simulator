extends StaticBody2D
## ChickenCoop — TASK-049 (PO_INBOX r5 #5). No-harm protein: interact grants
## one egg per calendar day (daily-limited resource, unlike Buffalo's
## unlimited milk). Mirror of Buffalo.gd's interaction contract.

@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null

var _player_in_range: bool = false
var _last_egg_day: int = -1

func _ready() -> void:
	add_to_group("chicken_coop")
	if _area != null:
		_area.body_entered.connect(_on_body_entered)
		_area.body_exited.connect(_on_body_exited)

func _current_day() -> int:
	var tm: Node = SignalBus.time_manager
	if tm != null and "day" in tm:
		return int(tm.day)
	return 1

func collect_egg() -> bool:
	var day: int = _current_day()
	if _last_egg_day == day:
		SignalBus.show_dialogue.emit("Chickens", "Hens are resting — eggs come tomorrow.")
		return false
	_last_egg_day = day
	GameData.add_chicken_affinity(5)
	SignalBus.chicken_affinity_changed.emit(GameData.chicken_affinity, GameData.chicken_hearts())
	var egg_id: String = "egg_gold" if GameData.chicken_hearts() >= 3 else "egg"
	# TASK-323B: yield scales with herd size — one egg per hen (count 1..3).
	GameData.add_item(egg_id, GameData.chicken_count)
	var egg_word: String = "egg" if GameData.chicken_count == 1 else "eggs"
	if egg_id == "egg_gold":
		SignalBus.show_dialogue.emit("Chickens", "+%d golden %s — the hens know your footsteps. Hearts: %d!" % [GameData.chicken_count, egg_word, GameData.chicken_hearts()])
	else:
		SignalBus.show_dialogue.emit("Chickens", "+%d %s — warm from the nest." % [GameData.chicken_count, egg_word])
	# TASK-323B: breeding attempt — automatic side effect of the daily
	# interact. Conditions, in spec order: hearts >= 2, count < cap, then
	# spend_silver. Never spend speculatively (mirrors CarpenterUpgrade.gd
	# check-before-deduct, not the old deduct-then-refund mistake). Cap
	# (chicken_count < 3) is enforced at the call site per the spec, not
	# on the var itself in GameData.gd. On insufficient silver: silent
	# skip, no dialogue nag — breeding is a cozy bonus on top of the
	# normal daily collection, not a requirement.
	if GameData.chicken_hearts() >= 2 and GameData.chicken_count < 3:
		if GameData.spend_silver(40):
			GameData.chicken_count += 1
			SignalBus.show_dialogue.emit("Chickens", "A new chick hatched! The coop swells to %d hens." % GameData.chicken_count)
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		collect_egg()
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = false
