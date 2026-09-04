extends SceneTree
# TASK-374 Phase 1 gate — furniture placement (floor_rug, FarmHouse-only,
# no rotation). Instances the real FarmHouse.tscn and drives the actual
# input actions / GameData API, not a mock. Follows the existing tests'
# `_check(cond, label)` convention (see test_farmhouse_decor.gd).

const FARMHOUSE_PATH: String = "res://scenes/interiors/FarmHouse.tscn"
const SaveManagerScript: GDScript = preload("res://scripts/persistence/SaveManager.gd")
const RUG_ID: String = "floor_rug"
const LOCATION_ID: String = "farmhouse"

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  farmhouse-furniture :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  farmhouse-furniture :: %s" % label)

func _initialize() -> void:
	await _run_all()
	print("\n=== FARMHOUSE-FURNITURE TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("FARMHOUSE-FURNITURE GATE FAILED: %d failing checks" % _failed)
	quit(1 if _failed > 0 else 0)

func _run_all() -> void:
	var gd: Node = root.get_node("GameData")
	# Clean slate for this test run.
	gd.placed_furniture = {}
	gd.inventory = {}

	var scene: PackedScene = load(FARMHOUSE_PATH)
	_check(scene != null, "FarmHouse.tscn loads")
	if scene == null:
		return
	var farmhouse: Node = scene.instantiate()
	root.add_child(farmhouse)
	await process_frame

	var furniture: Node2D = farmhouse.get_node_or_null("FarmHouseFurniture") as Node2D
	_check(furniture != null, "FarmHouseFurniture node exists in FarmHouse.tscn (not just the script)")
	if furniture == null:
		farmhouse.queue_free()
		return

	# InteriorBase._spawn_player() already auto-spawns a REAL Player.tscn
	# as part of FarmHouse.tscn's own _ready() (confirmed: FarmHouse.gd
	# extends InteriorBase). Use that real player, not a second fake one
	# -- a separate fake CharacterBody2D in the "player" group would sit
	# alongside the real Player, and both listen for "interact", causing
	# the real Player's own outdoor grid-interact logic to also fire on
	# every synthesized input event in this test.
	var player: Node2D = get_first_node_in_group("player") as Node2D
	_check(player != null, "InteriorBase auto-spawned a real Player in FarmHouse.tscn")
	if player == null:
		farmhouse.queue_free()
		return
	player.global_position = Vector2(2 * 48 + 24, 2 * 48 + 24) # cell (2,2), open
	await process_frame

	# --- A. Placement requires ownership ---
	_check(not gd.has_item(RUG_ID, 1), "starts with no floor_rug owned")
	_dispatch_action("toggle_furniture_place_mode")
	await process_frame
	_dispatch_action("interact")
	await process_frame
	_check(gd.placed_furniture.get(LOCATION_ID, []).is_empty(),
		"interact with no rug owned places nothing")

	# --- B. Place a rug (place mode already toggled on above) ---
	gd.add_item(RUG_ID, 1)
	_dispatch_action("interact")
	await process_frame
	_check(gd.has_placed_furniture_at(LOCATION_ID, Vector2i(2, 2)),
		"placing at cell (2,2) records it in GameData.placed_furniture")
	_check(not gd.has_item(RUG_ID, 1), "placing consumes the rug from inventory")
	_check(furniture.has_node("Rug_2_2"), "a visible rug sprite is spawned at (2,2)")

	# --- C. Occupied-tile safety: Bed sits at cell (1,1) ---
	player.global_position = Vector2(1 * 48 + 24, 1 * 48 + 24)
	gd.add_item(RUG_ID, 1)
	_dispatch_action("interact")
	await process_frame
	_check(not gd.has_placed_furniture_at(LOCATION_ID, Vector2i(1, 1)),
		"cannot place on Bed's occupied cell (1,1)")
	_check(gd.has_item(RUG_ID, 1), "a failed placement does not consume the rug")

	# --- D. Pick back up ---
	player.global_position = Vector2(2 * 48 + 24, 2 * 48 + 24)
	_dispatch_action("interact")
	await process_frame
	await process_frame # queue_free() is deferred -- one frame isn't reliably enough
	_check(not gd.has_placed_furniture_at(LOCATION_ID, Vector2i(2, 2)),
		"picking up removes it from GameData.placed_furniture")
	_check(gd.has_item(RUG_ID, 2), "picking up returns the rug to inventory")
	_check(not furniture.has_node("Rug_2_2"), "the rug sprite is removed on pickup")

	# --- E. Save/load round trip ---
	_dispatch_action("interact") # place it again for the round-trip check
	await process_frame
	var expected_count: int = gd.placed_furniture.get(LOCATION_ID, []).size()
	var sm: Node = SaveManagerScript.new()
	var saved: bool = sm.save_game()
	_check(saved, "SaveManager.save_game() writes with placed_furniture in the payload")
	gd.placed_furniture = {}
	var loaded: bool = sm.load_game()
	_check(loaded, "SaveManager.load_game() reads the saved file back")
	_check(gd.placed_furniture.get(LOCATION_ID, []).size() == expected_count,
		"placed_furniture round-trips through save/load")

	farmhouse.queue_free() # player is InteriorBase's own child, freed with it
	await process_frame

func _dispatch_action(action: String) -> void:
	# Synthesize a REAL InputEventAction so _unhandled_input() actually
	# fires — Input.action_press() alone only satisfies polled
	# is_action_pressed() checks, not _input()/_unhandled_input() handlers.
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
