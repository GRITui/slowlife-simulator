extends SceneTree
# TASK-357 save/scene-restore gate (headless-safe).
# Run: godot --headless --path . --script res://tests/test_save_scene_restore.gd
#
# Verified before this fix existed: SaveManager.gd wrote "player_pos": [480, 384]
# as a HARDCODED LITERAL — never the player's actual position — and no code
# anywhere read player_pos back on load. There was also no field at all for
# which scene the player was in. This was harmless while the game had exactly
# one scene; TASK-357 makes it load-bearing, since a save made in a non-default
# area must not silently boot the player back into World at a stale default
# position. This test writes the failing case FIRST: a save made while
# standing in FarmHouse at a non-default position must load back into
# FarmHouse, at that exact position — not World, not the door-derived spawn,
# not the (480,384) historical default.

const SaveManagerScript: GDScript = preload("res://scripts/persistence/SaveManager.gd")
const WORLD_PATH: String = "res://scenes/core/World.tscn"
const FARMHOUSE_PATH: String = "res://scenes/interiors/FarmHouse.tscn"

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  save-scene-restore :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  save-scene-restore :: %s" % label)

func _wait_for_current_scene(expected_path: String) -> void:
	# TASK-354: switched from a fixed 10-iteration process_frame budget to
	# a 2-second time budget. SceneLoader now adds a ~200ms fade-out /
	# fade-in around every change_scene_to_file() call, which can stretch
	# total wall-clock past 10 unthrottled headless frames under
	# contention. A time budget is self-tuning for any future fade
	# retune (no per-call-site budget edits) and still returns promptly
	# under the common case (next process_frame). Also yields a few extra
	# process_frames after the swap so the new scene's _ready() chain
	# AND Player._physics_process have a chance to run before the caller
	# reads position — the fade previously left the test reading the
	# player's pre-clamp global_position on rare occasions.
	var deadline_msec: int = Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline_msec:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == expected_path:
			await process_frame
			await process_frame
			await process_frame
			return

func _initialize() -> void:
	await _run_all()
	print("\n=== SAVE-SCENE-RESTORE TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("SAVE-SCENE-RESTORE GATE FAILED: %d failing checks" % _failed)
	quit(1 if _failed > 0 else 0)

func _run_all() -> void:
	var sb: Node = root.get_node("SignalBus")
	var sm: Node = SaveManagerScript.new()

	# --- 1. Boot into FarmHouse directly (simulates the player having
	# walked in through the door earlier in a real session), move the
	# player to a distinctive non-default position, then save.
	sb.pending_warp_id = ""
	change_scene_to_file(FARMHOUSE_PATH)
	await _wait_for_current_scene(FARMHOUSE_PATH)
	var farm: Node = current_scene
	var farm_player: Node = farm.get_node_or_null("Player")
	_check(farm_player != null, "FarmHouse has a Player child to test against")
	var distinctive_pos: Vector2 = Vector2(111, 137) # nowhere near any default/door spawn
	if farm_player != null:
		(farm_player as Node2D).global_position = distinctive_pos

	var saved: bool = sm.save_game()
	_check(saved, "save_game() succeeds while standing in FarmHouse")

	# --- 2. Confirm the save actually wrote real values, not the old
	# hardcoded literal — read the raw JSON directly.
	var f: FileAccess = FileAccess.open("user://savegame.json", FileAccess.READ)
	var raw: String = f.get_as_text() if f else ""
	var parsed: Variant = JSON.parse_string(raw)
	_check(parsed is Dictionary, "saved file parses as JSON")
	if parsed is Dictionary:
		var d: Dictionary = parsed as Dictionary
		_check(String(d.get("scene_path", "")) == FARMHOUSE_PATH,
			"saved JSON scene_path is FarmHouse, not a hardcoded default (got %s)"
				% str(d.get("scene_path", "")))
		var pp: Array = d.get("player_pos", []) as Array
		_check(pp.size() == 2 and is_equal_approx(float(pp[0]), 111.0) and is_equal_approx(float(pp[1]), 137.0),
			"saved JSON player_pos is the REAL position (111,137), not the old [480,384] literal (got %s)"
				% str(pp))
		_check(int(d.get("version", 0)) == 7, "saved JSON carries version=7")

	# --- 3. Reset to World (simulating a fresh boot / different session),
	# putting the player far from the FarmHouse-saved position, THEN load.
	# load_game() must transition back to FarmHouse and land the player at
	# the exact saved position.
	sb.pending_warp_id = ""
	change_scene_to_file(WORLD_PATH)
	await _wait_for_current_scene(WORLD_PATH)
	_check(current_scene.scene_file_path == WORLD_PATH,
		"pre-load setup: currently in World, not FarmHouse (baseline)")

	var loaded: bool = sm.load_game()
	_check(loaded, "load_game() reads the saved file back")

	# The scene swap load_game() triggers is deferred — wait for it.
	await _wait_for_current_scene(FARMHOUSE_PATH)
	_check(current_scene.scene_file_path == FARMHOUSE_PATH,
		"load_game() transitions back to FarmHouse (the saved scene), not World")
	var restored_player: Node = current_scene.get_node_or_null("Player")
	_check(restored_player != null, "FarmHouse has a Player after the load-triggered transition")
	if restored_player != null:
		_check((restored_player as Node2D).global_position.distance_to(distinctive_pos) < 1.0,
			"player lands at the EXACT saved position (111,137) after load, got %s"
				% str((restored_player as Node2D).global_position))

	# --- 4. migrate(): a v5 payload (no scene_path field at all) must
	# default scene_path to the project's main scene, not crash or leave
	# it missing — this is what every pre-TASK-357 save on disk looks like.
	var v5: Dictionary = {
		"version": 5,
		"player_pos": [480, 384],
		"inventory": {},
		"harmony": 0,
	}
	var m: Dictionary = sm.migrate(v5)
	_check(int(m.get("version", 0)) == 7, "migrate advances a v5 payload to version 7 (TASK-357 scene_path + TASK-358 fish_almanac)")
	_check(String(m.get("scene_path", "")) == WORLD_PATH,
		"migrate defaults a v5 (pre-TASK-357) save's scene_path to the main scene (got %s)"
			% str(m.get("scene_path", "")))

	sm.queue_free()
