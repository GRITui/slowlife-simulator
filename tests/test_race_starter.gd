extends SceneTree
# TASK-303 gate — race reachable in real play via the official's stand.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  race-starter :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  race-starter :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var starter: Node = main.get_node_or_null("RaceStarter")
	var course: Node = main.get_node_or_null("WingKwaiCourse")
	var race: Node = main.get_node_or_null("BuffaloRace")
	var player: Node2D = main.get_node_or_null("Player") as Node2D
	var buffalo: Node2D = main.get_node_or_null("Buffalo") as Node2D
	_check(starter != null, "RaceStarter instanced at the official's stand")
	_check(course != null, "flag course scaffold instanced")
	if starter == null or player == null or buffalo == null:
		await process_frame
		quit(1)
		return
	# Unmounted at the stand: hint path, race not started.
	player.global_position = starter.position + Vector2(40, 0)
	_check(starter.try_start() == false, "unmounted start -> official hints (race not started)")
	_check(race.race_active == false, "race inactive before mount")
	# Mount nearby buffalo, then start via the stand (real play path).
	player.global_position = buffalo.global_position + Vector2(40, 0)
	player.toggle_mount()
	player.global_position = starter.position + Vector2(40, 0)
	_check(starter.try_start(), "mounted start via official -> race begins")
	_check(race.race_active, "race_active after official start")
	_check(race.next_checkpoint == 0, "checkpoint sequence armed")
	main.queue_free()
	print("\n=== RACE-STARTER TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("RACE-STARTER GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
