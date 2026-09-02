extends SceneTree
# TASK-333 gate — weekly interaction streak bonus (the non-punishing
# alternative to affinity decay chosen instead, per owner decision
# 2026-09-02). Verifies GameData.record_weekly_engagement()'s streak math
# directly, then end-to-end through VillagerNPC.talk() and
# RomanceNPC.try_interact().

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  weekly-engagement :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  weekly-engagement :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")

	# --- direct unit checks on the streak function ---
	_check(int(gd.record_weekly_engagement("elder", 0)) == 0, "week 0: first-ever interaction grants no bonus")
	_check(int(gd.npc_weekly_streak.get("elder", 0)) == 1, "week 0: streak starts at 1")
	_check(int(gd.record_weekly_engagement("elder", 2)) == 0, "still week 0 (day 2): no repeat bonus, no streak change")
	_check(int(gd.npc_weekly_streak.get("elder", 0)) == 1, "streak unchanged on same-week repeat")
	_check(int(gd.record_weekly_engagement("elder", 7)) == 1, "week 1 (day 7), consecutive: +1 bonus")
	_check(int(gd.npc_weekly_streak.get("elder", 0)) == 2, "streak advances to 2")
	_check(int(gd.record_weekly_engagement("elder", 14)) == 2, "week 2, consecutive: +2 bonus")
	_check(int(gd.record_weekly_engagement("elder", 21)) == 3, "week 3, consecutive: +3 bonus")
	_check(int(gd.record_weekly_engagement("elder", 28)) == 4, "week 4, consecutive: +4 bonus")
	_check(int(gd.record_weekly_engagement("elder", 35)) == 5, "week 5, consecutive: +5 bonus (cap)")
	_check(int(gd.record_weekly_engagement("elder", 42)) == 5, "week 6, consecutive: bonus stays capped at +5")
	# Skip a week (day 63 = week 9, previous was week 6 at day 42) -> streak breaks.
	_check(int(gd.record_weekly_engagement("elder", 63)) == 0, "missed week: streak breaks, no bonus (not punished, just reset)")
	_check(int(gd.npc_weekly_streak.get("elder", 0)) == 1, "streak restarts at 1 after a missed week")

	# A different NPC's streak is independent.
	_check(int(gd.record_weekly_engagement("fah", 0)) == 0, "different npc: independent streak, starts fresh")

	# --- end-to-end: VillagerNPC.talk() grants the bonus silently ---
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var sb: Node = root.get_node("SignalBus")
	var tm: Node = sb.time_manager
	var elder: Node = main.get_node_or_null("ElderNPC")
	_check(elder != null, "ElderNPC present")
	if elder != null and tm != null:
		gd.affinity.erase("elder")
		gd.npc_weekly_streak.erase("elder")
		gd.npc_last_interaction_week.erase("elder")
		gd.inventory.clear() # isolate from gift-giving (any FOOD_ITEMS held auto-gifts on talk())
		tm.set_time(0, 6, 0)
		elder.talk()
		var affinity_week0: int = int(gd.get_affinity("elder"))
		gd.inventory.clear()
		tm.set_time(7, 6, 0)
		elder.talk()
		_check(int(gd.get_affinity("elder")) == affinity_week0 + 1,
			"VillagerNPC.talk() grants the +1 weekly bonus on the 2nd consecutive week")

	# --- end-to-end: RomanceNPC.try_interact() grants the bonus silently ---
	var fah: Node = main.get_node_or_null("FahNPC")
	_check(fah != null, "FahNPC present")
	if fah != null and tm != null:
		gd.affinity.erase("fah")
		gd.npc_weekly_streak.erase("fah")
		gd.npc_last_interaction_week.erase("fah")
		gd.inventory.clear()
		tm.set_time(0, 6, 0)
		fah.try_interact()
		var fah_week0: int = int(gd.get_affinity("fah"))
		gd.inventory.clear()
		tm.set_time(7, 6, 0)
		fah.try_interact()
		_check(int(gd.get_affinity("fah")) == fah_week0 + 1,
			"RomanceNPC.try_interact() grants the +1 weekly bonus on the 2nd consecutive week")
	main.queue_free()

	print("\n=== WEEKLY-ENGAGEMENT TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("WEEKLY-ENGAGEMENT GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
