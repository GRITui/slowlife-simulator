extends SceneTree
# TASK-280 year-scaling gate — veteran bonus + rollover sync.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  year-scaling :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  year-scaling :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var gm: Node = main.get_node_or_null("GridManager")
	var tm: Node = root.get_node("SignalBus").time_manager
	var crop: Resource = load("res://data/crops/jasmine_rice.tres")
	_check(int(gd.veteran_yield_bonus()) == 0, "year 1: no bonus")
	# Year 2: rollover sync + bonus.
	tm.set_time(97, 12, 0) # year 2 (season duration 30)
	gd.veteran_year = int(tm.year())
	_check(int(gd.veteran_yield_bonus()) == 1, "year 2: +1 veteran bonus")
	gm.plant(Vector2i(5, 5), crop)
	var ps: Variant = gm.plots[Vector2i(5, 5)]
	ps.stage = crop.total_stages - 1
	var y: int = gm.harvest(Vector2i(5, 5))
	_check(y >= crop.get_yield("cool", "clear") + 1, "harvest carries veteran +1 (got %d)" % y)
	# Cap at year 4+.
	gd.veteran_year = 9
	_check(int(gd.veteran_yield_bonus()) == 3, "bonus capped at 3")
	main.queue_free()
	print("\n=== YEAR-SCALING TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("YEAR-SCALING GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
