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
	# TASK-348: gold-egg tier moved from hearts >= 3 (old 0-4 scale, 75%) to
	# hearts >= 8 (new 0-10 scale, 80%) — the 0-4 "knows your footsteps"
	# threshold rescaled to the same percentage of the new ceiling.
	var egg_id: String = "egg_gold" if GameData.chicken_hearts() >= 8 else "egg"
	# TASK-323B: yield scales with herd size — one egg per hen (count 1..3).
	GameData.add_item(egg_id, GameData.chicken_count)
	var egg_word: String = "egg" if GameData.chicken_count == 1 else "eggs"
	# TASK-348: full 10-line hearts-up dialogue pool replaces the prior
	# 2-line "gold egg" vs "warm from the nest" branching. The pool is
	# keyed by the NEW hearts value (1..10) — line choice is independent
	# of the gold-egg item-tier check above.
	SignalBus.show_dialogue.emit("Chickens", _hearts_line(GameData.chicken_hearts()))
	# TASK-323B: breeding attempt — automatic side effect of the daily
	# interact. Conditions, in spec order: hearts >= 5 (TASK-348: was
	# >= 2 in the 0-4 era, now >= 5 in the 0-10 era — same 50% of the
	# ceiling), count < cap, then spend_silver. Never spend
	# speculatively (mirrors CarpenterUpgrade.gd check-before-deduct,
	# not the old deduct-then-refund mistake). Cap (chicken_count < 3)
	# is enforced at the call site per the spec, not on the var itself
	# in GameData.gd. On insufficient silver: silent skip, no dialogue
	# nag — breeding is a cozy bonus on top of the normal daily
	# collection, not a requirement.
	if GameData.chicken_hearts() >= 5 and GameData.chicken_count < 3:
		if GameData.spend_silver(40):
			GameData.chicken_count += 1
			SignalBus.show_dialogue.emit("Chickens", "A new chick hatched! The coop swells to %d hens." % GameData.chicken_count)
			# TASK-331 herd_keeper milestone — first time chicken AND buffalo herds both reach 3.
			if GameData.chicken_count >= 3 and GameData.buffalo_count >= 3:
				if GameData.earn_milestone("herd_keeper"):
					SignalBus.show_dialogue.emit("System", "Milestone: Herd Keeper! (+10 harmony)")
	return true

## TASK-348: 10-line hearts-up dialogue pool, one line per hearts value
## 1..10 in the chicken's voice — brisk, egg-and-flock framing. Called
## whenever the hearts level actually increases; replacing the prior
## 2-line "gold egg" vs "warm from the nest" branching. The gold-egg
## item-tier check in collect_egg() is a separate concern from which
## dialogue line is shown — an item-tier change and a dialogue-line
## change are not required to coincide.
func _hearts_line(hearts: int) -> String:
	var egg_word: String = "egg" if GameData.chicken_count == 1 else "eggs"
	match hearts:
		1: return "+%d %s — a soft cluck as you approach. Hearts: 1!" % [GameData.chicken_count, egg_word]
		2: return "+%d %s — the hens eye you, heads tilting. Hearts: 2!" % [GameData.chicken_count, egg_word]
		3: return "+%d %s — they don't scatter when you open the gate. Hearts: 3!" % [GameData.chicken_count, egg_word]
		4: return "+%d %s — a hen steps closer to inspect your hand. Hearts: 4!" % [GameData.chicken_count, egg_word]
		5: return "+%d %s — the rooster greets you with a short crow. Hearts: 5!" % [GameData.chicken_count, egg_word]
		6: return "+%d %s — the flock follows you around the run. Hearts: 6!" % [GameData.chicken_count, egg_word]
		7: return "+%d %s — a hen hops onto the fence to watch you work. Hearts: 7!" % [GameData.chicken_count, egg_word]
		8: return "+%d golden %s — the hens know your footsteps. Hearts: 8!" % [GameData.chicken_count, egg_word]
		9: return "+%d golden %s — a small fortune for the morning basket. Hearts: 9!" % [GameData.chicken_count, egg_word]
		10: return "+%d golden %s — the flock is yours. Hearts: 10!" % [GameData.chicken_count, egg_word]
		_: return "+%d %s — warm from the nest." % [GameData.chicken_count, egg_word]

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
