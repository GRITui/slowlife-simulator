extends SceneTree
# Phase 3 audit (2026-09-02) gate — extending gift-giving to VillagerNPC
# surfaced a pre-existing bug shared by RomanceNPC.gd: quest talk-tracking
# (_try_offer_quest/_try_complete_talk_objective) only ran inside each
# NPC's dialogue-fallback branch, so any earlier early-return — the gift
# branch especially, which fires on ANY interact while holding food, an
# extremely common state in a farming sim — silently skipped
# talk_to_<npc_id> quest objectives for that click. Both NPC scripts now
# run quest talk-tracking unconditionally before any branch. Verifies a
# talk_to_X objective still completes even while the player is holding a
# giftable food item.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  talk-not-skipped :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  talk-not-skipped :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	# --- VillagerNPC path: elder, quest "morning_merit" needs talk_to_elder ---
	var elder: Node = main.get_node_or_null("ElderNPC")
	_check(elder != null, "ElderNPC present")
	if elder != null:
		gd.start_quest("morning_merit", 1)
		gd.inventory.clear()
		gd.add_item("lotus_root", 1) # elder's loved gift — would trigger _give_gift()
		elder.talk()
		_check(int(gd.inventory.get("lotus_root", 0)) == 0, "gift still consumed on this interact")
		_check(gd.is_quest_complete("morning_merit"),
			"talk_to_elder objective still completes even while gifting on the same interact")

	# --- RomanceNPC path: fah, quest "first_catch" needs talk_to_fah ---
	var fah: Node = main.get_node_or_null("FahNPC")
	_check(fah != null, "FahNPC present")
	if fah != null:
		gd.start_quest("first_catch", 2)
		gd.inventory.clear()
		gd.add_item("lotus_root", 1) # fah's loved gift
		fah.try_interact()
		_check(int(gd.inventory.get("lotus_root", 0)) == 0, "gift still consumed on this interact (romance NPC)")
		var chain: Array = ["talk_to_fah"]
		var done: Array = (gd.active_quests["first_catch"] as Dictionary).get("objectives_done", []) as Array
		_check(done.has("talk_to_fah"),
			"talk_to_fah objective still completes even while gifting on the same interact")

	main.queue_free()
	print("\n=== TALK-NOT-SKIPPED TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("TALK-NOT-SKIPPED GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
