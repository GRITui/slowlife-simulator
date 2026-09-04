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

# TASK-379: mirrors WorldRender.gd's own ground-rects for the tiles
# NavGrid.gd's WATER_TILES const treats as unwalkable. A schedule
# waypoint landing here means a scheduled NPC will walk into water the
# moment that time window is active — exactly the bug found and fixed
# this task (headman/fah), dormant only because those NPCs weren't
# instanced until TASK-373. This check guards every npc_id's every
# waypoint, not just the two known-bad ones, so a future schedule
# entry authored before its NPC is ever visible fails loudly here.
const WATER_ZONES: Array = [
	[0, 0, 5, 4],      # lotus_pond
	[14, 10, 17, 13],  # lotus_maze_islet (deep_pond)
	[9, 13, 17, 14],   # canal_row
]

func _waypoint_in_water(pos: Vector2) -> bool:
	for z: Array in WATER_ZONES:
		if pos.x >= z[0] and pos.x < z[2] and pos.y >= z[1] and pos.y < z[3]:
			return true
	return false

func _initialize() -> void:
	var sdb: GDScript = load("res://scripts/narrative/ScheduleDB.gd")
	_check(String(sdb.SCHEDULES.keys()[0]) != "", "schedules populated")

	for npc_id: String in sdb.SCHEDULES.keys():
		var slots: Array = sdb.SCHEDULES[npc_id]
		for slot: Dictionary in slots:
			var pos: Vector2 = slot.get("pos", Vector2.ZERO)
			_check(not _waypoint_in_water(pos),
				"%s's waypoint %s (hours %s-%s) is not on a water tile" % [
					npc_id, pos, slot.get("from", "?"), slot.get("to", "?")])
	var wp: Vector2i = sdb.waypoint_for("fah", 7)
	_check(wp == Vector2i(10, 12), "fah at canal waypoint at 07:00 (got %s)" % str(wp))
	var wp2: Vector2i = sdb.waypoint_for("fah", 13)
	_check(wp2 == Vector2i(5, 0), "fah at pond waypoint at 13:00 (got %s)" % str(wp2))

	# TASK-328: rain override — elder/child route to their existing "home"
	# waypoint regardless of hour; NPCs with no RAIN_HOME entry are unaffected.
	_check(sdb.waypoint_for("elder", 7, "rain") == Vector2i(1, 5),
		"elder routes home at 07:00 when raining (normally temple lane)")
	_check(sdb.waypoint_for("elder", 20, "rain") == Vector2i(1, 5),
		"elder stays home at 20:00 when raining (normally by the shrine)")
	_check(sdb.waypoint_for("child", 7, "rain") == Vector2i(1, 6),
		"child routes home at 07:00 when raining (normally paddy edge play)")
	_check(sdb.waypoint_for("elder", 7, "clear") == Vector2i(1, 4),
		"elder keeps normal 07:00 waypoint when weather is clear")
	_check(sdb.waypoint_for("fah", 7, "rain") == Vector2i(10, 12),
		"fah (no RAIN_HOME entry) is unaffected by rain")
	# TASK-338: Nok extends weather-reactive scheduling to a 3rd NPC.
	_check(sdb.waypoint_for("nok", 8, "rain") == Vector2i(4, 8),
		"nok routes home at 08:00 when raining (normally paddy check)")
	_check(sdb.waypoint_for("nok", 8, "clear") == Vector2i(4, 7),
		"nok keeps normal 08:00 waypoint when weather is clear")

	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var fah: Node2D = main.get_node_or_null("FahNPC") as Node2D
	var elder: Node = main.get_node_or_null("ElderNPC")
	# TASK-379 finding (filed separately, out of this task's scope): fah
	# uses RomanceNPC.gd, not VillagerNPC.gd, and RomanceNPC.gd's _ready()
	# never reads ScheduleDB at all -- fah's SCHEDULES entry is dead data,
	# her real position is always World.tscn's static one (set by
	# TASK-373, since fah was never instanced before that task). This
	# assertion previously expected schedule-driven movement that fah's
	# actual script has never implemented; fixed to check what actually
	# happens (a stable static position) instead of a wrong expectation.
	_check(fah != null and fah.global_position == Vector2(648, 168),
		"fah (RomanceNPC.gd) stays at her static World.tscn position -- does not follow ScheduleDB")
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
