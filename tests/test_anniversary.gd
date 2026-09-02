extends SceneTree
# TASK-282 romance ceiling gate — yearly anniversary payoff.

var _passed: int = 0
var _failed: int = 0
var _events: int = 0

func _on_festival(name: String) -> void:
	if name.begins_with("anniversary_"):
		_events += 1

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  anniversary :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  anniversary :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var sb: Node = root.get_node("SignalBus")
	sb.festival_triggered.connect(_on_festival)
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var ek: Node = main.get_node_or_null("EkNPC")
	var tm: Node = sb.time_manager
	if ek == null:
		await process_frame
		quit(1)
		return
	gd.inventory.clear()
	# Marriage state (wedding test path compressed).
	gd.married = true
	gd.spouse = "ek"
	var silver0: int = int(gd.silver)
	_check(ek.try_interact(), "anniversary year 1")
	_check(int(gd.silver) == silver0 + 30 and int(gd.harmony) >= 10, "+30 silver, +10 harmony")
	_check(_events == 1, "anniversary event fired once")
	# Same year: no repeat.
	ek.try_interact()
	_check(_events == 1 and int(gd.silver) == silver0 + 30, "same-year repeat blocked (cozy daily line)")
	# Year 2: new anniversary.
	tm.set_time(97, 12, 0)
	ek.try_interact()
	_check(_events == 2, "year-2 anniversary fires")
	_check(int(gd.silver) == silver0 + 60, "second +30 silver")
	sb.festival_triggered.disconnect(_on_festival)
	main.queue_free()
	print("\n=== ANNIVERSARY TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("ANNIVERSARY GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
