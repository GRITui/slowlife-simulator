extends SceneTree
# TASK-040 festival wiring gate — manager live under World, minute_ticked
# hook fires festival exactly once per cool-season day 7.

var _passed: int = 0
var _failed: int = 0
var _hits: int = 0

func _on_festival(_name: String) -> void:
	_hits += 1

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  festival-wiring :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  festival-wiring :: %s" % label)

func _initialize() -> void:
	var sb: Node = root.get_node("SignalBus")
	sb.festival_triggered.connect(_on_festival)
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var fm: Node = main.get_node_or_null("FestivalManager")
	_check(fm != null, "FestivalManager instanced under World")
	_check(fm != null and fm.is_in_group("festival_manager"), "manager tagged")
	_check(sb.minute_ticked.get_connections().size() > 0, "minute_ticked has live connections")
	_check(_hits == 0, "no festival before day 7 cool")
	if fm != null:
		# Not the festival day.
		fm.try_trigger_festival(6, "cool")
		_check(_hits == 0, "day 6 cool does not trigger")
		# Wrong season.
		fm.try_trigger_festival(7, "hot")
		_check(_hits == 0, "day 7 hot does not trigger")
		# Trigger + once-only guard.
		_check(fm.try_trigger_festival(7, "cool"), "day 7 cool triggers")
		_check(_hits == 1, "festival_triggered emitted once")
		_check(fm.try_trigger_festival(7, "cool") == false, "second trigger same season blocked")
		_check(_hits == 1, "no duplicate emission")
	sb.festival_triggered.disconnect(_on_festival)
	main.queue_free()
	print("\n=== FESTIVAL-WIRING TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("FESTIVAL WIRING GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
