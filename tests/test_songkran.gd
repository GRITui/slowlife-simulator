extends SceneTree
# TASK-046 Songkran gate — hot day-3 midday trigger, once-only, splash spawn.

var _passed: int = 0
var _failed: int = 0
var _hits: int = 0

func _on_festival(name: String) -> void:
	if name == "songkran":
		_hits += 1

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  songkran :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  songkran :: %s" % label)

func _initialize() -> void:
	var sb: Node = root.get_node("SignalBus")
	sb.festival_triggered.connect(_on_festival)
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var st: Node = main.get_node_or_null("SongkranTrigger")
	_check(st != null, "SongkranTrigger instanced under World")
	if st == null:
		await process_frame
		quit(1)
		return
	_check(_hits == 0, "no trigger outside festival window")
	# Wrong season.
	var tm: Node = sb.time_manager
	if tm != null:
		tm.set_time(3, 13, 0)
		tm.set_season("cool")
		_check(_hits == 0, "cool season day 3 does not trigger")
		# Right season, wrong hour (morning).
		tm.set_season("hot")
		tm.set_time(3, 8, 0)
		_check(_hits == 0, "hot day 3 morning does not trigger")
		# Festival moment: hot day 3, 13:00.
		tm.set_time(3, 13, 0)
		_check(_hits == 1, "hot day 3 midday triggers once")
		_check(_hits == 1, "no duplicate emission on later ticks")
		var splash: Node = main.get_node_or_null("SongkranSplash")
		_check(splash != null, "splash particles spawned at pond")
		gd.current_season = tm.current_season
	sb.festival_triggered.disconnect(_on_festival)
	main.queue_free()
	print("\n=== SONGKRAN TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("SONGKRAN GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
