extends SceneTree
# TASK-381 gate — the RelationshipStatus overlay (affinity hearts,
# loved/liked gifts, married flag, avatar) opens correctly for a romance
# candidate via SignalBus.show_relationship_status, and the real
# "view_relationship" input action on a RomanceNPC actually triggers it
# (same "logic correct, wiring missing" regression class this project
# keeps finding — see TASK-366/369/373/376/378/367).

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  relationship-status :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  relationship-status :: %s" % label)

func _initialize() -> void:
	await _run_all()
	print("\n=== RELATIONSHIP-STATUS TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("RELATIONSHIP-STATUS GATE FAILED")
	quit(1 if _failed > 0 else 0)

func _run_all() -> void:
	var sb: Node = root.get_node("SignalBus")
	var gd: Node = root.get_node("GameData")

	_check(sb.has_signal("show_relationship_status"),
		"SignalBus has show_relationship_status signal")

	# Clean slate.
	gd.affinity.clear()
	gd.spouse = ""

	var world: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	var status: Node = world.get_node_or_null("RelationshipStatus")
	_check(status != null, "World.tscn has a real RelationshipStatus node (not just the script)")
	if status == null:
		world.queue_free()
		print("\n=== RELATIONSHIP-STATUS TESTS: %d passed, %d failed ===" % [_passed, _failed])
		quit(1)
		return

	_check(status.visible == false, "RelationshipStatus starts hidden")

	# --- A. Direct signal emission, no affinity/marriage yet ---
	gd.affinity["fah"] = 25 # level_for(25) = 2
	sb.show_relationship_status.emit("fah", "Fah")
	await process_frame
	_check(status.visible == true, "show_relationship_status('fah', 'Fah') opens the overlay")

	var name_label: Label = status.get_node_or_null("Panel/VBox/NameLabel") as Label
	_check(name_label != null and name_label.text == "Fah",
		"NameLabel shows the passed display_name ('Fah')")

	var hearts_label: Label = status.get_node_or_null("Panel/VBox/HeartsLabel") as Label
	_check(hearts_label != null and hearts_label.text == "2 / 10 hearts",
		"HeartsLabel reflects GameData.level_for(affinity) (got '%s')" % (hearts_label.text if hearts_label else "<null>"))

	var loved_label: Label = status.get_node_or_null("Panel/VBox/LovedLabel") as Label
	_check(loved_label != null and loved_label.text.begins_with("Loves: "),
		"LovedLabel is populated from DialogueDB.GIFT_PREFERENCES")
	_check(loved_label != null and loved_label.text.find("lotus soup") != -1,
		"LovedLabel formats item ids with spaces, not underscores (got '%s')" % (loved_label.text if loved_label else "<null>"))

	var liked_label: Label = status.get_node_or_null("Panel/VBox/LikedLabel") as Label
	_check(liked_label != null and liked_label.text.find("fish sauce") != -1,
		"LikedLabel is populated from DialogueDB.GIFT_PREFERENCES (got '%s')" % (liked_label.text if liked_label else "<null>"))

	var married_label: Label = status.get_node_or_null("Panel/VBox/MarriedLabel") as Label
	_check(married_label != null and married_label.visible == false,
		"MarriedLabel hidden when GameData.spouse != this candidate")

	var avatar: TextureRect = status.get_node_or_null("Panel/VBox/Avatar") as TextureRect
	_check(avatar != null and avatar.visible == false,
		"Avatar hides cleanly when no avatar art exists yet for this candidate (fah_avatar.png not on disk)")

	# --- B. Married flag ---
	gd.spouse = "fah"
	sb.show_relationship_status.emit("fah", "Fah")
	await process_frame
	_check(married_label != null and married_label.visible == true,
		"MarriedLabel shows when GameData.spouse == this candidate")
	gd.spouse = ""

	# --- C. Close button ---
	status.call("close")
	await process_frame
	_check(status.visible == false, "close() hides the overlay")

	# --- D. Real input path: RomanceNPC's view_relationship action ---
	var fah_npc: Node = world.get_node_or_null("FahNPC")
	_check(fah_npc != null, "World.tscn has a real FahNPC node")
	if fah_npc != null:
		fah_npc.set("_player_in_range", true)
		var ev: InputEvent = InputEventAction.new()
		(ev as InputEventAction).action = "view_relationship"
		(ev as InputEventAction).pressed = true
		fah_npc.call("_unhandled_input", ev)
		await process_frame
		_check(status.visible == true,
			"pressing 'view_relationship' near FahNPC opens RelationshipStatus (real input path, not just the direct signal test above)")
		_check(name_label != null and name_label.text == "Fah",
			"real input path populates the correct candidate's name")

		# Out-of-range guard.
		status.call("close")
		fah_npc.set("_player_in_range", false)
		var ev2: InputEvent = InputEventAction.new()
		(ev2 as InputEventAction).action = "view_relationship"
		(ev2 as InputEventAction).pressed = true
		fah_npc.call("_unhandled_input", ev2)
		await process_frame
		_check(status.visible == false,
			"'view_relationship' does nothing when the player is out of range")

	world.queue_free()
	gd.affinity.clear()
	gd.spouse = ""
