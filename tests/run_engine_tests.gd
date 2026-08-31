extends SceneTree
# Engine CI gate (Backend Orchestrator / @backend-automation):
#   godot --headless --path . --script res://tests/run_engine_tests.gd
# Exit 0 = all green, exit 1 = failures. Scope: engine-layer only —
# autoload wiring, SignalBus contract, TimeManager state machine,
# GridManager spatial bounds contract.
#
# Squad extension points (add a _section here when the task lands):
#   @spatial-physics   -> A* pathfinding correctness (none yet)
#   @data-persistence  -> save/load round-trip (none yet)
#   @profiler-inspector -> camera/render invariants (none yet)
# Do not add art/content assertions here (sprite frames, palette, dialogue) —
# that belongs to the separate content-squad's res://tests/run_tests.gd.

var _passed: int = 0
var _failed: int = 0
var _section: String = ""
var _sections_failed: String = ""

var _minute_hits: int = 0
var _season_hits: int = 0
var _last_season: String = ""

func _on_minute_ticked(_d: int, _h: int, _m: int) -> void:
	_minute_hits += 1

func _on_season_changed(s: String) -> void:
	_season_hits += 1
	_last_season = s

func _initialize() -> void:
	await _run_all()
	print("\n=== ENGINE TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("ENGINE CI GATE FAILED: %d failing checks in sections [%s]" % [_failed, _sections_failed])
	quit(1 if _failed > 0 else 0)

func _run_all() -> void:
	_section = "autoloads"
	var sb := root.get_node_or_null("SignalBus")
	var gd := root.get_node_or_null("GameData")
	_check(sb != null, "SignalBus autoload present")
	_check(gd != null, "GameData autoload present")
	if sb:
		for sig_name in ["minute_ticked", "season_changed", "weather_changed",
				"day_night_cycle_changed", "stamina_changed",
				"show_dialogue", "binthabat_offered", "crop_growth_progress"]:
			_check(sb.has_signal(sig_name), "SignalBus has signal %s" % sig_name)

	_section = "timemanager-boot"
	var tm_scene: PackedScene = load("res://scenes/core/TimeManager.tscn")
	_check(tm_scene != null, "TimeManager.tscn loads")
	var tm: Node = tm_scene.instantiate() if tm_scene else null
	if tm and sb:
		tm.auto_tick = false
		sb.minute_ticked.connect(_on_minute_ticked)
		sb.season_changed.connect(_on_season_changed)
		root.add_child(tm)
		await process_frame
		_check(tm.day == tm.start_day and tm.hour == tm.start_hour, "TimeManager boots at configured start time")
		_check(_minute_hits >= 1, "minute_ticked emitted on ready (initial sync)")

		_section = "timemanager-statemachine"
		tm.set_time(3, 23, 59)
		_check(tm.day == 3 and tm.hour == 23 and tm.minute == 59, "set_time applies exact values")
		tm.set_time(1, -5, 90)
		_check(tm.hour == 0 and tm.minute == 59, "set_time clamps out-of-range hour/minute")

		var before_season: String = tm.current_season
		tm.set_season("hot")
		_check(tm.current_season == "hot", "set_season transitions state")
		_check(is_equal_approx(tm.get_stamina_multiplier(), 1.3), "hot season stamina multiplier 1.3x")
		tm.set_season("monsoon")
		_check(is_equal_approx(tm.get_stamina_multiplier(), 0.8), "monsoon season stamina multiplier 0.8x")
		tm.set_season("not-a-real-season")
		_check(tm.current_season == "monsoon", "set_season rejects unknown season (no-op)")
		tm.set_season(before_season)

		tm.set_time(1, 6, 0)
		_check(tm.is_morning_bin_thabat_window(), "06:00 is within binthabat window")
		tm.set_time(1, 12, 0)
		_check(not tm.is_morning_bin_thabat_window(), "12:00 is outside binthabat window")

		_check(is_equal_approx(tm.get_day_fraction(), 0.5), "get_day_fraction at noon == 0.5")
		tm.queue_free()

	_section = "gridmanager-bounds"
	var main_scene: PackedScene = load("res://scenes/core/Main.tscn")
	var main: Node = main_scene.instantiate() if main_scene else null
	if main:
		root.add_child(main)
		var gm: Node = main.get_node_or_null("GridManager")
		_check(gm != null, "GridManager present in Main")
		if gm:
			_check(gm.grid_size == Vector2i(20, 16), "grid_size is locked 20x16")
			_check(gm.is_plantable(Vector2i(0, 0)), "origin cell in bounds")
			_check(gm.is_plantable(Vector2i(19, 15)), "far corner in bounds")
			_check(gm.is_plantable(Vector2i(-1, 0)) == false, "negative x rejected")
			_check(gm.is_plantable(Vector2i(0, -1)) == false, "negative y rejected")
			_check(gm.is_plantable(Vector2i(20, 15)) == false, "x == grid_size.x rejected (exclusive bound)")
			_check(gm.is_plantable(Vector2i(19, 16)) == false, "y == grid_size.y rejected (exclusive bound)")
			for x in range(gm.maze_origin.x, gm.maze_origin.x + 3):
				for y in range(gm.maze_origin.y, gm.maze_origin.y + 3):
					_check(gm.is_maze_cell(Vector2i(x, y)), "maze cell (%d,%d) flagged" % [x, y])
			_check(gm.is_maze_cell(gm.maze_origin - Vector2i(1, 0)) == false, "cell just outside maze not flagged")
		main.queue_free()

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  %s :: %s" % [_section, label])
	else:
		_failed += 1
		print("  FAIL  %s :: %s" % [_section, label])
		if not _sections_failed.contains(_section):
			if _sections_failed != "":
				_sections_failed += ", "
			_sections_failed += _section
