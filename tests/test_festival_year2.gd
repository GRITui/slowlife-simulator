extends SceneTree
# TASK-292 gate — festivals re-fire in year 2 (day-of-season, not absolute).

var _passed: int = 0
var _failed: int = 0
var _krathong_hits: int = 0

func _on_festival(name: String) -> void:
	if name == "loy_krathong":
		_krathong_hits += 1

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  festival-y2 :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  festival-y2 :: %s" % label)

func _initialize() -> void:
	var sb: Node = root.get_node("SignalBus")
	sb.festival_triggered.connect(_on_festival)
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var fm: Node = main.get_node_or_null("FestivalManager")
	var tm: Node = sb.time_manager
	if fm == null or tm == null:
		await process_frame
		quit(1)
		return
	# Year 1: cool season day-of-season 7 → absolute day 7.
	tm.set_season("cool")
	tm.set_time(7, 19, 0)
	_check(_krathong_hits == 1, "year-1 festival fires (absolute day 7)")
	# Year 2: cool season dos 7 -> absolute day 97 (year length 90 at
	# season_duration_days=30; the loop raised it from 10).
	tm.set_time(97, 19, 0)
	_check(_krathong_hits == 2, "year-2 festival RE-FIRES at absolute day 97 (was the bug)")
	_check(int(tm.day_of_season()) == 7 and int(tm.year()) == 2, "day 97 -> dos 7, year 2")
	sb.festival_triggered.disconnect(_on_festival)
	main.queue_free()
	print("\n=== FESTIVAL-Y2 TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("FESTIVAL-Y2 GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
