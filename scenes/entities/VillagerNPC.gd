extends CharacterBody2D
## VillagerNPC — TASK-012 generic village NPC (elder / child / handler)
## Seasonal dialogue passes + Binthabat event-tree hints, no heavy exposition.
## Decoupled via SignalBus.show_dialogue. Y-sort friendly, cozy ambient only.

const DialogueDBScript: GDScript = preload("res://scripts/narrative/DialogueDB.gd")
const ScheduleDBScript: GDScript = preload("res://scripts/narrative/ScheduleDB.gd")

@export var npc_id: String = "elder" ## elder | child | handler
@export var display_name: String = "Elder"
@export var idle_texture: Texture2D

var _player_in_range: bool = false
var _talk_count: int = 0
var _last_talk_day: int = -1

@onready var _sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null

var _schedule_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("villager_npc")
	add_to_group(npc_id)
	# TASK-313 Channel A: Trader evening visit (18:00-21:00 at farm).
	if npc_id == "trader":
		_update_trader_visibility()
	# TASK-058: drift toward the schedule waypoint (only for scheduled NPCs).
	if not ScheduleDBScript.SCHEDULES.has(npc_id):
		set_physics_process(npc_id == "trader") # trader needs visibility updates even without schedule
	else:
		_schedule_pos = ScheduleDBScript.waypoint_for(npc_id, _current_hour(), _current_weather()) * 48.0 + Vector2(24, 24)
		global_position = _schedule_pos

func _current_hour() -> int:
	var tm: Node = SignalBus.time_manager
	if tm != null and "hour" in tm:
		return int(tm.hour)
	return 6

## TASK-328: weather-aware schedule override (rain routes elder/child home).
func _current_weather() -> String:
	if "current_weather" in GameData:
		return String(GameData.current_weather)
	return "clear"

func _update_trader_visibility() -> void:
	# TASK-313 Channel A: Trader at farm evenings 18:00-21:00.
	var tm: Node = SignalBus.time_manager
	var hour: int = int(tm.hour) if tm != null and "hour" in tm else 12
	var available: bool = hour >= 18 and hour < 21
	visible = available
	if has_node("CollisionShape2D"):
		($CollisionShape2D as CollisionShape2D).disabled = not available
	if available:
		# Farm position (near home, not using schedule)
		global_position = Vector2(2 * 48 + 24, 4 * 48 + 24)

## TASK-058: cozy waypoint drift — called from _physics_process. Static
## NPCs (unscheduled) skip this entirely via set_physics_process(false).
func _physics_process(_delta: float) -> void:
	if npc_id == "trader":
		_update_trader_visibility()
		return
	var tm: Node = SignalBus.time_manager
	if tm != null:
		var target: Vector2 = ScheduleDBScript.waypoint_for(npc_id, int(tm.hour), _current_weather()) * 48.0 + Vector2(24, 24)
		if target != _schedule_pos:
			_schedule_pos = target
		var dist: float = global_position.distance_to(_schedule_pos)
		if dist > 8.0:
			velocity = (_schedule_pos - global_position).normalized() * 40.0
			move_and_slide()
		else:
			velocity = Vector2.ZERO
	if _area:
		if not _area.body_entered.is_connected(_on_body_entered):
			_area.body_entered.connect(_on_body_entered)
		if not _area.body_exited.is_connected(_on_body_exited):
			_area.body_exited.connect(_on_body_exited)
	if _sprite:
		if idle_texture != null:
			_sprite.texture = idle_texture
		else:
			# Headless-safe fallback: pick per-npc idle texture if none assigned.
			var path: String = ""
			match npc_id:
				"elder": path = "res://assets/characters/npc_elder_idle_01.png"
				"child": path = "res://assets/characters/npc_child_idle_01.png"
				"handler": path = "res://assets/characters/npc_handler_idle_01.png"
				# Phase 3 audit (2026-09-02): headman/vet have dedicated
				# portrait assets that sat unused — this fallback had no case
				# for either, so both silently rendered as Elder.
				"headman": path = "res://assets/characters/headman_idle_01.png"
				"vet": path = "res://assets/characters/vet_idle_01.png"
				_: path = "res://assets/characters/npc_elder_idle_01.png"
			if ResourceLoader.exists(path):
				var tex: Texture2D = load(path) as Texture2D
				if tex:
					_sprite.texture = tex
	# Seasonal tint sync is handled by World; NPCs just idle.
	# Ensure collision shape is enabled.
	if has_node("CollisionShape2D"):
		($CollisionShape2D as CollisionShape2D).disabled = false

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		talk()
		get_viewport().set_input_as_handled()

