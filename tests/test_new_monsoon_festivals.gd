extends SceneTree
# TASK-330 monsoon festival density gate — Asalha Bucha (monsoon day 5,
# 17:00-21:00) and Ok Phansa (monsoon day 28, 18:00-22:00). Both triggers
# boot under Main, fire festival_triggered with the correct id exactly once
# inside their window (year-season dedupe), and stay silent outside the
# season/day/hour window.

var _passed: int = 0
var _failed: int = 0
var _asalha_hits: int = 0
var _ok_hits: int = 0

func _on_festival(name: String) -> void:
	if name == "asalha_bucha":
		_asalha_hits += 1
	elif name == "ok_phansa":
		_ok_hits += 1

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  monsoon-festivals :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  monsoon-festivals :: %s" % label)

func _initialize() -> void:
	var sb: Node = root.get_node("SignalBus")
	sb.festival_triggered.connect(_on_festival)
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var asalha: Node = main.get_node_or_null("AsalhaBuchaTrigger")
	_check(asalha != null, "AsalhaBuchaTrigger instanced under Main")
	var ok_phansa: Node = main.get_node_or_null("OkPhansaTrigger")
	_check(ok_phansa != null, "OkPhansaTrigger instanced under Main")
	_check(_asalha_hits == 0 and _ok_hits == 0, "no trigger outside festival window")
	var tm: Node = sb.time_manager
	if tm != null:
		# Wrong season for both (festival day, in-window hour).
		tm.set_season("cool")
		tm.set_time(5, 17, 0)
		_check(_asalha_hits == 0, "cool day 5 evening does not trigger Asalha Bucha")
		tm.set_time(28, 18, 0)
		_check(_ok_hits == 0, "cool day 28 night does not trigger Ok Phansa")
		# Right season, wrong day.
		tm.set_season("monsoon")
		tm.set_time(4, 17, 0)
		_check(_asalha_hits == 0, "monsoon day 4 does not trigger Asalha Bucha")
		tm.set_time(27, 18, 0)
		_check(_ok_hits == 0, "monsoon day 27 does not trigger Ok Phansa")
		# Right day, hour before each window.
		tm.set_time(5, 16, 0)
		_check(_asalha_hits == 0, "monsoon day 5 afternoon does not trigger Asalha Bucha")
		tm.set_time(28, 17, 0)
		_check(_ok_hits == 0, "monsoon day 28 early evening does not trigger Ok Phansa")
		# Festival moment: monsoon day 5, 17:00 — fires once.
		tm.set_time(5, 17, 0)
		_check(_asalha_hits == 1, "monsoon day 5 evening triggers Asalha Bucha once")
		tm.set_time(5, 17, 30)
		_check(_asalha_hits == 1, "no duplicate Asalha Bucha emission on later ticks")
		# Festival moment: monsoon day 28, 18:00 — fires once.
		tm.set_time(28, 18, 0)
		_check(_ok_hits == 1, "monsoon day 28 night triggers Ok Phansa once")
		tm.set_time(28, 18, 30)
		_check(_ok_hits == 1, "no duplicate Ok Phansa emission on later ticks")
		gd.current_season = tm.current_season
	sb.festival_triggered.disconnect(_on_festival)
	main.queue_free()
	print("\n=== MONSOON FESTIVAL TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("MONSOON FESTIVAL GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
