extends CharacterBody2D
## FlavorNPC — TASK-383. Minimal static background NPC: no schedule, no
## affinity, no gift system, no dialogue tiers. Interact cycles through
## exactly 3 fixed flavor lines round-robin. Exists purely for village
## liveliness/family lore — deliberately distinct from
## RomanceNPC.gd/VillagerNPC.gd/RivalNPC.gd's heavier mechanical systems.

const FlavorDialogueScript: GDScript = preload("res://scripts/narrative/FlavorDialogue.gd")
const DialogueDBScript: GDScript = preload("res://scripts/narrative/DialogueDB.gd")

# TASK-385: family NPC -> linked romance candidate for the once-per-day
# gift hint. Kwan/chang is deliberately absent — Somchai is a shared
# mentor figure, not exclusively her family NPC, so no hint routes via him.
const FAMILY_GIFT_CANDIDATE: Dictionary = {
	"charoen": "fah",
	"somsri": "ploy",
	"gaew": "ek",
	"boonchu": "klong",
	"ampai": "yaa",
}

# TASK-384: one-time family marriage reactions. npc_id -> candidate npc_id
# this family member reacts to. Only these 5 npc_ids are in this map;
# everyone else is unaffected.
const MARRIAGE_REACTION_CANDIDATE: Dictionary = {
	"charoen": "fah",
	"somsri": "ploy",
	"gaew": "ek",
	"boonchu": "klong",
	"ampai": "yaa",
}

# TASK-384 locked reaction lines — verbatim, do not paraphrase.
const MARRIAGE_REACTION_LINE: Dictionary = {
	"charoen": "Fah brought home news today — married, she says, like it's a small thing. It isn't. Take care of her out there on the water.",
	"somsri": "Ploy told me before she told half the village, which is more than I expected. I'm glad it's you.",
	"gaew": "Mali actually cried a little. Don't tell her I told you. Welcome to the family, I suppose — try to keep up with her.",
	"boonchu": "Rin asked me to play at the wedding. Forty years of drumming, and that request meant more than most.",
	"ampai": "Yaa's been humming since she told me. I haven't heard that in a while. Thank you for that.",
}

@export var npc_id: String = ""
@export var display_name: String = ""

var _player_in_range: bool = false
var _line_index: int = 0

@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null

func _ready() -> void:
	add_to_group("flavor_npc")
	if _area != null:
		_area.body_entered.connect(_on_body_entered)
		_area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		_talk()
		get_viewport().set_input_as_handled()

func _current_day() -> int:
	# TASK-385: same "once per day" day-source as VillagerNPC.gd's
	# villager_talked_days use — SignalBus.time_manager's current day.
	var tm: Node = SignalBus.time_manager
	if tm != null and "day" in tm:
		return int(tm.day)
	return 1

func _family_hint_item(candidate_id: String) -> String:
	# TASK-385: deterministic gift-hint pick — first "loved" item if one
	# exists, otherwise the first "liked" item. Purely informational, no
	# affinity change for hearing it.
	var prefs: Dictionary = DialogueDBScript.GIFT_PREFERENCES.get(candidate_id, {})
	var loved: Array = prefs.get("loved", [])
	if not loved.is_empty():
		return String(loved[0])
	var liked: Array = prefs.get("liked", [])
	if not liked.is_empty():
		return String(liked[0])
	return ""

func _talk() -> void:
	# TASK-384: one-shot marriage reaction replaces the normal flavor-line
	# cycle the FIRST time the player talks to this family NPC after the
	# relevant marriage, then reverts to normal cycling forever after.
	# Idempotent — never shows twice. Does not advance _line_index so the
	# normal cycle resumes exactly where it left off.
	if MARRIAGE_REACTION_CANDIDATE.has(npc_id):
		var want: String = String(MARRIAGE_REACTION_CANDIDATE[npc_id])
		var shown: Dictionary = GameData.family_marriage_reaction_shown as Dictionary
		if GameData.married and String(GameData.spouse) == want and not bool(shown.get(npc_id, false)):
			shown[npc_id] = true
			SignalBus.show_dialogue.emit(display_name, String(MARRIAGE_REACTION_LINE[npc_id]))
			return
	var lines: Array = FlavorDialogueScript.FLAVOR_LINES.get(npc_id, [])
	if lines.is_empty():
		return
	# TASK-385: the FIRST talk of the day to one of the 5 family NPCs
	# surfaces ONE hint line naming a real item from their candidate's
	# GIFT_PREFERENCES, INSTEAD of the normal flavor cycle (a second
	# show_dialogue emit would just overwrite the first — World has no
	# dialogue queue — so only one line per talk). The hint consumes no
	# flavor-cycle step: _line_index is untouched, so subsequent talks
	# the same day behave exactly as before. Cooldown state lives in
	# GameData.family_gift_hint_last_day (npc_id -> last_day), a NEW dict
	# — villager_talked_days is VillagerNPC-specific and is not reused.
	if FAMILY_GIFT_CANDIDATE.has(npc_id):
		var day: int = _current_day()
		if int(GameData.family_gift_hint_last_day.get(npc_id, -1)) != day:
			var item_id: String = _family_hint_item(String(FAMILY_GIFT_CANDIDATE[npc_id]))
			if not item_id.is_empty():
				GameData.family_gift_hint_last_day[npc_id] = day
				SignalBus.show_dialogue.emit(display_name, "She's always going on about %s." % String(item_id).replace("_", " "))
				return
	SignalBus.show_dialogue.emit(display_name, String(lines[_line_index % lines.size()]))
	_line_index += 1

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = false
