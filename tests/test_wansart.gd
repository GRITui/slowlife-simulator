extends SceneTree
# TASK-055 Wan Sart gate — cool day-5 morning, once-only, offering release.

var _passed: int = 0
var _failed: int = 0
var _hits: int = 0

func _on_festival(name: String) -> void:
	if name == "wan_sart":
		_hits += 1

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  wansart :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  wansart :: %s" % label)

func _initialize() -> void:
	var sb: Node = root.get_node("SignalBus")
	sb.festival_triggered.connect(_on_festival)
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var ws: Node = main.get_node_or_null("WanSartTrigger")
	_check(ws != null, "WanSartTrigger instanced")
	if ws == null:
		await process_frame
		quit(1)
		return
	var tm: Node = sb.time_manager
	if tm != null:
		tm.set_season("cool")
		tm.set_time(5, 7, 0)
		_check(_hits == 1, "cool day-5 morning triggers once")
		tm.set_time(5, 14, 0)
		_check(_hits == 1, "afternoon does not re-trigger (window closed)")
	# Offering flow. AI-ENG-001 run 2 (2026-09-01): festival now checks for
	# kra_yasat (the real Wan Sart merit-offering dish), not the generic
	# wan_sart_basket placeholder — see WanSartTrigger.gd.
	gd.inventory.erase("kra_yasat")
	ws.release_offering()
	_check(int(gd.inventory.get("kra_yasat", 0)) == 0 and not gd.has_item("kra_yasat", 1),
		"no kra yasat -> soft nudge")
	gd.add_item("sticky_rice", 2)
	gd.add_item("peanut", 1)
	gd.add_item("sesame", 1)
	gd.add_item("palm_sugar", 1)
	gd.current_season = "cool"
	var station: Node = main.get_node_or_null("CookingStation")
	# Kra yasat is craftable at the station in cool season via recipes.json.
	var all: Array = station.get_all_craftable() if station != null else []
	var ids: Array = []
	for r: Dictionary in all:
		ids.append(String(r.get("id", "")))
	_check(ids.has("kra_yasat"),
		"kra_yasat among craftable (%s)" % str(ids))
	if station != null and ids.has("kra_yasat"):
		station.try_craft()
	gd.add_item("kra_yasat", 1)
	gd.harmony = 0
	ws.release_offering()
	_check(int(gd.harmony) == 8, "release grants +8 harmony")
	sb.festival_triggered.disconnect(_on_festival)
	main.queue_free()
	print("\n=== WANSART TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("WANSART GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
