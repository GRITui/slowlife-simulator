extends Node
## QuestLog — TASK-057 (#111): first quest chains on the TASK-053
## QuestData/GameData.active_quests primitive. Loads data/quests/quests.json,
## hands out quests by giver interaction, and completes objectives when the
## matching SignalBus events fire (decoupled — listens, never reaches).

const QUESTS_PATH: String = "res://data/quests/quests.json"
var _chains: Dictionary = {}

func _ready() -> void:
	add_to_group("quest_log")
	_load_chains()
	SignalBus.craft_completed.connect(_on_craft_completed)
	SignalBus.crop_harvested.connect(_on_crop_harvested)
	SignalBus.binthabat_offered.connect(_on_binthabat_offered)
	SignalBus.infrastructure_repaired.connect(_on_infrastructure_repaired)

func _exit_tree() -> void:
	if SignalBus.craft_completed.is_connected(_on_craft_completed):
		SignalBus.craft_completed.disconnect(_on_craft_completed)
	if SignalBus.crop_harvested.is_connected(_on_crop_harvested):
		SignalBus.crop_harvested.disconnect(_on_crop_harvested)
	if SignalBus.binthabat_offered.is_connected(_on_binthabat_offered):
		SignalBus.binthabat_offered.disconnect(_on_binthabat_offered)
	if SignalBus.infrastructure_repaired.is_connected(_on_infrastructure_repaired):
		SignalBus.infrastructure_repaired.disconnect(_on_infrastructure_repaired)

func _load_chains() -> void:
	var f: FileAccess = FileAccess.open(QUESTS_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary and (parsed as Dictionary).has("quests"):
		for q: Dictionary in (parsed as Dictionary)["quests"] as Array:
			_chains[String(q.get("id", ""))] = q

func get_chain(quest_id: String) -> Dictionary:
	return _chains.get(quest_id, {}) as Dictionary

## Called by the giver NPC's interact: offers the quest if not started.
func offer_quest(quest_id: String) -> void:
	if not _chains.has(quest_id) or GameData.active_quests.has(quest_id):
		return
	var chain: Dictionary = get_chain(quest_id)
	var objectives: Array = chain.get("objectives", []) as Array
	GameData.start_quest(quest_id, objectives.size())
	# Talking to the giver immediately satisfies the talk objective.
	var first: String = String(objectives[0]) if not objectives.is_empty() else ""
	if first.begins_with("talk_to_"):
		GameData.complete_objective(quest_id, first)
	SignalBus.show_dialogue.emit(String(chain.get("giver_npc_id", "npc")), "%s — will you help? (%s)" % [String(chain.get("display_name", quest_id)), "quest started"])

## Offers the first available quest for a given giver NPC.
func offer_quest_for_giver(giver_npc_id: String) -> void:
	for quest_id in _chains.keys():
		var chain: Dictionary = _chains[quest_id] as Dictionary
		if String(chain.get("giver_npc_id", "")) == giver_npc_id and not GameData.active_quests.has(quest_id):
			offer_quest(quest_id)
			return

## Event-driven objective completion.
func _on_craft_completed(item_id: String, _qty: int) -> void:
	# Fish catches flow through craft_completed (TASK-050 reuses it).
	_check_objective_by_item(item_id)
	# TASK-310: Handle craft-based objectives for migrated quests.
	if item_id == "stamina_mash" or item_id == "nam_prik":
		complete_objective_everywhere("craft_stamina_mash")
		complete_objective_everywhere("deliver_nam_prik_to_trader")
	if item_id == "fish_sauce":
		complete_objective_everywhere("acquire_fish_sauce")
	if item_id == "wood" or item_id == "flood_ward_charm":
		complete_objective_everywhere("gather_reinforcement_wood")

func _on_crop_harvested(crop_id: int) -> void:
	# TASK-310: Harvest objectives for migrated quests.
	complete_objective_everywhere("harvest_jasmine_rice")
	complete_objective_everywhere("harvest_two_crop_types")

func _on_binthabat_offered(item_id: String, _harmony_yield: int) -> void:
	# TASK-310: Binthabat objectives.
	complete_objective_everywhere("offer_binthabat")
	complete_objective_everywhere("binthabat_day_1")
	complete_objective_everywhere("binthabat_day_2")
	complete_objective_everywhere("binthabat_day_3")

func _on_infrastructure_repaired(structure_id: String) -> void:
	if structure_id == "sluice_gate":
		complete_objective_everywhere("reinforce_the_banks")

func _check_objective_by_item(item_id: String) -> void:
	if item_id.begins_with("pla_"):
		complete_objective_everywhere("catch_a_fish")
		# TASK-310: Fah's rare fish objective.
		if item_id.ends_with("_rare") or item_id.ends_with("_big"):
			complete_objective_everywhere("catch_rare_tier_fish")
		complete_objective_everywhere("catch_two_fish")
	elif item_id == "wan_sart_basket" or item_id == "krathong":
		complete_objective_everywhere("make_offering")
	elif item_id == "durian":
		complete_objective_everywhere("deliver_durian_to_niran")
		complete_objective_everywhere("harvest_two_crop_types")
	elif item_id == "banana_leaf" or item_id == "banana":
		complete_objective_everywhere("find_the_empty_crate")
		complete_objective_everywhere("donate_fruit_for_the_banquet")
	elif item_id == "three_wise_monkeys_figurine":
		complete_objective_everywhere("host_the_banquet")

## Called when player talks to an NPC — completes talk objectives.
func on_npc_talked(npc_id: String) -> void:
	complete_objective_everywhere("talk_to_" + npc_id)
	complete_objective_everywhere("interview_ton" if npc_id == "child" else "")
	complete_objective_everywhere("report_to_handler" if npc_id == "handler" else "")
	complete_objective_everywhere("speak_with_the_monk" if npc_id == "monk" else "")
	complete_objective_everywhere("examine_forest_clues" if npc_id == "child" else "")
	complete_objective_everywhere("confront_the_maskmaker" if npc_id == "elder" else "")
	complete_objective_everywhere("clear_up_the_misunderstanding" if npc_id == "elder" else "")
	complete_objective_everywhere("feed_buffalo_mash" if npc_id == "handler" else "")
	complete_objective_everywhere("enter_the_race" if npc_id == "handler" else "")

func complete_objective_everywhere(objective_id: String) -> void:
	for quest_id: String in GameData.active_quests.keys():
		GameData.complete_objective(quest_id, objective_id)
		if GameData.is_quest_complete(quest_id):
			_payout(quest_id)

func _payout(quest_id: String) -> void:
	var chain: Dictionary = get_chain(quest_id)
	if chain.is_empty():
		return
	var item: String = String(chain.get("reward_item_id", ""))
	var qty: int = int(chain.get("reward_item_qty", 1))
	if item != "":
		GameData.add_item(item, qty)
	GameData.add_harmony(int(chain.get("reward_harmony", 0)))
	SignalBus.show_dialogue.emit("Quest", "%s complete! +%d %s, +%d harmony." % [
		String(chain.get("display_name", quest_id)), qty, item.replace("_", " "), int(chain.get("reward_harmony", 0))])

## Manual completion for non-event objectives (tests / NPC hooks).
func complete_objective(quest_id: String, objective_id: String) -> void:
	GameData.complete_objective(quest_id, objective_id)
	if GameData.is_quest_complete(quest_id):
		_payout(quest_id)
