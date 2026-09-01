extends SceneTree
# TASK-319 fishing competition gate — hot day 15, skill gate, once per year.

var _passed: int = 0
var _failed: int = 0
var _hits: int = 0

func _on_festival(name: String) -> void:
	if name == "fishing_competition":
		_hits += 1

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  fishing-comp :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  fishing-comp :: %s" % label)

func _initialize() -> void:
	var sb: Node = root.get_node("SignalBus")
	sb.festival_triggered.connect(_on_festival)
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var comp: Node = main.get_node_or_null("FishingCompetitionTrigger")
	_check(comp != null, "FishingCompetitionTrigger instanced")
	if comp == null:
		await process_frame
		quit(1)
		return
	var tm: Node = sb.time_manager
	var gd: Node = root.get_node("GameData")
	# Need skill 2 to enter
	gd.fishing_skill = 1
	tm.set_season("hot")
	tm.set_time(15, 12, 0)
	_check(_hits == 0, "skill 1 does not trigger")
	# Skill 2 triggers
	gd.fishing_skill = 2
	# Need to advance day to trigger again (since we already triggered the check at 12:00, but skill was 1, so it showed dialogue but didn't trigger)
	# The trigger checks skill inside _on_minute_ticked, so we need to re-trigger by changing time
	tm.set_time(15, 13, 0)
	_check(_hits == 1, "skill 2 triggers at 13:00")
	# Duplicate same year blocked
	tm.set_time(15, 14, 0)
	_check(_hits == 1, "same year duplicate blocked")
	main.queue_free()
	print("\n=== FISHING-COMP TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("FISHING-COMP GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
