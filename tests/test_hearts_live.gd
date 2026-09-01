extends SceneTree
# TASK-311 gate — daily-gated milk, affinity accrual, hearts HUD signal.

var _passed: int = 0
var _failed: int = 0
var _heart_events: Array = []

func _on_hearts(affinity: int, hearts: int) -> void:
	_heart_events.append([affinity, hearts])

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  hearts-live :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  hearts-live :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var sb: Node = root.get_node("SignalBus")
	sb.buffalo_affinity_changed.connect(_on_hearts)
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var buffalo: Node = main.get_node_or_null("Buffalo")
	var hud: Node = main.get_node_or_null("HUD")
	_check(buffalo != null and buffalo.has_method("interact"), "Buffalo.interact() present")
	if buffalo == null:
		await process_frame
		quit(1)
		return
	_check(buffalo.interact(), "day-1 milk + affinity")
	_check(int(gd.inventory.get("buffalo_milk", 0)) == 1, "milk granted once")
	_check(buffalo.interact() == false, "same-day re-interact blocked (daily gate)")
	_check(int(gd.inventory.get("buffalo_milk", 0)) == 1, "no duplicate milk")
	var tm: Node = sb.time_manager
	if tm != null:
		tm.set_time(2, 6, 0)
	_check(buffalo.interact(), "next-day interact allowed")
	_check(_heart_events.size() == 2, "buffalo_affinity_changed emitted per interact")
	_check(_heart_events[1][1] >= _heart_events[0][1], "hearts monotonic")
	var lbl: Label = hud.find_child("HeartsLabel", true, false) as Label if hud else null
	_check(lbl != null and lbl.text.contains("Buffalo"), "HUD hearts label live")
	sb.buffalo_affinity_changed.disconnect(_on_hearts)
	main.queue_free()
	print("\n=== HEARTS-LIVE TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("HEARTS-LIVE GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
