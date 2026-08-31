extends SceneTree
# Headless CI gate: godot --headless --path . --script res://tests/run_tests.gd
# Exit 0 = all green, exit 1 = failures. Covers: autoloads, GameData economy,
# CropData resource, Main scene boot (player spawn + camera), GridManager round-trip.

var _passed: int = 0
var _failed: int = 0
var _section: String = ""
var _sig_hits: int = 0

func _on_stamina_sig(_c: float, _m: float) -> void:
	_sig_hits += 1

func _initialize() -> void:
	_run_all()
	quit(1 if _failed > 0 else 0)

func _run_all() -> void:
	_section = "autoloads"
	var sb := root.get_node_or_null("SignalBus")
	var gd := root.get_node_or_null("GameData")
	_check(sb != null, "SignalBus autoload present")
	_check(gd != null, "GameData autoload present")
	if sb:
		for sig_name in ["minute_ticked", "season_changed", "stamina_changed",
				"show_dialogue", "binthabat_offered", "crop_growth_progress"]:
			_check(sb.has_signal(sig_name), "SignalBus has signal %s" % sig_name)

	_section = "gamedata"
	if gd:
		gd.current_stamina = 50.0
		_check(is_equal_approx(gd.current_stamina, 50.0), "stamina set")
		var sig_hits: int = 0
		if sb:
			sb.stamina_changed.connect(_on_stamina_sig)
		_sig_hits = 0
		gd.current_stamina = 40.0
		_check(_sig_hits == 1, "stamina_changed emitted on set")
		gd.current_stamina = 500.0
		_check(is_equal_approx(gd.current_stamina, gd.max_stamina), "stamina clamped to max")
		gd.add_item("rice_grain", 2)
		_check(gd.has_item("rice_grain", 2), "add_item/has_item")
		_check(gd.remove_item("rice_grain", 1), "remove_item")
		var harmony_before: int = gd.harmony
		gd.add_harmony(2)
		_check(gd.harmony == clamp(harmony_before + 2, 0, gd.max_harmony), "add_harmony")
		gd.add_item("rice_grain", 1)
		var y: int = gd.offer_bin_thabat("rice_grain", 1)
		_check(y == int(gd.binthabat_yields["rice_grain"]), "binthabat offering yields harmony")
		_check(gd.offer_bin_thabat("rice_grain", 1) == 0, "binthabat daily limit enforced")

	_section = "cropdata"
	var crop: Resource = load("res://data/crops/jasmine_rice.tres")
	_check(crop != null, "jasmine_rice.tres loads")
	if crop:
		_check(crop.total_stages == 4, "total_stages == 4")
		_check(crop.is_plantable_in("cool") and crop.is_plantable_in("hot"), "plantable seasons")
		_check(crop.get_yield("cool", "clear") >= 1, "get_yield >= 1")
		_check(crop.get_growth_minutes(0, "monsoon") == int(120.0 / 1.25), "monsoon growth speed")

	_section = "main-boot"
	var main_scene: PackedScene = load("res://scenes/core/Main.tscn")
	_check(main_scene != null, "Main.tscn loads")
	var main: Node = main_scene.instantiate() if main_scene else null
	if main:
		root.add_child(main)
		var player := main.get_node_or_null("Player")
		_check(player != null, "Player node present")
		if player:
			_check(player.global_position.distance_to(Vector2(320, 256)) < 0.1,
				"player spawns at map center (320,256)")
			var cam := player.get_node_or_null("Camera2D")
			_check(cam != null, "Player has Camera2D child")
			if cam:
				_check(cam.enabled, "camera enabled (4.7: 'current' property is gone)")
		_check(main.get_node_or_null("GridManager") != null, "GridManager present")
		_check(main.get_node_or_null("MonkNPC") != null, "MonkNPC present")
		_check(main.get_node_or_null("HUD") != null, "HUD present")

		_section = "gridmanager"
		var gm: Node = main.get_node_or_null("GridManager")
		if gm and crop:
			var cell := Vector2i(5, 5)
			_check(gm.is_plantable(cell), "free cell plantable")
			_check(gm.is_plantable(Vector2i(15, 11)) == false, "maze cell not plantable")
			_check(gm.is_plantable(Vector2i(20, 0)) == false, "out-of-bounds not plantable")
			var stamina_before: float = gd.current_stamina if gd else 100.0
			_check(gm.plant(cell, crop), "plant succeeds")
			if gd:
				_check(gd.current_stamina < stamina_before, "plant drains stamina")
			_check(gm.is_plantable(cell) == false, "occupied cell not plantable")
			var plot = gm.get_plot(cell)
			_check(plot != null, "plot exists after plant")
			if plot:
				_check(gm.water(cell), "water succeeds")
				_check(plot.watered, "plot flagged watered")
				plot.stage = crop.total_stages - 1
				var rice_before: int = gd.inventory.get("rice_grain", 0) if gd else 0
				var yield_n: int = gm.harvest(cell)
				_check(yield_n >= 1, "harvest yields >= 1")
				if gd:
					_check(gd.inventory.get("rice_grain", 0) >= rice_before + yield_n,
						"harvest adds item to inventory")
		main.queue_free()

	print("\n=== TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("CI GATE FAILED: %d failing checks in sections [%s]" % [_failed, _sections_failed])

var _sections_failed: String = ""

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
