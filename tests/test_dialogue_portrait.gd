extends SceneTree
# TASK-376 gate — the dialogue Portrait TextureRect actually exists in
# World.tscn and actually shows/hides on SignalBus.show_dialogue. Written
# because a real bug existed here: World.gd's dialogue_portrait was
# guarded with `if has_node(...) else null`, and no "Portrait" node ever
# existed under DialogueLayer/Panel — so PORTRAIT_PATHS and every portrait
# PNG had never actually rendered in a real session, despite the display
# logic in World.gd's _on_show_dialogue() being fully correct. This test
# instances the real World.tscn (not just the script) specifically so a
# future regression of the same shape (logic correct, node missing)
# fails loudly here — same pattern as test_particle_drivers.gd (TASK-366).

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  dialogue-portrait :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  dialogue-portrait :: %s" % label)

func _initialize() -> void:
	var sb: Node = root.get_node("SignalBus")
	var world: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	# --- A. Scene-tree wiring ---
	var portrait: TextureRect = world.get_node_or_null("DialogueLayer/Panel/Portrait") as TextureRect
	_check(portrait != null, "World.tscn has a real DialogueLayer/Panel/Portrait node (not just the script)")
	if portrait == null:
		world.queue_free()
		print("\n=== DIALOGUE-PORTRAIT TESTS: %d passed, %d failed ===" % [_passed, _failed])
		quit(1)
		return

	_check(portrait.visible == false, "Portrait starts hidden (no dialogue shown yet)")

	# --- B. A speaker WITH a portrait ---
	sb.show_dialogue.emit("Elder", "Welcome, traveler.")
	await process_frame
	_check(portrait.visible == true, "show_dialogue('Elder', ...) makes Portrait visible")
	_check(portrait.texture != null, "Portrait.texture is set for a PORTRAIT_PATHS speaker")

	# --- C. A speaker WITHOUT a portrait (e.g. the screenshot-hook's 'Camera') ---
	sb.show_dialogue.emit("Camera", "Screenshot saved.")
	await process_frame
	_check(portrait.visible == false, "show_dialogue('Camera', ...) hides Portrait (no portrait for that speaker)")

	# --- D. Re-arm: a second PORTRAIT_PATHS speaker after a no-portrait one ---
	sb.show_dialogue.emit("Monk", "Peace be with you.")
	await process_frame
	_check(portrait.visible == true, "show_dialogue('Monk', ...) re-shows Portrait after a no-portrait speaker")

	# --- E. Layout hygiene: Portrait must not overlap DialogueLabel's text region ---
	var label: Label = world.get_node_or_null("DialogueLayer/Panel/DialogueLabel") as Label
	_check(label != null, "DialogueLabel still present alongside Portrait")
	if label != null:
		_check(label.offset_left >= portrait.offset_right,
			"DialogueLabel starts at/after Portrait's right edge (no overlap)")

	world.queue_free()
	print("\n=== DIALOGUE-PORTRAIT TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("DIALOGUE-PORTRAIT GATE FAILED")
	quit(1 if _failed > 0 else 0)
