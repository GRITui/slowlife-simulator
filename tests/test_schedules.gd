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

	# TASK-328: rain override — elder/child route to their existing "home"
	# waypoint regardless of hour; NPCs with no RAIN_HOME entry are unaffected.
	_check(sdb.waypoint_for("elder", 7, "rain") == Vector2i(1, 5),
		"elder routes home at 07:00 when raining (normally temple lane)")
	_check(sdb.waypoint_for("elder", 20, "rain") == Vector2i(1, 5),
		"elder stays home at 20:00 when raining (normally by the shrine)")
	_check(sdb.waypoint_for("child", 7, "rain") == Vector2i(1, 6),
		"child routes home at 07:00 when raining (normally paddy edge play)")
	_check(sdb.waypoint_for("elder", 7, "clear") == Vector2i(1, 2),
		"elder keeps normal 07:00 waypoint when weather is clear")
	_check(sdb.waypoint_for("fah", 7, "rain") == Vector2i(10, 12),
		"fah (no RAIN_HOME entry) is unaffected by rain")

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

	# TASK-328: live weather-driven physics drift on an already-booted NPC.
	var gd: Node = root.get_node("GameData")
	if elder != null:
		gd.current_weather = "rain"
		elder.call("_physics_process", 0.016)
		var target: Vector2 = Vector2(1, 5) * 48.0 + Vector2(24, 24)
		_check(elder.get("_schedule_pos") == target, "elder's live target updates to home when weather flips to rain")
		gd.current_weather = "clear"
	main.queue_free()
	print("\n=== SCHEDULE TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("SCHEDULE GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
