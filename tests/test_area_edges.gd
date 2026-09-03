extends SceneTree
# TASK-357 area-edge gate. Mirrors test_scene_transitions.gd's exact style
# (same _check() helper, same _wait_for_current_scene() polling helper, same
# print format, same quit-on-failure finalization). Covers the load-bearing
# edges-only regressions that test_scene_transitions.gd does NOT exercise:
#
# 1. Edge crossings land the player at the carried coordinate on carry_axis,
#    not at a fixed point (the one real design difference from a Door warp).
#    Forward (World -> CoastalArea) and reverse (CoastalArea -> World).
# 2. TimeManager / clock state survives a World <-> CoastalArea round trip
#    (same load-bearing check as test_scene_transitions.gd, now exercised
#    on a second scene pair).
# 3. Warp-id uniqueness across every Door and EdgeTransition in scenes/ —
#    a gate-level collision scan (Door and EdgeTransition share the same
#    @export var warp_id: String, so a typo in either namespace silently
#    aliases both — this scan would catch it).

const WORLD_PATH: String = "res://scenes/core/World.tscn"
const COASTAL_PATH: String = "res://scenes/interiors/CoastalArea.tscn"
const EAST_EDGE_WARP_ID: String = "world_east_to_coastal"  # World's EastEdge.warp_id (matches CoastalArea.WestEdge.target_warp_id)
const WEST_EDGE_WARP_ID: String = "coastal_west_to_world"  # CoastalArea.WestEdge.warp_id (matches World.EastEdge.target_warp_id)

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  area-edges :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  area-edges :: %s" % label)