func talk() -> void:
	# Phase 3 audit (2026-09-02): quest talk-tracking must fire on every
	# interact regardless of which flavor branch below handles it (trader
	# sale, tool upgrade, specialty sell, or the new villager gifting) —
	# previously this ran only after falling through to the seasonal
	# dialogue line, so any early return (the gift branch especially,
	# which now fires on ANY interact while holding food — extremely
	# common in a farming sim) silently skipped talk_to_<npc_id> quest
	# objectives for that click. Moved here, unconditional, before any
	# early return.
	_try_offer_quest()
	_try_complete_talk_objective()
	# TASK-333 (design pivot from affinity decay, which conflicted with the
	# established no-fail-state precedent — see TASK-319/324): a weekly
	# interaction streak grants a small BONUS on top of normal affinity
	# gains instead of punishing neglect. Fires on every interact
	# (whichever branch below handles it), excluding the transactional
	# trader. Missing a week only forfeits that week's bonus and resets
	# the streak — it never reduces affinity already earned. Granted
	# silently (no separate dialogue line) — show_dialogue has no queue
	# (World._on_show_dialogue overwrites dialogue_label.text directly), so
	# a line emitted here would just get instantly overwritten by
	# whichever branch below emits its own line next.
	if npc_id != "trader":
		var tm_bonus: Node = SignalBus.time_manager
		var day_bonus: int = int(tm_bonus.day) if tm_bonus != null and "day" in tm_bonus else 1
		var bonus: int = GameData.record_weekly_engagement(npc_id, day_bonus)
		if bonus > 0:
			GameData.add_affinity(npc_id, bonus)
	# TASK-313 Channel A: Cart Trader (evening farm visit 18:00-21:00, base price).
	if npc_id == "trader":
		if not _is_trader_available():
			SignalBus.show_dialogue.emit(display_name, "Cart's gone for the day — catch me evenings at the farm (6-9pm).")
			return
		if _try_trader_sell():
			return
	# TASK-312: Handler offers tool upgrades (complementary to mount riding tool).
	if npc_id == "handler" and _try_tool_upgrade():
		return
	# TASK-313 Channel C: Specialty Buyer (close tier, +45% premium, 3/week cap).
	if (npc_id == "fah" or npc_id == "ek") and _try_specialty_sell():
		return
	# Phase 3 audit (2026-09-02): GIFT_PREFERENCES already covered elder/
	# child/handler (and headman/vet fall back to "neutral"), but only
	# RomanceNPC._give_gift() ever called it — general villagers had no
	# gifting path at all despite the data existing. Mirrors RomanceNPC's
	# exact gift mechanic (auto-consumes the first held food item);
	# trader stays transactional, no gifting.
	if npc_id != "trader" and _give_gift():
		return
	# TASK-384: Somchai's one-time marriage reaction (Kwan's mentor/uncle
	# figure). Replaces the normal seasonal line the FIRST time the player
	# talks to him after marrying chang, then reverts forever after.
	# Idempotent — never shows twice. Only npc_id "somchai" is affected.
	if npc_id == "somchai":
		var shown: Dictionary = GameData.family_marriage_reaction_shown as Dictionary
		if GameData.married and String(GameData.spouse) == "chang" and not bool(shown.get("somchai", false)):
			shown["somchai"] = true
			SignalBus.show_dialogue.emit(display_name, "Chang told me over the workbench, like it was just another piece of news. I had to put the chisel down for a minute.")
			return
	var season: String = GameData.current_season if "current_season" in GameData else "cool"
	var tm: Node = SignalBus.time_manager
	var day: int = 1
	if tm and "day" in tm:
		day = int(tm.day)
	# Daily cooldown hint: if talked today, rotate line but don't block.
	var is_new_day: bool = day != _last_talk_day
	if is_new_day:
		_last_talk_day = day
	# Binthabat streak check — has player offered today?
	var binthabat_done: bool = false
	if "last_offering_day" in GameData and "daily_offerings" in GameData:
		binthabat_done = int(GameData.last_offering_day) == day and int(GameData.daily_offerings) > 0
	var line: String = DialogueDBScript.get_seasonal_line(npc_id, season, binthabat_done, _talk_count, _current_weather(), GameData.level_for(int(GameData.affinity.get(npc_id, 0))))
	_talk_count += 1
	SignalBus.show_dialogue.emit(display_name, line)
	# Track per-NPC talk for quests (no reward loop — cozy only).
	if "villager_talked_days" in GameData:
		# GameData.villager_talked_days is Dictionary npc_id -> last_day
		var d: Dictionary = GameData.villager_talked_days as Dictionary
		d[npc_id] = day

