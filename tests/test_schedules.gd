extends SceneTree
# TASK-058 schedule gate — waypoint lookup + NPC placement.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  schedules :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  schedules :: %s" % label)

func _initialize() -> void:
	var sdb: GDScript = load("res://scripts/narrative/ScheduleDB.gd")
	_check(String(sdb.SCHEDULES.keys()[0]) != "", "schedules populated")
	var wp: Vector2i = sdb.waypoint_for("fah", 7)
	_check(wp == Vector2i(10, 12), "fah at canal waypoint at 07:00 (got %s)" % str(wp))
	var wp2: Vector2i = sdb.waypoint_for("fah", 13)
	_check(wp2 == Vector2i(2, 1), "fah at pond waypoint at 13:00 (got %s)" % str(wp2))
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var fah: Node2D = main.get_node_or_null("FahNPC") as Node2D
	var elder: Node = main.get_node_or_null("ElderNPC")
	_check(fah != null and fah.global_position.distance_to(Vector2(10 * 48 + 24, 12 * 48 + 24)) < 80.0,
		"fah placed at schedule waypoint (boot 06:00)")
	_check(elder != null and elder.is_physics_processing(), "scheduled NPC processes (drift active)")
	var buffalo: Node = main.get_node_or_null("Buffalo")
	_check(buffalo != null and not buffalo.is_processing(), "unscheduled nodes stay static")
	main.queue_free()
	print("\n=== SCHEDULE TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("SCHEDULE GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
