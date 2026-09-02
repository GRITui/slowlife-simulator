extends SceneTree
# Phase 3 audit (2026-09-02) gate — QuestLog.gd never removed a completed
# quest from GameData.active_quests, so any later unrelated event that
# shares an already-satisfied objective_id re-ran _payout every time it
# fired (unbounded silver/harmony/item duplication). Verifies a completed
# quest's reward pays out exactly once no matter how many more times its
# objective event fires afterward.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  quest-no-dupe :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  quest-no-dupe :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var ql: Node = main.get_node_or_null("QuestLog")
	_check(ql != null, "QuestLog present")
	if ql == null:
		main.queue_free()
		await process_frame
		quit(1)
		return

	# Find any quest chain that includes the "catch_a_fish" event objective
	# (fired by QuestLog._check_objective_by_item on every pla_* catch).
	var chain_id: String = ""
	for qid: String in ql._chains.keys():
		var chain: Dictionary = ql._chains[qid] as Dictionary
		if (chain.get("objectives", []) as Array).has("catch_a_fish"):
			chain_id = qid
			break
	_check(chain_id != "", "a quest chain using catch_a_fish exists")
	if chain_id == "":
		main.queue_free()
		await process_frame
		quit(1)
		return

	var chain: Dictionary = ql.get_chain(chain_id)
	var objectives: Array = chain.get("objectives", []) as Array
	gd.start_quest(chain_id, objectives.size())
	# Satisfy every other objective directly so catch_a_fish is the one
	# event that completes (and pays out) the quest.
	for o: String in objectives:
		if o != "catch_a_fish":
			gd.complete_objective(chain_id, o)

	var harmony_start: int = gd.harmony
	ql._check_objective_by_item("pla_nin_small")
	_check(gd.is_quest_complete(chain_id), "quest completes on first catch_a_fish trigger")
	var harmony_after_payout: int = gd.harmony
	_check(harmony_after_payout > harmony_start, "payout granted harmony once")

	# Fire the same event two more times — a normal player action (catching
	# more fish) that has nothing to do with the already-paid quest.
	ql._check_objective_by_item("pla_nin_small")
	ql._check_objective_by_item("pla_nin_small")
	_check(gd.harmony == harmony_after_payout,
		"repeated catch_a_fish triggers do not re-pay the completed quest")

	# The manual entry point (complete_objective) must be guarded the same way.
	var harmony_before_manual: int = gd.harmony
	ql.complete_objective(chain_id, "catch_a_fish")
	_check(gd.harmony == harmony_before_manual,
		"manual complete_objective() on an already-complete quest is a no-op")

	main.queue_free()
	print("\n=== QUEST-NO-DUPE TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("QUEST-NO-DUPE GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
