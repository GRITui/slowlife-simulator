extends SceneTree
# TASK-332 noticeboard gate — proximity instancing, real InteractArea (the
# @onready null-bug shipped twice before), insufficient-item soft-fail (no
# economy mutation, hint dialogue), successful fulfill (item removed,
# silver/harmony granted exactly once, board rotates to a different notice),
# and proximity enter/exit mirroring tests/test_fishing.gd.

var _passed: int = 0
var _failed: int = 0
var _dialogue: Array = []
var _silver_hits: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  noticeboard :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  noticeboard :: %s" % label)

func _on_dialogue(speaker: String, text: String) -> void:
	_dialogue.append({"speaker": speaker, "text": text})

func _on_silver(_silver: int) -> void:
	_silver_hits += 1

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var sb: Node = root.get_node("SignalBus")
	sb.show_dialogue.connect(_on_dialogue)
	sb.silver_changed.connect(_on_silver)
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	# 1) Dynamically instanced, not authored in World.tscn.
	var board: Node = main.get_node_or_null("Noticeboard")
	_check(board != null, "Noticeboard instanced as runtime child of World")
	var tscn_text: String = FileAccess.get_file_as_string("res://scenes/core/World.tscn")
	_check(not tscn_text.contains("[node name=\"Noticeboard\""),
		"Noticeboard is NOT hard-authored in World.tscn (dynamic only)")
	if board == null:
		await process_frame
		quit(1)
		return
	# 2) Real InteractArea — this project has twice shipped the @onready
	# $InteractArea null-bug; it must not repeat here.
	_check(board.get("_area") != null, "Noticeboard._area is a real Area2D (not null)")
	var area: Node = board.get("_area")
	if area != null:
		_check(area.get_class() == "Area2D", "InteractArea is an Area2D node")
		var has_circle: bool = false
		for child: Node in area.get_children():
			if child is CollisionShape2D and child.shape is CircleShape2D:
				var cs: CircleShape2D = child.shape
				if is_equal_approx(cs.radius, 56.0):
					has_circle = true
					break
		_check(has_circle, "InteractArea has CollisionShape2D with CircleShape2D radius 56")
	# 3) Boot state: roster loaded, initial notice active.
	var roster: Array = board.get("_roster")
	_check(roster.size() > 1, "roster loaded with more than 1 entry (%d)" % roster.size())
	var notice: Dictionary = board.get("_active_notice")
	_check(not notice.is_empty(), "initial active notice picked on _ready")
	_check(notice.has("item_id") and notice.has("reward_silver"), "active notice is a request template")
	if notice.is_empty():
		await process_frame
		quit(1)
		return
	var item_id: String = String(notice.get("item_id", ""))
	var qty: int = int(notice.get("qty", 1))
	# 4) Insufficient items: soft-fail, zero economy mutation, hint dialogue.
	gd.inventory.erase(item_id)
	var pre_silver: int = gd.silver
	var pre_harmony: int = gd.harmony
	_dialogue.clear()
	_silver_hits = 0
	var soft: bool = board.call("_try_fulfill")
	_check(soft == false, "insufficient items -> soft-fail")
	_check(not gd.has_item(item_id, qty), "no inventory mutation on soft-fail")
	_check(gd.silver == pre_silver, "silver unchanged on soft-fail")
	_check(gd.harmony == pre_harmony, "harmony unchanged on soft-fail")
	_check(_silver_hits == 0, "no silver_changed emitted on soft-fail (check-before-deduct)")
	_check(_dialogue.size() == 1, "hint dialogue shown once on soft-fail (%d)" % _dialogue.size())
	if _dialogue.size() == 1:
		_check(String(_dialogue[0]["text"]) == String(notice.get("line", "")),
			"hint dialogue is the notice's own line")
	# 5) Sufficient items: fulfill grants rewards exactly once, then rotates.
	gd.add_item(item_id, qty)
	var pre_silver2: int = gd.silver
	var pre_harmony2: int = gd.harmony
	_dialogue.clear()
	_silver_hits = 0
	var ok: bool = board.call("_try_fulfill")
	_check(ok, "fulfill succeeds with enough items")
	_check(not gd.has_item(item_id, 1), "item removed after fulfill")
	_check(gd.silver == pre_silver2 + int(notice.get("reward_silver", 0)),
		"silver granted exactly once")
	_check(gd.harmony == pre_harmony2 + int(notice.get("reward_harmony", 0)),
		"harmony granted exactly once")
	_check(_silver_hits == 1, "silver_changed emitted exactly once on fulfill (%d)" % _silver_hits)
	_check(_dialogue.size() == 1 and String(_dialogue[0]["text"]).contains(String(notice.get("flavor_npc", ""))),
		"confirmation dialogue names the flavor_npc")
	var next_notice: Dictionary = board.get("_active_notice")
	_check(not next_notice.is_empty() and String(next_notice.get("id", "")) != String(notice.get("id", "")),
		"board rotated to a different notice after fulfill")
	# 6) Proximity: entering/exiting the InteractArea sets/clears
	# _player_in_range (mirror tests/test_fishing.gd — headless has no physics
	# step to reliably drive real body_entered/exited firing, so simulate the
	# Area2D signals directly).
	var player: Node2D = main.get_node_or_null("Player") as Node2D
	if player != null:
		board.call("_on_body_entered", player)
		_check(bool(board.get("_player_in_range")) == true, "entering the InteractArea sets _player_in_range")
		board.call("_on_body_exited", player)
		_check(bool(board.get("_player_in_range")) == false, "exiting the InteractArea clears _player_in_range")
	main.queue_free()
	print("\n=== NOTICEBOARD TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("NOTICEBOARD GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
