extends CharacterBody2D
## RomanceNPC — TASK-052. Peer NPCs (Niran/Fah) with affinity-driven
## dialogue tiers + v1 gift-giving (any FOOD_ITEMS item, +10 affinity).
## VillagerNPC contract mirror (Area2D proximity + interact), SignalBus-only.

const DialogueDBScript: GDScript = preload("res://scripts/narrative/DialogueDB.gd")

@export var npc_id: String = "niran"
@export var display_name: String = "Niran"

var _player_in_range: bool = false
var _talk_count: int = 0

@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null

func _ready() -> void:
	add_to_group("villager_npc")
	add_to_group("romance_candidate")
	if _area != null:
		_area.body_entered.connect(_on_body_entered)
		_area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		try_interact()
		get_viewport().set_input_as_handled()

## Gift first, then specialty sell (close tier, +45% premium, 3/week), then proposal check (romantic + krathong held), else talk.
func try_interact() -> bool:
	# Phase 3 audit (2026-09-02): quest talk-tracking previously ran only
	# inside the _talk() fallback at the bottom of this method, so any
	# earlier branch that returned first — _give_gift() especially, which
	# fires on ANY interact while holding food (extremely common in a
	# farming sim) — silently skipped talk_to_<npc_id> quest objectives
	# for that click. Moved here, unconditional, before every branch
	# below (anniversary/specialty-sell/gift/proposal/talk), none of
	# which are otherwise touched.
	_try_offer_quest()
	_try_complete_talk_objective()
	# TASK-333 (design pivot from affinity decay, which conflicted with the
	# established no-fail-state precedent — see TASK-319/324): a weekly
	# interaction streak grants a small BONUS on top of normal affinity
	# gains instead of punishing neglect. Granted silently (no dialogue
	# line — show_dialogue has no queue, a line here would just be
	# overwritten by whichever branch below emits next).
	var tm_bonus: Node = SignalBus.time_manager
	var day_bonus: int = int(tm_bonus.day) if tm_bonus != null and "day" in tm_bonus else 1
	var bonus: int = GameData.record_weekly_engagement(npc_id, day_bonus)
	if bonus > 0:
		GameData.add_affinity(npc_id, bonus)
	if GameData.married and GameData.spouse == npc_id:
		# TASK-282: marriage ceiling payoff — annual anniversary, cozy loop.
		var tm: Node = SignalBus.time_manager
		var year: int = int(tm.year()) if tm != null and tm.has_method("year") else 1
		var key: String = "anniversary_%d_%s" % [year, npc_id]
		if not GameData.active_quests.has(key):
			GameData.active_quests[key] = {"stage": 1, "objectives_done": []}
			GameData.add_silver(30)
			GameData.add_harmony(10)
			SignalBus.festival_triggered.emit("anniversary_" + npc_id)
			# TASK-324 life progression: stage the child on this anniversary
			# (0->1 pregnant, 1->2 born, 2->3 toddler), awarding a harmony bonus
			# and replacing the standard anniversary line with a milestone line.
			# Silver amount, add_harmony(10), and festival_triggered.emit above
			# must stay exactly as they are — do not add a new festival event
			# and do not change silver; test_anniversary.gd depends on both.
			var years_married: int = year - int(GameData.married_year)
			var milestone_line: String = ""
			if years_married >= 1 and int(GameData.child_stage) == 0:
				GameData.child_stage = 1
				GameData.add_harmony(15)
				milestone_line = "There's a little one on the way — the village grows. (+15 harmony)"
			elif years_married >= 2 and int(GameData.child_stage) == 1:
				GameData.child_stage = 2
				GameData.add_harmony(25)
				milestone_line = "The baby is here — small, calm, ours. (+25 harmony)"
			elif years_married >= 3 and int(GameData.child_stage) == 2:
				GameData.child_stage = 3
				GameData.add_harmony(15)
				milestone_line = "Our child is walking now — every step a small festival. (+15 harmony)"
			if milestone_line.is_empty():
				SignalBus.show_dialogue.emit(display_name, "Happy anniversary, year %d — I saved up for us. (+30 silver, +10 harmony)" % year)
			else:
				SignalBus.show_dialogue.emit(display_name, milestone_line)
		else:
			SignalBus.show_dialogue.emit(display_name, "Home is wherever the two of us stop working. Let's head in soon.")
		return true
	if _try_specialty_sell():
		return true
	if _give_gift():
		return true
	if _check_proposal():
		return true
	_talk()
	return false