func _try_tool_upgrade() -> bool:
	# TASK-312: Handler offers tool upgrades for rice. Tries tools in order:
	# hoe -> watering_can -> sickle. Each upgrade costs tier*8 rice.
	# Complementary track: mount's 3x3 auto-plow is situational riding tool,
	# while these tiers are permanent solo-farming upgrades.
	# TASK-317: Show shop UI with current tiers and costs.
	var shop_text: String = "Tools: "
	for tool_id in ["hoe", "watering_can", "sickle"]:
		var tier: int = GameData.tool_tier(tool_id)
		shop_text += "%s T%d" % [tool_id.capitalize(), tier]
		if tier < 3:
			shop_text += " (next: %d rice)" % (tier * 8)
		else:
			shop_text += " (MAX)"
		if tool_id != "sickle":
			shop_text += " | "
	SignalBus.show_dialogue.emit(display_name, shop_text)
	for tool_id in ["hoe", "watering_can", "sickle"]:
		var tier: int = GameData.tool_tier(tool_id)
		if tier >= 3:
			continue
		var cost: int = tier * 8
		if GameData.has_item("rice_grain", cost):
			if GameData.upgrade_tool(tool_id):
				SignalBus.show_dialogue.emit(display_name, "Upgraded %s to tier %d for %d rice! (Riding plow is separate — works only while mounted.)" % [tool_id, tier + 1, cost])
				return true
	return false

## Phase 3 audit (2026-09-02): ported from RomanceNPC._give_gift() —
## same mechanic, same GIFT_PREFERENCES table, extended to non-romance
## villagers so gifting isn't limited to the two marriage candidates.
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
	GameData.add_affinity(npc_id, delta)
	var affinity: int = GameData.get_affinity(npc_id)
	match tier:
		"loved":
			SignalBus.show_dialogue.emit(display_name, "%s — you remembered! (affinity %d)" % [gift_id.replace("_", " "), affinity])
		"liked":
			SignalBus.show_dialogue.emit(display_name, "%s is nice of you. (affinity %d)" % [gift_id.replace("_", " "), affinity])
		_:
			SignalBus.show_dialogue.emit(display_name, "Thanks for the %s. (affinity %d)" % [gift_id.replace("_", " "), affinity])
	return true

func _is_trader_available() -> bool:
	# TASK-313 Channel A: Cart Trader evening window 18:00-21:00.
	var tm: Node = SignalBus.time_manager
	if tm == null or not ("hour" in tm and "day" in tm):
		return true # headless fallback: always available for tests
	var hour: int = int(tm.hour)
	return hour >= 18 and hour < 21

func _try_trader_sell() -> bool:
	# Channel A: base price, no premium, no affinity gate.
	var sellable: String = GameData.cheapest_sellable()
	if sellable.is_empty():
		SignalBus.show_dialogue.emit(display_name, "Nothing to sell? Bring me something from the harvest.")
		return true
	var gained: int = GameData.sell_item(sellable)
	if gained > 0:
		SignalBus.show_dialogue.emit(display_name, "Cart deal: sold %s for %d silver. (base price)" % [sellable.replace("_", " "), gained])
		return true
	return false

func _try_specialty_sell() -> bool:
	# Channel C: Specialty Buyer — handled in RomanceNPC for Fah/Mali,
	# but VillagerNPC also checks for those ids if somehow routed here.
	if npc_id != "fah" and npc_id != "ek":
		return false
	var tm: Node = SignalBus.time_manager
	var day: int = int(tm.day) if tm != null and "day" in tm else 1
	if not GameData.can_specialty_sell(npc_id, day):
		return false
	# Thematic categories: Fah buys rare fish, Mali buys hot-season crops.
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
	elif npc_id == "ek":
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

func _try_offer_quest() -> void:
	var quest_logs: Array = get_tree().get_nodes_in_group("quest_log")
	if quest_logs.is_empty():
		return
	var quest_log: Node = quest_logs[0] as Node
	if quest_log != null and quest_log.has_method("offer_quest_for_giver"):
		quest_log.offer_quest_for_giver(npc_id)

func _try_complete_talk_objective() -> void:
	var quest_logs: Array = get_tree().get_nodes_in_group("quest_log")
	if quest_logs.is_empty():
		return
	var quest_log: Node = quest_logs[0] as Node
	if quest_log != null and quest_log.has_method("on_npc_talked"):
		quest_log.on_npc_talked(npc_id)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") or body.name == "Player" or body is CharacterBody2D:
		if body != self:
			_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") or body.name == "Player" or body is CharacterBody2D:
		if body != self:
			_player_in_range = false
# ENGINE-008 NavGrid consumer stub
