extends SceneTree
# TASK-270 race gate — mount requirement, checkpoint order, timeout, payout.

var _passed: int = 0
var _failed: int = 0
var _finished: Array = []

func _on_finished(won: bool, seconds: float) -> void:
	_finished.append([won, seconds])

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  race :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  race :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var race: Node = main.get_node_or_null("BuffaloRace")
	var player: Node2D = main.get_node_or_null("Player") as Node2D
	_check(race != null, "BuffaloRace instanced")
	if race == null or player == null:
		await process_frame
		quit(1)
		return
	race.race_finished.connect(_on_finished)
	var buffalo: Node2D = main.get_node_or_null("Buffalo") as Node2D
	# Unmounted start blocked.
	gd.inventory.erase("seed_rice")
	_check(race.start_race(player) == false, "unmounted start blocked")
	# Mount then start (mount at the buffalo — 96px range check).
	player.global_position = buffalo.global_position + Vector2(40, 0)
	player.toggle_mount()
	_check(race.start_race(player), "race starts mounted")
	_check(bool(player.mounted), "still mounted during race")
	# Hit checkpoints in order.
	var cps: Array = race.CHECKPOINTS
	for i in cps.size():
		player.global_position = cps[i]
		await process_frame
		_check(race.next_checkpoint == i + 1, "checkpoint %d passed" % [i + 1])
	_check(_finished.size() == 1 and _finished[0][0] == true, "race finished won")
	_check(int(gd.harmony) >= 15, "champion payout +15 harmony")
	_check(int(gd.inventory.get("sticky_rice", 0)) >= 3, "sticky rice payout")
	# Timeout path: restart, force the timer over.
	player.toggle_mount() # dismount at cp4
	buffalo.global_position = player.global_position + Vector2(40, 0)
	player.toggle_mount() # re-mount beside the buffalo
	_check(race.start_race(player), "race restarts for timeout path")
	race.race_time = 91.0
	race._process(0.016)
	_check(_finished.size() == 2 and _finished[1][0] == false, "timeout finishes lost")
	main.queue_free()
	print("\n=== RACE TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("RACE GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