func _try_specialty_sell() -> bool:
	# TASK-313 Channel C: Specialty Buyer — close tier (60+), +45% premium, 3/week cap.
	var tm: Node = SignalBus.time_manager
	var day: int = int(tm.day) if tm != null and "day" in tm else 1
	if not GameData.can_specialty_sell(npc_id, day):
		return false
	var want_item: String = ""
	if npc_id == "fah":
		for item_id in ["pla_nin_big", "pla_soi_big", "pla_chon_big", "mango_sticky_rice", "lotus_root"]:
			if GameData.has_item(item_id, 1):
				want_item = item_id
				break
		if want_item.is_empty():
			for item_id in GameData.inventory.keys():
				if String(item_id).begins_with("pla_") and GameData.has_item(item_id, 1):
					want_item = item_id
					break
	elif npc_id == "niran":
		for item_id in ["durian", "mango", "durian_sticky_rice", "mango_sticky_rice"]:
			if GameData.has_item(item_id, 1):
				want_item = item_id
				break
	if want_item.is_empty():
		return false
	var gained: int = GameData.sell_item_premium(want_item, "specialty")
	if gained > 0:
		GameData.record_specialty_sale(npc_id, day)
		SignalBus.show_dialogue.emit(display_name, "Specialty buyer: %s for %d silver! (close-tier premium, %d/3 this week)" % [want_item.replace("_", " "), gained, int(GameData.specialty_sales_this_week.get(npc_id, 0))])
		return true
	return false

## TASK-059: proposal — romantic tier (>=90) + krathong held. Cozy, mutual:
## the NPC accepts and a small wedding fires via festival_triggered.
func _check_proposal() -> bool:
	if GameData.married or GameData.get_affinity(npc_id) < 90:
		return false
	if not GameData.has_item("krathong", 1):
		return false
	GameData.remove_item("krathong", 1)
	GameData.married = true
	GameData.spouse = npc_id
	# TASK-324: record the wedding year so the anniversary branch can compute
	# years_married for life-progression stage transitions. Mirrors the
	# SignalBus.time_manager.year() lookup the anniversary block uses above.
	var tm: Node = SignalBus.time_manager
	var year: int = int(tm.year()) if tm != null and tm.has_method("year") else 1
	GameData.married_year = year
	GameData.add_affinity(npc_id, 10) # cap keeps it at 100
	GameData.add_harmony(20)
	SignalBus.festival_triggered.emit("wedding_" + npc_id)
	SignalBus.show_dialogue.emit(display_name, "Yes. Lanterns, family, the whole village — let's be married.")
	return true

func _give_gift() -> bool:
	var gift_id: String = ""
	for item_id: String in GameData.inventory.keys():
		if item_id in GameData.FOOD_ITEMS and int(GameData.inventory[item_id]) > 0:
			gift_id = item_id
			break
	if gift_id.is_empty():
		return false
	GameData.remove_item(gift_id, 1)
	# TASK-054: per-NPC preference table scales the affinity delta.
	var tier: String = DialogueDBScript.gift_tier(npc_id, gift_id)
	var delta: int = DialogueDBScript.gift_affinity(tier)
	GameData.add_affinity(npc_id, delta)
	var affinity: int = GameData.get_affinity(npc_id)
	match tier:
		"loved":
			SignalBus.show_dialogue.emit(display_name, "%s — you remembered! (affinity %d)" % [gift_id.replace("_", " "), affinity])
		"liked":
			SignalBus.show_dialogue.emit(display_name, "%s is nice of you. (affinity %d)" % [gift_id.replace("_", " "), affinity])
		_:
			SignalBus.show_dialogue.emit(display_name, "%s — thank you. (affinity %d)" % [gift_id.replace("_", " "), affinity])
	return true

func _talk() -> void:
	var tier: String = DialogueDBScript.get_affinity_tier(GameData.get_affinity(npc_id))
	# TASK-324: occasional light rival pressure on the close-tier courtship
	# path — every 5th talk only, and never when married to this NPC. Swaps
	# the dialogue pool for that one call; everything else (talk-count,
	# quest hooks) stays unchanged.
	if tier == "close" and not (GameData.married and GameData.spouse == npc_id) and _talk_count % 5 == 4:
		tier = "rival"
	var line: String = DialogueDBScript.get_line(npc_id, tier, _talk_count)
	_talk_count += 1
	SignalBus.show_dialogue.emit(display_name, line)

func _try_complete_talk_objective() -> void:
	var quest_logs: Array = get_tree().get_nodes_in_group("quest_log")
	if quest_logs.is_empty():
		return
	var quest_log: Node = quest_logs[0] as Node
	if quest_log != null and quest_log.has_method("on_npc_talked"):
		quest_log.on_npc_talked(npc_id)

func _try_offer_quest() -> void:
	var quest_logs: Array = get_tree().get_nodes_in_group("quest_log")
	if quest_logs.is_empty():
		return
	var quest_log: Node = quest_logs[0] as Node
	if quest_log != null and quest_log.has_method("offer_quest_for_giver"):
		quest_log.offer_quest_for_giver(npc_id)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = false
