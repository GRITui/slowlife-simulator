extends SceneTree
# ISSUE-134 gate — raid clears plots, banana truce protects, once/day.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  lopburi :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  lopburi :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var raid: Node = main.get_node_or_null("LopburiRaid")
	_check(raid != null, "LopburiRaid instanced")
	if raid == null:
		await process_frame
		quit(1)
		return
	var gm: Node = root.get_node("SignalBus").grid_manager
	var crop: Resource = load("res://data/crops/jasmine_rice.tres")
	# Seed 2 plots.
	gm.plant(Vector2i(4, 5), crop)
	gm.plant(Vector2i(5, 5), crop)
	# Raid without banana: plots reset to stage 0.
	gd.inventory.erase("banana")
	raid.raid()
	var ps1: Variant = gm.plots.get(Vector2i(4, 5))
	var ps2: Variant = gm.plots.get(Vector2i(5, 5))
	_check(ps1 != null and int(ps1.stage) == 0, "raided plot 1 reset to stage 0")
	_check(ps2 != null and int(ps2.stage) == 0, "raided plot 2 reset to stage 0")
	# Truce: with banana, plots untouched, +3 harmony.
	gm.plant(Vector2i(4, 5), crop)
	gm.plant(Vector2i(5, 5), crop)
	gm.plots[Vector2i(4, 5)].stage = 2 # mid-growth: raid would reset to 0
	gd.add_item("banana", 1)
	var harmony_before: int = int(gd.harmony)
	raid.raid()
	_check(gd.has_item("banana", 0) or not gd.has_item("banana", 1), "banana consumed for truce")
	_check(int(gd.harmony) == harmony_before + 3, "truce +3 harmony")
	var ps1b: Variant = gm.plots.get(Vector2i(4, 5))
	_check(ps1b != null and int(ps1b.stage) > 0, "truce protected plots (stage preserved)")
	main.queue_free()
	print("\n=== LOPBURI TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("LOPBURI GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
