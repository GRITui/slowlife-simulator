extends CharacterBody2D
## RivalNPC — TASK-342. A named rival competing for a specific romance
## candidate. Talks (dialogue escalates with the courtship clock) AND
## accepts gifts (building rival_friendship, TASK-347) — high enough
## friendship unlocks a one-time reward + the confession dilemma
## (TASK-342 part C). Never touches the candidate's own affinity.
##
## Resolve order in try_interact() (matches DELEGATE_TASK342.md §1):
##   1. _try_confession_resolution() — concede via krathong (if confessed).
##   2. _give_gift()                — build rival_friendship (any food held).
##   3. talk()                      — escalation-tier dialogue fallback.

const DialogueDBScript: GDScript = preload("res://scripts/narrative/DialogueDB.gd")

@export var npc_id: String = ""
@export var display_name: String = ""
@export var candidate_id: String = ""

var _player_in_range: bool = false
var _talk_count: int = 0

@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null

func _ready() -> void:
	add_to_group("villager_npc")
	add_to_group("rival_npc")
	if _area != null:
		_area.body_entered.connect(_on_body_entered)
		_area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		try_interact()
		get_viewport().set_input_as_handled()

## Concede (krathong) first, then gift, then talk — matches DELEGATE_TASK342.md §1.
func try_interact() -> void:
	if _try_confession_resolution():
		return
	if _give_gift():
		return
	talk()

func talk() -> void:
	var tier: int = int(GameData.rival_warning_shown.get(candidate_id, 0))
	var has_won: bool = bool(GameData.lost_to_rival.get(candidate_id, false))
	var line: String = DialogueDBScript.get_rival_line(npc_id, tier, has_won, _talk_count)
	_talk_count += 1
	SignalBus.show_dialogue.emit(display_name, line)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = false

## Mirrors RomanceNPC._give_gift() exactly, applied to rival_friendship
## instead of affinity. Uses the SAME GIFT_PREFERENCES/gift_tier()
## mechanism (the rival-side GIFT_PREFERENCES entries in DialogueDB.gd
## reuse each rival's paired candidate's OWN loved items).
func _give_gift() -> bool:
	var gift_id: String = ""
	for item_id: String in GameData.inventory.keys():
		if item_id in GameData.FOOD_ITEMS and int(GameData.inventory[item_id]) > 0:
			gift_id = item_id
			break
	if gift_id.is_empty():
		return false
	GameData.remove_item(gift_id, 1)
	var tier: String = DialogueDBScript.gift_tier(npc_id, gift_id)
	var delta: int = DialogueDBScript.gift_affinity(tier)
	GameData.rival_friendship[npc_id] = clampi(int(GameData.rival_friendship.get(npc_id, 0)) + delta, 0, 100)
	SignalBus.show_dialogue.emit(display_name, "Thanks for the %s." % gift_id.replace("_", " "))
	_maybe_trigger_confession()
	return true

## Fires once, the first time rival_friendship reaches level 6+ (friendly-
## NPC affiliation uses the same 10-level scale per the owner's instruction;
## see GameData.level_for()). Grants the fixed reward regardless of what
## the player chooses next, then marks the confession as delivered so it
## never repeats (repeat gifts after confession don't re-trigger or re-grant).
func _maybe_trigger_confession() -> void:
	if bool(GameData.rival_confessed.get(npc_id, false)):
		return
	if GameData.level_for(int(GameData.rival_friendship.get(npc_id, 0))) < 6:
		return
	GameData.rival_confessed[npc_id] = true
	GameData.add_silver(25)
	GameData.add_harmony(15)
	SignalBus.show_dialogue.emit(display_name,
		"Can I tell you something? I'm in love with %s. Has been for a while. ... Thank you for listening — that's worth more than you know. (+25 silver, +15 harmony)" % _candidate_display_name())

## Continue-rivalry path = no special action. The player just keeps
## courting the candidate normally; RivalClock's existing win/loss logic
## is completely unaffected by any of this. (No code branch needed —
## noting it explicitly here so nobody tries to build a "choice A" branch
## that doesn't need to exist.)
func _candidate_display_name() -> String:
	return candidate_id.capitalize()

## Concede path — checked BEFORE _give_gift() in try_interact(). A krathong
## is not a FOOD_ITEMS entry, so _give_gift() would never pick it up anyway,
## but checking it explicitly first makes the precedence unambiguous. Only
## fires after the confession has fired, sets lost_to_rival permanently
## (same enforcement point as neglect-loss, just reached by generosity
## instead of inaction), grants the matchmaker_<rival_id> milestone
## (TASK-331's existing milestone system, reused), and a second krathong
## attempt is a no-op (already resolved, guard at top).
func _try_confession_resolution() -> bool:
	if not bool(GameData.rival_confessed.get(npc_id, false)):
		return false
	if bool(GameData.lost_to_rival.get(candidate_id, false)) or (GameData.married and GameData.spouse == candidate_id):
		return false
	if not GameData.has_item("krathong", 1):
		return false
	GameData.remove_item("krathong", 1)
	GameData.lost_to_rival[candidate_id] = true
	GameData.earn_milestone("matchmaker_%s" % npc_id, 20)
	SignalBus.show_dialogue.emit(display_name,
		"You're... sure? ... Thank you. I won't forget this. (Milestone: Matchmaker! +20 harmony)")
	return true