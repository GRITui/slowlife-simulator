extends CharacterBody2D
# Buffalo — TASK-020 cozy care, no combat. Feed/pet via interact.
# TASK-311 (#159 BUG fix): daily-gated milk (Binthabat pattern), affinity
# accrual per interaction, hearts surfaced via SignalBus + HUD.

@export var buffalo_id: String = "buffalo_01"
var _player_in_range: bool = false
var _last_milk_day: int = -1

@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null

func _ready() -> void:
	add_to_group("buffalo")
	if _area != null:
		if not _area.body_entered.is_connected(_on_enter):
			_area.body_entered.connect(_on_enter)
		if not _area.body_exited.is_connected(_on_exit):
			_area.body_exited.connect(_on_exit)

func _current_day() -> int:
	var tm: Node = SignalBus.time_manager
	if tm != null and "day" in tm:
		return int(tm.day)
	return 1

func interact() -> bool:
	var day: int = _current_day()
	if _last_milk_day == day:
		SignalBus.show_dialogue.emit("Buffalo", "Already tended today — the buffalo grazes contentedly.")
		return false
	_last_milk_day = day
	var hearts_before: int = GameData.buffalo_hearts()
	GameData.add_buffalo_affinity(5)
	SignalBus.buffalo_affinity_changed.emit(GameData.buffalo_affinity, GameData.buffalo_hearts())
	# TASK-348: high-milk tier moved from hearts >= 3 (old 0-4 scale, 75%) to
	# hearts >= 8 (new 0-10 scale, 80%) — the 0-4 "trust" threshold was
	# rescaled to the same percentage of the new ceiling.
	var milk_id: String = "buffalo_milk_high" if GameData.buffalo_hearts() >= 8 else "buffalo_milk"
	# TASK-323B: yield scales with herd size — one milk per buffalo (count 1..3).
	GameData.add_item(milk_id, GameData.buffalo_count)
	if GameData.buffalo_hearts() > hearts_before:
		# TASK-348: full 10-line hearts-up dialogue pool replaces the prior
		# 2-line "high milk" vs "more milk" branching. The pool is keyed
		# by the NEW hearts value (1..10) — line choice is independent of
		# the high-milk item-tier check above.
		SignalBus.show_dialogue.emit("Buffalo", _hearts_line(GameData.buffalo_hearts()))
	else:
		SignalBus.show_dialogue.emit("Buffalo", "The buffalo nuzzles you. +%d milk (hearts %d)." % [GameData.buffalo_count, GameData.buffalo_hearts()])
	# TASK-323B: breeding attempt — automatic side effect of the daily
	# interact, mirrors ChickenCoop.gd's breeding block exactly. Never
	# spend silver speculatively — check hearts/cap first, spend only on
	# success. Silent skip on insufficient silver (cozy bonus, not a
	# requirement).
	# TASK-348: breeding threshold moved from hearts >= 2 (old 0-4 = 50%)
	# to hearts >= 5 (new 0-10 = 50%) — same percentage of the ceiling,
	# new number.
	if GameData.buffalo_hearts() >= 5 and GameData.buffalo_count < 3:
		if GameData.spend_silver(60):
			GameData.buffalo_count += 1
			SignalBus.show_dialogue.emit("Buffalo", "A new calf joined the herd! Now %d buffalo strong." % GameData.buffalo_count)
			# TASK-331 herd_keeper milestone — first time buffalo AND chicken herds both reach 3.
			if GameData.buffalo_count >= 3 and GameData.chicken_count >= 3:
				if GameData.earn_milestone("herd_keeper"):
					SignalBus.show_dialogue.emit("System", "Milestone: Herd Keeper! (+10 harmony)")
	return true

## TASK-348: 10-line hearts-up dialogue pool, one line per hearts value
## 1..10 in the buffalo's voice — calm, steady, milk-and-trust framing.
## Called whenever the hearts level actually increases; replacing the
## prior 2-line "high milk" vs "more milk" branching. The high-milk
## item-tier check in interact() is a separate concern from which
## dialogue line is shown — an item-tier change and a dialogue-line
## change are not required to coincide.
func _hearts_line(hearts: int) -> String:
	match hearts:
		1: return "The buffalo lets you near. +%d milk — the first day it didn't shy away. Hearts: 1!" % GameData.buffalo_count
		2: return "The buffalo holds still while you work. +%d milk — it knows your scent now. Hearts: 2!" % GameData.buffalo_count
		3: return "The buffalo lows softly when you approach. +%d milk — your steps have become familiar. Hearts: 3!" % GameData.buffalo_count
		4: return "The buffalo leans into your hand. +%d milk — the pail fills a little easier today. Hearts: 4!" % GameData.buffalo_count
		5: return "The buffalo follows you to the gate. +%d milk — half-trusted now. Hearts: 5!" % GameData.buffalo_count
		6: return "The buffalo waits for you at milking time. +%d milk — steady, unhurried. Hearts: 6!" % GameData.buffalo_count
		7: return "The buffalo rests its chin on the fence rail. +%d milk — the herd knows your name. Hearts: 7!" % GameData.buffalo_count
		8: return "The buffalo trusts you deeply — rich golden milk fills the pail. +%d milk! Hearts: 8!" % GameData.buffalo_count
		9: return "The buffalo breathes slow beside you, warm as a hearth. +%d milk — milk thick as cream. Hearts: 9!" % GameData.buffalo_count
		10: return "The buffalo is family. +%d milk — the richest the herd has ever given. Hearts: 10!" % GameData.buffalo_count
		_: return "The buffalo nuzzles you. +%d milk (hearts %d)." % [GameData.buffalo_count, hearts]

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		interact()
		get_viewport().set_input_as_handled()

func _on_enter(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = true

func _on_exit(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = false