func _initialize() -> void:
	await _run_all()
	print("\n=== AREA-EDGES TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("AREA-EDGES GATE FAILED: %d failing checks" % _failed)
	quit(1 if _failed > 0 else 0)

func _run_all() -> void:
	var sb: Node = root.get_node("SignalBus")
	var tm: Node = root.get_node("TimeManager")
	# Wait one frame so the autoloads' _ready()s have a chance to wire up
	# SignalBus.time_manager / SignalBus.scene_transition_requested before
	# we read or emit anything.
	await process_frame

	# Pre-debounce setup: any prior scene transition from earlier autoload
	# readiness stamps SceneLoader._last_transition_msec, which would eat
	# the first transition in this test under the 400ms debounce. Wait
	# past the window with TimeManager.auto_tick frozen (the time advances
	# 6 min/sec by default — freezing it keeps any clock-state checks in
	# this file deterministic across the wait).
	var saved_auto_tick: bool = tm.auto_tick
	tm.auto_tick = false
	await create_timer(0.5).timeout

	# --- 0. Sanity: both warp-ids declared in their respective .tscn files
	# actually match the constants at the top of this file. Catches a
	# future rename of either side without needing to update this test
	# (the constant + the .tscn divergence would be the first sign).
	var world_tscn: String = FileAccess.get_file_as_string(WORLD_PATH)
	var coastal_tscn: String = FileAccess.get_file_as_string(COASTAL_PATH)
	_check(world_tscn.contains("warp_id = \"%s\"" % EAST_EDGE_WARP_ID),
		"World.tscn declares EdgeTransition with warp_id=\"%s\"" % EAST_EDGE_WARP_ID)
	_check(world_tscn.contains("target_warp_id = \"%s\"" % WEST_EDGE_WARP_ID),
		"World.tscn's EastEdge targets CoastalArea with target_warp_id=\"%s\"" % WEST_EDGE_WARP_ID)
	_check(coastal_tscn.contains("warp_id = \"%s\"" % WEST_EDGE_WARP_ID),
		"CoastalArea.tscn declares EdgeTransition with warp_id=\"%s\"" % WEST_EDGE_WARP_ID)
	_check(coastal_tscn.contains("target_warp_id = \"%s\"" % EAST_EDGE_WARP_ID),
		"CoastalArea.tscn's WestEdge targets World with target_warp_id=\"%s\"" % EAST_EDGE_WARP_ID)

	# --- 1. Boot World fresh. Same setup as test_scene_transitions.gd: a
	# known-empty pending_warp_id baseline so any prior-test bleed can't
	# pollute the first transition's spawn resolution.
	sb.pending_warp_id = ""
	var world: Node = (load(WORLD_PATH) as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	# Locate the outdoor EastEdge by warp_id (same lookup test_scene_transitions.gd
	# uses for doors). Confirms the .tscn is wired correctly — without
	# this node in the edge_transition group, the forward transition's
	# InteriorBase resolution below would have nothing to match against.
	var east_edge: Node = null
	for e in world.get_tree().get_nodes_in_group("edge_transition"):
		if e is Node2D and String((e as Node).get("warp_id")) == EAST_EDGE_WARP_ID:
			east_edge = e
			break
	_check(east_edge != null,
		"World.tscn exposes an EdgeTransition in 'edge_transition' group with warp_id=\"%s\"" % EAST_EDGE_WARP_ID)
	_check(east_edge != null and String((east_edge as Node).get("target_scene_path")) == COASTAL_PATH,
		"World's EastEdge target_scene_path=\"%s\"" % COASTAL_PATH)
	_check(east_edge != null and String((east_edge as Node).get("target_warp_id")) == WEST_EDGE_WARP_ID,
		"World's EastEdge target_warp_id=\"%s\" (the matching CoastalArea.WestEdge.warp_id)" % WEST_EDGE_WARP_ID)
	_check(east_edge != null and String((east_edge as Node).get("carry_axis")) == "y",
		"World's EastEdge carry_axis=\"y\" (east/west edge carries the player's Y across)")

	# --- 2. Edge crossing World -> CoastalArea: player lands at the
	# carried Y coordinate, NOT at a fixed point. Drive the same code path
	# an EdgeTransition's _on_body_entered would: set
	# SignalBus.edge_carry_value to the player's distinctive Y, then fire
	# scene_transition_requested with the EastEdge's target_scene_path +
	# target_warp_id (which SceneLoader stuffs into pending_warp_id). We
	# can't simulate real physics body-overlap in a headless test any
	# more than test_scene_transitions.gd can simulate a door's
	# _unhandled_input — so we drive the signal directly, same way it
	# does.
	#
	# Distinctive Y is chosen FAR from both the outdoor default (384) and
	# any plausible CoastalArea default — if InteriorBase._place_player
	# somehow fell through to default_spawn instead of honoring the edge
	# match, this assertion would catch it immediately.
	var carried_y_forward: float = 217.5
	var player_world: Node = world.get_node("Player")
	_check(player_world != null, "World has a Player child (instanced in World.gd._ready)")
	# Set the carry value BEFORE emitting the transition. EdgeTransition.gd
	# line 47 does this in _on_body_entered; SceneLoader preserves it
	# across change_scene_to_file (only pending_warp_id is stamped by
	# SceneLoader, edge_carry_value lives on SignalBus untouched).
	sb.edge_carry_value = carried_y_forward
	sb.scene_transition_requested.emit(COASTAL_PATH, WEST_EDGE_WARP_ID)
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	await _wait_for_current_scene(COASTAL_PATH)
	var coastal: Node = current_scene
	_check(coastal.scene_file_path == COASTAL_PATH,
		"World -> CoastalArea transition landed current_scene on CoastalArea.tscn (got %s)"
			% str(coastal.scene_file_path))
	_check(sb.pending_warp_id == "",
		"CoastalArea._ready() (via InteriorBase._place_player) consumed pending_warp_id='%s'" % WEST_EDGE_WARP_ID)
	var player_coastal: Node = coastal.get_node_or_null("Player")
	_check(player_coastal != null,
		"CoastalArea has a Player child (instanced by InteriorBase._spawn_player)")
	# Locate the matching incoming edge in CoastalArea — same group walk
	# InteriorBase._place_player does internally.
	var west_edge: Node = null
	for e in coastal.get_tree().get_nodes_in_group("edge_transition"):
		if e is Node2D and String((e as Node).get("warp_id")) == WEST_EDGE_WARP_ID:
			west_edge = e
			break
	_check(west_edge != null,
		"CoastalArea exposes an EdgeTransition in 'edge_transition' group with warp_id=\"%s\"" % WEST_EDGE_WARP_ID)
	if player_coastal != null and west_edge != null:
		var west_edge_x: float = (west_edge as Node2D).global_position.x
		# NOTE on X expectation: Player.gd._physics_process clamps the
		# player's global_position to the outdoor 20x16 grid bounds
		# [24, 936] x [24, 744] on every physics tick — that's WHY the
		# player snaps to x=24 here even though the edge is at x=0.
		# Without this clamp a real player could walk past the western
		# map edge. The carry behavior we're testing lives on the Y axis
		# (the carry_axis for an east/west edge); the X is anchored to
		# the edge's position, then clamped to bounds. So the X assertion
		# checks "close to the edge X" (within clamp range), not "exactly
		# equal to the edge X".
		var clamped_x: float = clamp(west_edge_x, 24.0, 20.0 * 48.0 - 24.0)
		var expected_pos: Vector2 = Vector2(clamped_x, carried_y_forward)
		_check(player_coastal.global_position == expected_pos,
			"Player landed at carried Y on CoastalArea.WestEdge (X clamped to bounds, got %s, expected %s)"
				% [str(player_coastal.global_position), str(expected_pos)])
		# Confirm the assertion is NOT trivially satisfied by default_spawn
		# (default_spawn in CoastalArea.gd is Vector2(72, 120) — a totally
		# different cell, so this would catch a fall-through regression).
		_check(player_coastal.global_position.y != 120.0,
			"Player did NOT snap to CoastalArea's default_spawn (y=120) — edge resolution took effect")
		_check(player_coastal.global_position.x == clamped_x,
			"Player's X is anchored to CoastalArea.WestEdge's X (then clamped to bounds; got %s, expected %s)"
				% [str(player_coastal.global_position.x), str(clamped_x)])

	# --- 3. Edge crossing CoastalArea -> World: same in reverse, but with
	# a different distinctive Y so we know the test isn't passing because
	# of a stale carry_value or a static position. World.gd's _ready()
	# resolves pending_warp_id against the edge_transition group (TASK-357
	# bugfix parallel to InteriorBase._place_player) so the WestEdge's
	# target_warp_id="world_east_to_coastal" lands the player at
	# (EastEdge.x, SignalBus.edge_carry_value) — NOT at the (480, 384)
	# outdoor default that the door-only fallback would give.
	#
	# Wait past the 400ms SceneLoader debounce first so this emit is
	# treated as a NEW transition (the previous forward emit landed ~4-5
	# frames ago, well inside the 400ms window).
	await create_timer(0.5).timeout
	var carried_y_reverse: float = 425.5
	# Stash the forward's Y so a bug that used the stale carry_value would
	# visibly fail (carry_y_reverse != carry_y_forward on purpose).
	_check(carried_y_reverse != carried_y_forward,
		"distinctive Y values for forward vs reverse so a stale edge_carry_value is caught")
	sb.edge_carry_value = carried_y_reverse
	sb.scene_transition_requested.emit(WORLD_PATH, EAST_EDGE_WARP_ID)
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	await _wait_for_current_scene(WORLD_PATH)
	var world_back: Node = current_scene
	_check(world_back.scene_file_path == WORLD_PATH,
		"CoastalArea -> World transition landed current_scene on World.tscn (got %s)"
			% str(world_back.scene_file_path))
	_check(sb.pending_warp_id == "",
		"World._ready() (TASK-357 edge branch) consumed pending_warp_id='%s'" % EAST_EDGE_WARP_ID)
	var player_world2: Node = world_back.get_node("Player")
	_check(player_world2 != null, "World has a Player child after the reverse transition")
	if player_world2 != null:
		# Re-find the EastEdge (fresh tree after the swap).
		var east_edge2: Node = null
		for e in world_back.get_tree().get_nodes_in_group("edge_transition"):
			if e is Node2D and String((e as Node).get("warp_id")) == EAST_EDGE_WARP_ID:
				east_edge2 = e
				break
		_check(east_edge2 != null,
			"World.tscn (post-swap) still exposes EastEdge in 'edge_transition' group")
		if east_edge2 != null:
			var east_edge_x: float = (east_edge2 as Node2D).global_position.x
			# Same X-clamp behavior as the forward direction above —
			# Player.gd._physics_process clamps x to the outdoor bounds
			# [24, 936], so the east edge's x=940 spawns the player at
			# x=936 (clamped down). The carry-axis (y) is unconstrained.
			var clamped_x2: float = clamp(east_edge_x, 24.0, 20.0 * 48.0 - 24.0)
			var expected_pos2: Vector2 = Vector2(clamped_x2, carried_y_reverse)
			_check(player_world2.global_position == expected_pos2,
				"Player landed at carried Y on World.EastEdge (X clamped to bounds, got %s, expected %s)"
					% [str(player_world2.global_position), str(expected_pos2)])
			# Confirm the assertion is NOT trivially satisfied by the
			# outdoor default spawn (480, 384). Without the World.gd edge
			# branch, this position is exactly where the player would
			# land — that's the bug this regression guard is here to catch.
			_check(player_world2.global_position != Vector2(10 * 48, 8 * 48),
				"Player did NOT snap to World's outdoor default (480, 384) — edge resolution took effect")
			_check(player_world2.global_position.y == carried_y_reverse,
				"Player's Y matches the carried value (got %s, expected %s)"
					% [str(player_world2.global_position.y), str(carried_y_reverse)])

	# --- 4. TimeManager / clock state survives a World <-> CoastalArea
	# round trip. Same shape as test_scene_transitions.gd's clock-survival
	# check (see lines 70-113 of that file), just targeting CoastalArea
	# instead of FarmHouse — the load-bearing regression for any new
	# interior. If the second InteriorBase subclass accidentally
	# registered its own TimeManager or reset the day/hour on boot, this
	# would catch it.
	await create_timer(0.5).timeout
	tm.set_time(11, 9, 27)
	_check(tm.day == 11 and tm.hour == 9 and tm.minute == 27,
		"clock set to day 11 09:27 BEFORE the World -> CoastalArea transition")
	var tm_before_fwd: Node = sb.time_manager
	# Reset carry_value so a stale carry from the prior reverse edge
	# doesn't influence this transition's spawn (we want to verify the
	# transition itself works, not re-test the carry here).
	sb.edge_carry_value = 0.0
	sb.scene_transition_requested.emit(COASTAL_PATH, WEST_EDGE_WARP_ID)
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	await _wait_for_current_scene(COASTAL_PATH)
	_check(sb.time_manager == tm_before_fwd,
		"SignalBus.time_manager is the SAME node instance after World -> CoastalArea swap (autoload survived)")
	_check(sb.time_manager != null and sb.time_manager.day == 11
			and sb.time_manager.hour == 9
			and sb.time_manager.minute == 27,
		"clock state day=11 09:27 SURVIVED the World -> CoastalArea swap")
	# Same again in reverse — CoastalArea -> World. Distinct time so the
	# swap didn't reset to start_day/start_hour defaults.
	await create_timer(0.5).timeout
	tm.set_time(14, 22, 3)
	var tm_before_rev: Node = sb.time_manager
	sb.edge_carry_value = 0.0
	sb.scene_transition_requested.emit(WORLD_PATH, EAST_EDGE_WARP_ID)
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	await _wait_for_current_scene(WORLD_PATH)
	_check(sb.time_manager == tm_before_rev,
		"SignalBus.time_manager is the SAME node instance after CoastalArea -> World swap (autoload survived)")
	_check(sb.time_manager != null and sb.time_manager.day == 14
			and sb.time_manager.hour == 22
			and sb.time_manager.minute == 3,
		"clock state day=14 22:03 SURVIVED the CoastalArea -> World swap (full edge round-trip)")
	# pending_warp_id consumed by the World swap.
	_check(sb.pending_warp_id == "",
		"SignalBus.pending_warp_id is cleared after World's _ready() consumed 'world_east_to_coastal'")

	# --- 5. Warp-id uniqueness across every Door and EdgeTransition in
	# scenes/. Both node types share the same @export var warp_id: String
	# property name (see EdgeTransition.gd:31 and Door.gd), and a typo in
	# either namespace silently aliases both — one warp_id resolving to
	# two different scene entries means a transition signal could route
	# to either depending on scene-load order, which is exactly the kind
	# of bug that's invisible at code review but obvious in a scan.
	#
	# Walk scenes/ recursively via DirAccess, collect every `warp_id = "..."`
	# line per file, fail if any value appears twice across the whole tree
	# (or twice within the same file — both would be a regression).
	var all_warp_ids: Dictionary = {}  # warp_id -> Array of "file:line"
	var warp_id_re: RegEx = RegEx.new()
	# Lookbehind on [a-zA-Z_] excludes `target_warp_id = "..."` matches —
	# we only want the plain `warp_id = "..."` property on the EdgeTransition
	# / Door node itself, not the outgoing edge's target reference. Anchored
	# to the start of the property assignment on a line.
	warp_id_re.compile("(?<![a-zA-Z_])warp_id\\s*=\\s*\"([^\"]+)\"")
	var scenes_dir: DirAccess = DirAccess.open("res://scenes")
	_check(scenes_dir != null, "DirAccess.open('res://scenes') succeeded (scenes directory exists)")
	if scenes_dir != null:
		_collect_warp_ids("res://scenes", all_warp_ids, warp_id_re)
	# Report the full inventory for debugging — useful when a uniqueness
	# check fails and we want to see what other entries share the value.
	var inventory_lines: Array = []
	for wid in all_warp_ids.keys():
		inventory_lines.append("%s -> %s" % [wid, str(all_warp_ids[wid])])
	print("DEBUG: warp_id inventory: %s" % "; ".join(inventory_lines))
	# The actual uniqueness assertion: zero duplicates across the whole
	# tree. If any warp_id appears in two distinct locations, this fails.
	var duplicates: Array = []
	for wid in all_warp_ids.keys():
		if (all_warp_ids[wid] as Array).size() > 1:
			duplicates.append("%s (used at %s)" % [wid, str(all_warp_ids[wid])])
	_check(duplicates.is_empty(),
		"every warp_id in scenes/ is unique across the whole tree (duplicates: %s)"
			% ("none" if duplicates.is_empty() else str(duplicates)))
	# And confirm we actually scanned SOMETHING — if the directory walk
	# silently bailed, the uniqueness check above is meaningless.
	_check(all_warp_ids.size() >= 2,
		"warp-id scan found at least 2 entries (saw %d — World has farmhouse_entry + world_east_to_coastal, CoastalArea has coastal_west_to_world, FarmHouse has farmhouse_exit)"
			% all_warp_ids.size())

	# Restore auto-tick before exit so any subsequent test that doesn't
	# re-stamp it inherits the original autoload default, not our freeze.
	tm.auto_tick = saved_auto_tick

func _collect_warp_ids(dir_path: String, all_warp_ids: Dictionary, warp_id_re: RegEx) -> void:
	# Walk this directory one level at a time (DirAccess exposes
	# get_files() / get_directories() at the same level — no recursion
	# helper in the API, so we recurse manually). We pass the path as a
	# String and re-open per call: DirAccess.open(sub) on an existing
	# DirAccess parent returns null in Godot 4 (subdirs are only openable
	# from a fresh root), so a fresh open per recursion level is required.
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	var entries: PackedStringArray = dir.get_files()
	for fname in entries:
		if not fname.ends_with(".tscn"):
			continue
		var full_path: String = dir_path.path_join(fname)
		var src: String = FileAccess.get_file_as_string(full_path)
		var line_num: int = 0
		for line in src.split("\n"):
			line_num += 1
			var m: RegExMatch = warp_id_re.search(line)
			if m == null:
				continue
			var wid: String = m.get_string(1)
			if not all_warp_ids.has(wid):
				all_warp_ids[wid] = []
			(all_warp_ids[wid] as Array).append("%s:%d" % [full_path, line_num])
	var subdirs: PackedStringArray = dir.get_directories()
	for sub in subdirs:
		_collect_warp_ids(dir_path.path_join(sub), all_warp_ids, warp_id_re)

func _wait_for_current_scene(expected_path: String) -> void:
	# change_scene_to_file defers the actual swap; poll current_scene until
	# it matches expected_path or we hit a generous frame budget. Same shape
	# as test_scene_transitions.gd's helper.
	for _i in 10:
		await process_frame
		if current_scene != null:
			var ps: Node = current_scene
			if ps.scene_file_path == expected_path:
				return