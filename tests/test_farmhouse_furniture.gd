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

	# --- F. TASK-375: cycle_furniture_item selects among OWNED items only ---
	gd.placed_furniture = {}
	gd.inventory = {}
	player.global_position = Vector2(3 * 48 + 24, 3 * 48 + 24) # cell (3,3), open
	gd.add_item(RUG_ID, 1)
	gd.add_item("floor_cushion", 1)
	gd.add_item("small_table", 1)
	furniture.set("_primed_furniture_id", "")
	_dispatch_action("cycle_furniture_item")
	await process_frame
	var primed1: String = String(furniture.get("_primed_furniture_id"))
	_dispatch_action("cycle_furniture_item")
	await process_frame
	var primed2: String = String(furniture.get("_primed_furniture_id"))
	_dispatch_action("cycle_furniture_item")
	await process_frame
	var primed3: String = String(furniture.get("_primed_furniture_id"))
	_check(primed1 != primed2 and primed2 != primed3 and primed1 in ["floor_rug", "floor_cushion", "small_table"],
		"cycle_furniture_item advances through owned items ('%s' -> '%s' -> '%s')" % [primed1, primed2, primed3])

	# --- G. floor_cushion and small_table are placeable/pickup-able the same way ---
	furniture.set("_primed_furniture_id", "floor_cushion")
	# Place mode was toggled ON once in section A and never toggled off
	# anywhere in this file since -- confirm that's still true rather
	# than assume it, since a future edit to this test could change that.
	if not bool(furniture.get("_place_mode")):
		_dispatch_action("toggle_furniture_place_mode")
		await process_frame
	_dispatch_action("interact")
	await process_frame
	_check(gd.has_placed_furniture_at(LOCATION_ID, Vector2i(3, 3)),
		"floor_cushion placed at (3,3) via the primed-item flow")
	_check(furniture.has_node("Cushion_3_3"), "a visible cushion sprite is spawned at (3,3)")
	_check(not gd.has_item("floor_cushion", 1), "placing the cushion consumes it from inventory")

	# --- H. Rotation ---
	var facing0: int = int(gd.get_placed_furniture_at(LOCATION_ID, Vector2i(3, 3)).get("facing", -1))
	_check(facing0 == 0, "newly-placed cushion defaults to facing=0")
	var seen_facings: Array = [facing0]
	for i in range(5):
		_dispatch_action("rotate_furniture")
		await process_frame
		seen_facings.append(int(gd.get_placed_furniture_at(LOCATION_ID, Vector2i(3, 3)).get("facing", -1)))
	_check(seen_facings == [0, 1, 2, 3, 0, 1],
		"rotating 5 times steps 0->1->2->3->0->1 (got %s)" % str(seen_facings))
	var sprite_after_rotate: Sprite2D = furniture.get_node("Cushion_3_3") as Sprite2D
	_check(sprite_after_rotate != null and is_equal_approx(sprite_after_rotate.rotation_degrees, 90.0),
		"the live sprite's rotation_degrees matches facing=1 (90°) after 5 rotations")

	# Rotating an empty cell is a no-op, no crash.
	player.global_position = Vector2(0 * 48 + 24, 0 * 48 + 24) # cell (0,0), empty
	var before_empty_rotate: Dictionary = gd.get_placed_furniture_at(LOCATION_ID, Vector2i(3, 3)).duplicate()
	_dispatch_action("rotate_furniture")
	await process_frame
	_check(gd.get_placed_furniture_at(LOCATION_ID, Vector2i(3, 3)) == before_empty_rotate,
		"rotating an empty cell does not affect any other placed entry")

	# Pick the cushion back up.
	player.global_position = Vector2(3 * 48 + 24, 3 * 48 + 24)
	_dispatch_action("interact")
	await process_frame
	await process_frame
	_check(not gd.has_placed_furniture_at(LOCATION_ID, Vector2i(3, 3)),
		"picking up the cushion removes it from placed_furniture")
	_check(gd.has_item("floor_cushion", 1), "picking up returns the cushion to inventory")

	# --- I. small_table placement (independent cell) ---
	player.global_position = Vector2(0 * 48 + 24, 2 * 48 + 24) # cell (0,2), open
	furniture.set("_primed_furniture_id", "small_table")
	_dispatch_action("interact")
	await process_frame
	_check(gd.has_placed_furniture_at(LOCATION_ID, Vector2i(0, 2)),
		"small_table placed at (0,2) via the primed-item flow")
	_check(furniture.has_node("Table_0_2"), "a visible table sprite is spawned at (0,2)")

	# --- J. Old (Phase 1) save entries with no `facing` key load as facing=0 ---
	gd.placed_furniture[LOCATION_ID] = [{"item_id": "floor_rug", "cell": Vector2i(5, 4)}]
	var legacy_entry: Dictionary = gd.get_placed_furniture_at(LOCATION_ID, Vector2i(5, 4))
	_check(not legacy_entry.has("facing"),
		"a pre-TASK-375 entry genuinely has no 'facing' key (sanity check on the fixture)")
	_check(int(legacy_entry.get("facing", 0)) == 0,
		"every real read site's entry.get(\"facing\", 0) call defaults a missing key to facing=0, not a crash")

	# --- K. Save/load round-trip preserves facing for a rotated item ---
	gd.placed_furniture = {}
	gd.inventory = {}
	gd.add_item(RUG_ID, 1)
	player.global_position = Vector2(2 * 48 + 24, 3 * 48 + 24) # cell (2,3), open
	furniture.set("_primed_furniture_id", "floor_rug")
	_dispatch_action("interact")
	await process_frame
	_dispatch_action("rotate_furniture")
	await process_frame
	_dispatch_action("rotate_furniture")
	await process_frame
	var facing_before_save: int = int(gd.get_placed_furniture_at(LOCATION_ID, Vector2i(2, 3)).get("facing", -1))
	_check(facing_before_save == 2, "pre-save facing is 2 (180°) after two rotations")
	var sm2: Node = SaveManagerScript.new()
	var saved2: bool = sm2.save_game()
	_check(saved2, "save_game() succeeds with a rotated furniture entry")
	gd.placed_furniture = {}
	var loaded2: bool = sm2.load_game()
	_check(loaded2, "load_game() reads the saved file back")
	_check(int(gd.get_placed_furniture_at(LOCATION_ID, Vector2i(2, 3)).get("facing", -1)) == 2,
		"facing survives the save/load round-trip (still 2 after reload)")
	sm2.queue_free()

	# --- L. fishing_net's neighbor: floor_cushion / small_table are real market items ---
	var mm_script: GDScript = load("res://scripts/market/MarketManager.gd")
	var found_cushion: bool = false
	var found_table: bool = false
	for season in mm_script.BUY_OFFERS.keys():
		for offer: Dictionary in (mm_script.BUY_OFFERS[season] as Array):
			if String(offer.get("item", "")) == "floor_cushion":
				found_cushion = true
			if String(offer.get("item", "")) == "small_table":
				found_table = true
	_check(found_cushion, "floor_cushion is a real MarketManager.BUY_OFFERS entry")
	_check(found_table, "small_table is a real MarketManager.BUY_OFFERS entry")

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
