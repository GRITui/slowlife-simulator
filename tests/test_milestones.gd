extends SceneTree
# TASK-331 milestone collectibles gate.
# GameData.earn_milestone() idempotency + each of the 5 trigger sites
# fires its milestone exactly once when the condition is met, and a
# second trigger of the same condition does not re-grant. Drives state
# directly via GameData (mirrors how tests/test_mining.gd /
# tests/test_fishing.gd already drive skill-up).

var _passed: int = 0
var _failed: int = 0
var _dialogue_hits: Array = [] # [speaker, text] pairs from show_dialogue

func _on_show_dialogue(speaker: String, text: String) -> void:
	_dialogue_hits.append([speaker, text])

func _milestone_dialogue_count(name: String) -> int:
	var count: int = 0
	for d in _dialogue_hits:
		if d[0] == "System" and String(d[1]).begins_with("Milestone: %s" % name):
			count += 1
	return count

func _saw_milestone_line(name: String) -> bool:
	return _milestone_dialogue_count(name) >= 1

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  milestones :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  milestones :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var sb: Node = root.get_node("SignalBus")

	# --- GameData.earn_milestone() surface ---
	gd.milestones_earned.clear()
	_check(gd.has_method("earn_milestone"), "GameData has earn_milestone()")
	var h_before: int = int(gd.harmony)
	var got: bool = gd.earn_milestone("smoke_test", 7)
	_check(got == true, "first earn_milestone() returns true")
	_check(int(gd.harmony) == h_before + 7, "first earn_milestone() grants the reward harmony")
	_check(bool(gd.milestones_earned.get("smoke_test", false)),
		"milestones_earned records the id as true")
	# Repeat call: same id -> no-op, no extra harmony.
	var got2: bool = gd.earn_milestone("smoke_test", 7)
	_check(got2 == false, "repeat earn_milestone(same id) returns false")
	_check(int(gd.harmony) == h_before + 7, "repeat earn_milestone() grants nothing extra")
	# A different id still grants, even though smoke_test is recorded.
	var got3: bool = gd.earn_milestone("other_id", 3)
	_check(got3 == true, "a different id earns normally")
	_check(int(gd.harmony) == h_before + 10, "different id grants its own reward")
	gd.milestones_earned.clear()

	# Boot World scene so MiningSpot / FishingSpot / Companion / Buffalo /
	# ChickenCoop are available as live nodes.
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	sb.show_dialogue.connect(_on_show_dialogue)

	var tm: Node = root.get_node("SignalBus").time_manager
	var mining: Node = main.get_node_or_null("MiningSpot")
	var fishing: Node = main.get_node_or_null("FishingSpot")
	var cat: CharacterBody2D = main.get_node_or_null("CompanionNPC") as CharacterBody2D
	var player: Node2D = main.get_node_or_null("Player") as Node2D
	var coop: Node = main.get_node_or_null("ChickenCoop")
	var buffalo: Node = main.get_node_or_null("Buffalo")
	_check(mining != null, "MiningSpot instanced")
	_check(fishing != null, "FishingSpot instanced")
	_check(cat != null, "CompanionNPC instanced")
	_check(player != null, "Player instanced")
	_check(coop != null, "ChickenCoop instanced")
	_check(buffalo != null, "Buffalo instanced")
	if mining == null or fishing == null or cat == null or player == null \
			or coop == null or buffalo == null:
		main.queue_free()
		await process_frame
		quit(1)
		return

	# --- 1) deep_miner: mining_skill reaches cap (3) ---
	gd.mining_skill = 2
	gd.inventory.erase("copper_ore")
	gd.inventory.erase("iron_ore")
	gd.inventory.erase("silver_ore")
	gd.milestones_earned.erase("deep_miner")
	_dialogue_hits.clear()
	# Push mining_rolls to 9 so the next successful dig promotes skill 2->3
	# (clampi(1 + 9 / 5, 1, 3) == 2, but with rolls_per_skill=5
	# the formula is clampi(1 + 10 / 5, 1, 3) == 3, so we need 10 rolls).
	# Reset mining_rolls and drive 10 digs.
	mining.set("mining_rolls", 0)
	gd.mining_skill = 1
	for i: int in 10:
		gd.current_stamina = gd.max_stamina
		mining.dig()
	_check(int(gd.mining_skill) == 3, "mining_skill reached cap 3 after 10 digs")
	_check(bool(gd.milestones_earned.get("deep_miner", false)),
		"deep_miner milestone recorded in milestones_earned")
	_check(_saw_milestone_line("Deep Miner"),
		"deep_miner milestone emits System dialogue line")
	# Repeat the triggering condition — skill is at cap, so level never
	# increases again. The milestone must not re-fire.
	var dm_dialogue_after_first: int = _milestone_dialogue_count("Deep Miner")
	for i: int in 3:
		gd.current_stamina = gd.max_stamina
		mining.dig()
	_check(_milestone_dialogue_count("Deep Miner") == dm_dialogue_after_first,
		"repeated digs after cap do not re-fire Deep Miner dialogue")
	_check(not _saw_milestone_line("Deep Miner Extra"),
		"Deep Miner system dialogue does not fire a second time (no-dupe guard)")

	# --- 2) master_angler: fishing_skill reaches cap (4) ---
	gd.milestones_earned.erase("master_angler")
	_dialogue_hits.clear()
	gd.fishing_skill = 3
	fishing.set("fishing_rolls", 14) # next cast -> rolls 15 -> level 4 (1 + 15/5)
	gd.add_item("fishing_rod", 1)
	if tm != null:
		tm.set_season("monsoon")
	gd.current_season = "monsoon"
	var cast_ok: bool = fishing.cast_line()
	_check(cast_ok, "master_angler precondition: cast_line() succeeds")
	_check(int(gd.fishing_skill) == 4, "fishing_skill reached cap 4 after master_angler trigger")
	_check(bool(gd.milestones_earned.get("master_angler", false)),
		"master_angler milestone recorded")
	_check(_saw_milestone_line("Master Angler"),
		"master_angler milestone emits System dialogue line")
	# Repeat casts — fishing_skill is at cap, so level won't go higher,
	# so master_angler should not re-fire.
	var ma_dialogue_after_first: int = _milestone_dialogue_count("Master Angler")
	for i: int in 3:
		gd.add_item("fishing_rod", 1)
		fishing.cast_line()
	_check(_milestone_dialogue_count("Master Angler") == ma_dialogue_after_first,
		"repeated casts after cap do not re-fire Master Angler dialogue")

	# --- 3) inseparable: companion_bond_tier reaches max (10) ---
	# TASK-348: rescaled from the legacy /25.0 scale (max tier 4) to the
	# 0-10 scale (TASK-346's level_for()) — max tier is now 10.
	gd.milestones_earned.erase("inseparable")
	_dialogue_hits.clear()
	gd.companion_bond = 99 # level_for(99) = 9; one more grant -> level 10
	cat.set("_nearby_minutes", 59)
	# Park cat within COMFORT so the tick triggers a +1 grant.
	player.global_position = Vector2(480, 384)
	cat.global_position = player.global_position
	sb.minute_ticked.emit(1, 6, 0)
	_check(int(gd.companion_bond_tier()) == 10,
		"companion_bond_tier reached max 10 after inseparable trigger")
	_check(bool(gd.milestones_earned.get("inseparable", false)),
		"inseparable milestone recorded")
	_check(_saw_milestone_line("Inseparable"),
		"inseparable milestone emits System dialogue line")
	# Drive more ticks — bond is at 100 (clamp), so tier never advances;
	# no second trigger.
	var is_dialogue_after_first: int = _milestone_dialogue_count("Inseparable")
	for i: int in 5:
		cat.set("_nearby_minutes", 59)
		sb.minute_ticked.emit(1, 6, 1)
	_check(_milestone_dialogue_count("Inseparable") == is_dialogue_after_first,
		"repeated companion ticks after tier 10 do not re-fire Inseparable dialogue")

	# --- 4) herd_keeper: buffalo_count >= 3 AND chicken_count >= 3 ---
	gd.milestones_earned.erase("herd_keeper")
	_dialogue_hits.clear()
	gd.buffalo_count = 2
	gd.chicken_count = 2
	gd.buffalo_affinity = 60 # 2 hearts (60/25)
	gd.chicken_affinity = 60 # 2 hearts
	gd.silver = 1000
	# Advance calendar day so the daily-gated interact/collect isn't skipped.
	if tm != null:
		tm.set_time(2, 6, 0)
	# Breed chicken first (chicken_count 2 -> 3), then buffalo (2 -> 3).
	# After both, the milestone should fire from whichever breeding block
	# lands second and sees both >= 3.
	coop.collect_egg()
	buffalo.interact()
	_check(int(gd.chicken_count) == 3, "chicken_count reached 3")
	_check(int(gd.buffalo_count) == 3, "buffalo_count reached 3")
	_check(bool(gd.milestones_earned.get("herd_keeper", false)),
		"herd_keeper milestone recorded")
	_check(_saw_milestone_line("Herd Keeper"),
		"herd_keeper milestone emits System dialogue line")
	# Both counts are at cap; further daily interacts must not re-grant.
	# Hearts >= 2 still holds, silver is plentiful, but breeding is
	# gated on count < 3 so the breeding block never runs again.
	if tm != null:
		tm.set_time(3, 6, 0)
	var hk_dialogue_after_first: int = _milestone_dialogue_count("Herd Keeper")
	buffalo.interact()
	coop.collect_egg()
	_check(_milestone_dialogue_count("Herd Keeper") == hk_dialogue_after_first,
		"repeated daily interacts at herd cap do not re-fire Herd Keeper dialogue")

	# --- 5) storm_catch: catch + monsoon + rain ---
	gd.milestones_earned.erase("storm_catch")
	_dialogue_hits.clear()
	if tm != null:
		tm.set_season("monsoon")
	gd.current_season = "monsoon"
	gd.current_weather = "rain"
	gd.add_item("fishing_rod", 1)
	var storm_ok: bool = fishing.cast_line()
	_check(storm_ok, "storm_catch precondition: cast_line() succeeds")
	_check(bool(gd.milestones_earned.get("storm_catch", false)),
		"storm_catch milestone recorded in monsoon + rain")
	_check(_saw_milestone_line("Storm Catch"),
		"storm_catch milestone emits System dialogue line")
	# A second cast in the same conditions must NOT re-grant — the
	# milestone dict guard keeps it idempotent.
	gd.add_item("fishing_rod", 1)
	var storm_ok2: bool = fishing.cast_line()
	_check(storm_ok2, "second cast in monsoon+rain succeeds")
	_check(_milestone_dialogue_count("Storm Catch") == 1,
		"second storm_catch does not re-fire Storm Catch dialogue (idempotent)")

	sb.show_dialogue.disconnect(_on_show_dialogue)
	main.queue_free()
	print("\n=== MILESTONES TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("MILESTONES GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)