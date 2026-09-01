extends SceneTree
# TASK-053 quest primitive gate — resource shape + state machine.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  quests :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  quests :: %s" % label)

func _initialize() -> void:
	var QuestDataRes: GDScript = load("res://scripts/resource_types/QuestData.gd")
	var q: Resource = QuestDataRes.new()
	q.id = "intro_fishing"
	q.display_name = "First Catch"
	var objs: Array[String] = ["get_rod", "catch_fish", "meet_fah"]
	q.objectives = objs
	q.reward_harmony = 10
	_check(String(q.id) == "intro_fishing", "QuestData fields set")
	_check((q.objectives as Array).size() == 3, "objectives array holds ids")
	var gd: Node = root.get_node("GameData")
	gd.start_quest("intro_fishing", 3)
	_check(gd.active_quests.has("intro_fishing"), "start_quest registers")
	gd.start_quest("intro_fishing", 3)
	_check(int((gd.active_quests["intro_fishing"] as Dictionary).get("stage")) == 0,
		"start_quest idempotent")
	gd.advance_quest("intro_fishing")
	_check(int((gd.active_quests["intro_fishing"] as Dictionary).get("stage")) == 1,
		"advance_quest +1 stage")
	_check(gd.is_quest_complete("intro_fishing") == false, "incomplete with 0/3 objectives")
	gd.complete_objective("intro_fishing", "get_rod")
	gd.complete_objective("intro_fishing", "catch_fish")
	_check(gd.is_quest_complete("intro_fishing") == false, "incomplete at 2/3")
	gd.complete_objective("intro_fishing", "meet_fah")
	_check(gd.is_quest_complete("intro_fishing"), "complete at 3/3")
	print("\n=== QUEST TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("QUEST GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
