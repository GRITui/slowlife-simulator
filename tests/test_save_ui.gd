extends SceneTree
# ENGINE-013 save/load UI hookup gate.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  save-ui :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  save-ui :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var pause: CanvasLayer = main.get_node_or_null("PauseMenu") as CanvasLayer
	_check(pause != null, "PauseMenu present")
	if pause == null:
		await process_frame
		quit(1)
		return
	var save_btn: BaseButton = pause.find_child("Save", true, false) as BaseButton
	var load_btn: BaseButton = pause.find_child("Load", true, false) as BaseButton
	_check(save_btn != null and save_btn.custom_minimum_size.y >= 44.0, "Save button >= 44pt")
	_check(load_btn != null and load_btn.custom_minimum_size.y >= 44.0, "Load button >= 44pt")
	_check(save_btn != null and save_btn.pressed.get_connections().size() > 0, "Save wired")
	_check(load_btn != null and load_btn.pressed.get_connections().size() > 0, "Load wired")
	# End-to-end: handlers persist + restore state.
	gd.add_item("krathong", 2)
	gd.harmony = 17
	if main.has_method("_on_save_game"):
		main._on_save_game()
		var f: FileAccess = FileAccess.open("user://savegame.json", FileAccess.READ)
		_check(f != null, "savegame.json written via UI handler")
		gd.inventory.clear()
		gd.harmony = 0
		main._on_load_game()
		_check(int(gd.inventory.get("krathong", 0)) == 2 and int(gd.harmony) == 17,
			"load restores krathong=2 harmony=17")
	main.queue_free()
	print("\n=== SAVE-UI TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("SAVE-UI GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
