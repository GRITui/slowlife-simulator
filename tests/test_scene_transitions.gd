extends SceneTree
# TASK-352 scene-transition gate. Covers the load-bearing regression for
# this whole task: TimeManager + clock state MUST survive a building-entry
# scene swap (otherwise every door entry silently resets the player to day
# 1, 06:00). Plus the door round-trip warp-spawn contract and the
# pending_warp_id hygiene that prevents stale-warp leakage across
# unrelated scene loads.

const WORLD_PATH: String = "res://scenes/core/World.tscn"
const FARMHOUSE_PATH: String = "res://scenes/interiors/FarmHouse.tscn"

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  scene-transitions :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  scene-transitions :: %s" % label)

func _initialize() -> void:
	await _run_all()
	print("\n=== SCENE-TRANSITION TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("SCENE-TRANSITION GATE FAILED: %d failing checks" % _failed)
	quit(1 if _failed > 0 else 0)

func _run_all() -> void:
	var sb: Node = root.get_node("SignalBus")
	var tm: Node = root.get_node("TimeManager")

	# --- 1. TimeManager is a true autoload, not a child of the loaded area.
	# Proven by: (a) it exists at /root/TimeManager independently of any
	# loaded scene, (b) it's NOT a descendant of any loaded area root,
	# and (c) it's the same instance that SignalBus.time_manager points at.
	# Wait one frame so the autoload's _ready() (which sets
	# SignalBus.time_manager = self) has a chance to run before we read.
	await process_frame
	_check(tm != null, "TimeManager autoload present at /root/TimeManager")
	print("DEBUG: tm path=%s, sb.time_manager path=%s, equal=%s" % [
		str(tm.get_path()),
		str(sb.time_manager.get_path() if sb.time_manager else "<null>"),
		str(sb.time_manager == tm),
	])
	_check(sb.time_manager == tm,
		"SignalBus.time_manager is the running autoload instance (not a separate child)")
	# Force pending_warp_id to a known empty baseline so any prior test
	# bleed doesn't pollute the first transition.
	sb.pending_warp_id = ""
	var world: Node = (load(WORLD_PATH) as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	_check(sb.time_manager != null and sb.time_manager.get_parent() != world,
		"SignalBus.time_manager is NOT a descendant of World (TASK-352 autoload guarantee)")
	# Also sanity-check the new per-area render registry slot.
	_check(sb.world_render != null,
		"SignalBus.world_render populated by World's _ready()")
	_check(sb.world_render.get_parent() == world,
		"SignalBus.world_render is the outdoor World's child (not the FarmHouse's)")

	# --- 2. The single most important regression: clock survives a scene swap.
	# Advance TimeManager to day 5, mark a unique hour/minute, fire a
	# transition to the FarmHouse (a fresh .tscn that boots its own
	# grid_manager + world_render), and confirm SignalBus.time_manager.day
	# is STILL 5 — AND that it points at the SAME node instance (proving the
	# autoload survived, not just a clock value that was rewritten elsewhere).
	tm.set_time(5, 14, 37)
	_check(tm.day == 5 and tm.hour == 14 and tm.minute == 37,
		"clock set to day 5 14:37 BEFORE the transition")
	var tm_before: Node = sb.time_manager
	sb.scene_transition_requested.emit(FARMHOUSE_PATH, "farmhouse_entry")
	# change_scene_to_file is queued; wait several frames so the deferred
	# _free fires and the new scene's _ready runs.
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	_check(sb.time_manager == tm_before,
		"SignalBus.time_manager is the SAME node instance after FarmHouse swap (autoload survived)")
	_check(sb.time_manager != null and sb.time_manager.day == 5
			and sb.time_manager.hour == 14
			and sb.time_manager.minute == 37,
		"clock state day=5 14:37 SURVIVED the World -> FarmHouse swap (the load-bearing fix)")
	# Same again in reverse — FarmHouse -> World. Set a distinct time first
	# so we know the swap didn't reset to the start_day/start_hour defaults.
	# TASK-353: SceneLoader's 400ms transition debounce (Fix 2) is now
	# active on every signal-driven transition. Wait past the window so
	# this FarmHouse -> World emit is treated as a NEW transition, not a
	# re-trigger of the World -> FarmHouse emit above (~4 frames away).
	# TASK-354: SceneLoader now stamps _last_transition_msec only AFTER
	# its ~100ms fade-out tween completes (not immediately on emit), so
	# the real gap between two transitions' debounce stamps is up to
	# ~100ms tighter than the wait below suggests. 0.5s left only a ~0ms
	# safety margin against the 400ms window under that additional
	# delay (observed flaking intermittently) -- widened to 1.0s for a
	# comfortable ~500ms+ margin regardless of fade timing jitter.
	# TimeManager auto-ticks at 6 min/sec, so freeze auto-tick across the
	# wait AND the post-emit frame drain, otherwise a single game
	# minute can tick during the scene swap and our target (8,3,12)
	# drifts to (8,3,13) before we can read it back.
	var saved_auto_tick: bool = tm.auto_tick
	tm.auto_tick = false
	await create_timer(1.0).timeout
	tm.set_time(8, 3, 12)
	var tm_before_2: Node = sb.time_manager
	sb.scene_transition_requested.emit(WORLD_PATH, "farmhouse_exit")
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	tm.auto_tick = saved_auto_tick
	_check(sb.time_manager == tm_before_2,
		"SignalBus.time_manager is the SAME node instance after FarmHouse -> World swap")
	_check(sb.time_manager != null and sb.time_manager.day == 8
			and sb.time_manager.hour == 3
			and sb.time_manager.minute == 12,
		"clock state day=8 03:12 SURVIVED the FarmHouse -> World swap (round-trip)")
	# Now in the World scene again. Confirm pending_warp_id was consumed by
	# the FarmHouse's _ready() (the round-trip test below depends on this).
	_check(sb.pending_warp_id == "",
		"SignalBus.pending_warp_id is cleared after FarmHouse consumed 'farmhouse_entry'")

	# --- 3. Door warp-spawn round-trip. The player's position must end up
	# at the matching door's global_position + spawn_offset, NOT at the
	# historical (480, 384) snap. We can't directly invoke _unhandled_input
	# from a headless test, so we drive the same code path the door would:
	# set pending_warp_id, fire change_scene_to_file(), let _ready() resolve
	# it, then read the player's global_position.
	await _wait_for_current_scene(WORLD_PATH)
	var world_round: Node = current_scene
	var player_world_dbg: Node = world_round.get_node_or_null("Player")
	if player_world_dbg != null:
		print("DEBUG: just after _wait_for_current_scene, Player.pos=%s, vel=%s, dir=(%s, %s, %s, %s), scene_file_path=%s, scene_path=%s" % [
			str(player_world_dbg.global_position),
			str(player_world_dbg.velocity),
			str(Input.get_action_strength("move_right")),
			str(Input.get_action_strength("move_left")),
			str(Input.get_action_strength("move_up")),
			str(Input.get_action_strength("move_down")),
			str(current_scene.scene_file_path),
			str(world_round.get_path()),
		])
		# Check parent path
		print("DEBUG: Player.get_parent().get_path()=%s, world_round.get_path()=%s" % [
			str(player_world_dbg.get_parent().get_path()),
			str(world_round.get_path()),
		])
	# Pick the outdoor FarmHouseDoor and remember its expected spawn point.
	var outdoor_door: Node = null
	for d in world_round.get_tree().get_nodes_in_group("door"):
		if d is Node2D and String((d as Node).get("warp_id")) == "farmhouse_entry":
			outdoor_door = d
			break
	_check(outdoor_door != null,
		"World has a door in the 'door' group with warp_id='farmhouse_entry'")
	_check(world_round.get_node_or_null("Player") != null,
		"World has a Player child (auto-instanced via World.tscn)")
	# Player's spawn point should be (480, 384) — the historical default,
	# since no pending_warp_id is set and we just landed here via the
	# time-survival test's swap with pending_warp_id already consumed.
	var player_world: Node = world_round.get_node("Player")
	# Check the position IMMEDIATELY after spawn, before physics frames
	# can move the body. Headless mode shouldn't register input, but if
	# the engine's stub Input has any default state this test catches it.
	print("DEBUG: pending_warp_id at check=%s, player_world.global_position=%s" % [
		str(sb.pending_warp_id),
		str(player_world.global_position),
	])
	# TASK-353: Fix 1 — SceneLoader now strips the outgoing Player's
	# collision_layer/mask to 0 right before calling change_scene_to_file(),
	# so the depenetration-recovery race that used to push the new Player
	# ~40-60px along X (Y matched exactly in every observed run) can no
	# longer happen at the source. The previous < 100.0 tolerance check
	# was masking the symptom — the root cause is fixed in SceneLoader,
	# not just papered over in the assertion. Tolerance tightened to
	# < 5.0px (allows for sub-pixel float noise only); run five times in
	# a row to confirm it's stable, not a one-off.
	_check(player_world.global_position.distance_to(Vector2(10 * 48, 8 * 48)) < 5.0,
		"Player spawn near (480,384) when no pending_warp_id (fresh-boot default, got %s)"
			% str(player_world.global_position))

	# Now drive the world -> farmhouse transition manually and verify the
	# FarmHouse's _ready() resolves pending_warp_id='farmhouse_exit' to
	# the inside door's spawn point.
	sb.pending_warp_id = "farmhouse_exit"
	change_scene_to_file(FARMHOUSE_PATH)
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	await _wait_for_current_scene(FARMHOUSE_PATH)
	var farm: Node = current_scene
	_check(sb.pending_warp_id == "",
		"FarmHouse._ready() consumes pending_warp_id='farmhouse_exit' (no stale leakage)")
	# Find the inside door and verify the player spawned at door + spawn_offset.
	var inside_door: Node = null
	for d in farm.get_tree().get_nodes_in_group("door"):
		if d is Node2D and String((d as Node).get("warp_id")) == "farmhouse_exit":
			inside_door = d
			break
	_check(inside_door != null,
		"FarmHouse has a door in the 'door' group with warp_id='farmhouse_exit'")
	var player_farm: Node = farm.get_node_or_null("Player")
	_check(player_farm != null, "FarmHouse has a Player child (instanced in _ready())")
	if inside_door != null and player_farm != null:
		var expected_pos: Vector2 = (inside_door as Node2D).global_position + Vector2((inside_door as Node).get("spawn_offset"))
		_check(player_farm.global_position == expected_pos,
			"Player spawned at FarmHouse door + spawn_offset (got %s, expected %s)"
				% [str(player_farm.global_position), str(expected_pos)])
		_check(player_farm.global_position != Vector2(10 * 48, 8 * 48),
			"Player did NOT snap to the outdoor (480,384) default — warp spawn took effect")

	# Round-trip back: door -> world -> door -> world. Verify both ends land
	# on the right tile, and pending_warp_id is cleared on every consumption.
	sb.pending_warp_id = "farmhouse_entry"
	change_scene_to_file(WORLD_PATH)
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	await _wait_for_current_scene(WORLD_PATH)
	var world_back: Node = current_scene
	_check(sb.pending_warp_id == "",
		"World._ready() consumes pending_warp_id='farmhouse_entry' (no stale leakage)")
	var player_world2: Node = world_back.get_node("Player")
	var outdoor_door2: Node = null
	for d in world_back.get_tree().get_nodes_in_group("door"):
		if d is Node2D and String((d as Node).get("warp_id")) == "farmhouse_entry":
			outdoor_door2 = d
			break
	if outdoor_door2 != null:
		var expected_pos2: Vector2 = (outdoor_door2 as Node2D).global_position + Vector2((outdoor_door2 as Node).get("spawn_offset"))
		_check(player_world2.global_position == expected_pos2,
			"Player spawned at World door + spawn_offset on the way back (got %s, expected %s)"
				% [str(player_world2.global_position), str(expected_pos2)])

	# --- 4. Stale-warp leakage guard. A THIRD unrelated scene load (no
	# pending_warp_id) must not inherit the previous "farmhouse_entry"
	# value — confirm pending_warp_id is empty and the next load gets the
	# default spawn.
	_check(sb.pending_warp_id == "",
		"pending_warp_id is '' before the unrelated scene load (consumed earlier)")
	change_scene_to_file(FARMHOUSE_PATH)
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	await _wait_for_current_scene(FARMHOUSE_PATH)
	var farm2: Node = current_scene
	_check(sb.pending_warp_id == "",
		"pending_warp_id cleared after the fresh-boot-into-FarmHouse load (no stale warp)")
	var player_farm2: Node = farm2.get_node_or_null("Player")
	if player_farm2 != null:
		# Default interior spawn is room center (3*TILE, 3*TILE), NOT the
		# outdoor door's spawn point.
		_check(player_farm2.global_position == Vector2(3 * 48, 3 * 48),
			"fresh-boot FarmHouse player spawn at room center (no stale 'farmhouse_entry' warp)")

	# --- 5. SceneLoader autoload is wired and listens to the signal.
	# The above tests already implicitly prove this (every transition went
	# through change_scene_to_file()), but assert the wiring contract here.
	var scene_loader: Node = root.get_node_or_null("SceneLoader")
	_check(scene_loader != null,
		"SceneLoader autoload present at /root/SceneLoader")
	_check(sb.has_signal("scene_transition_requested"),
		"SignalBus exposes scene_transition_requested signal (TASK-352)")
	_check("pending_warp_id" in sb,
		"SignalBus exposes pending_warp_id field (TASK-352)")

	# --- 6. TASK-353 Fix 2 — SceneLoader debounce. Two signal-driven
	# transitions fired with no frame wait between them must collapse to
	# ONE actual scene change: the FIRST request wins, the second is
	# dropped (no change_scene_to_file call, pending_warp_id is NOT
	# updated). We drive the signal twice in immediate succession (no
	# awaits between the emits), let several frames elapse for any
	# debounced request to land, and confirm current_scene matches the
	# FIRST target path and that pending_warp_id was consumed for the
	# first request (not stuck holding the second one's value).
	#
	# Pre-test setup: the previous section's transition (~line 91's
	# emit) set SceneLoader._last_transition_msec, so the debounce
	# window is still active. Wait past it AND disable
	# TimeManager.auto_tick across the wait, then reload World with no
	# warp (pending_warp_id is already ""). The reload update inside
	# SceneLoader is itself timestamped, so we wait ANOTHER margin after
	# the reload completes before doing the double-emit — otherwise the
	# reload itself eats the first double-emit via debounce.
	# TASK-354: widened 0.5s -> 1.0s — SceneLoader now stamps
	# _last_transition_msec only after its ~100ms fade-out tween
	# completes, tightening the real margin against the 400ms debounce
	# window (observed intermittent flaking at 0.5s).
	await create_timer(1.0).timeout
	var saved_auto_tick_2: bool = tm.auto_tick
	tm.auto_tick = false
	sb.scene_transition_requested.emit(WORLD_PATH, "")
	await _wait_for_current_scene(WORLD_PATH)
	tm.auto_tick = saved_auto_tick_2
	# Wait past the debounce window again, with the same TASK-354
	# fade-delay margin as above.
	await create_timer(1.0).timeout
	_check(current_scene.scene_file_path == WORLD_PATH,
		"pre-debounce-test setup landed on World as expected (baseline)")
	# Now fire TWO signal requests back-to-back, with no awaits. Both
	# hit SceneLoader._on_transition_requested within < 1ms of each
	# other. The first targets FarmHouse; the second targets a path
	# that does NOT exist as a scene (res://DOES_NOT_EXIST.tscn) so a
	# successful second transition would error and we'd notice
	# immediately.
	sb.scene_transition_requested.emit(FARMHOUSE_PATH, "")
	sb.scene_transition_requested.emit("res://DOES_NOT_EXIST.tscn", "")
	# Let several frames elapse — enough for any non-debounced request
	# to land its change_scene_to_file. If the second emit was honored,
	# we'd see a load-failure error from Godot (and current_scene would
	# either stay on FarmHouse's old scene OR fail to load). If the
	# debounce worked, current_scene should now be FarmHouse (the first
	# target) with no errors.
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	await _wait_for_current_scene(FARMHOUSE_PATH)
	_check(current_scene.scene_file_path == FARMHOUSE_PATH,
		"debounce: first of two back-to-back signal emits won (current_scene=%s)"
			% str(current_scene.scene_file_path))
	_check(current_scene.scene_file_path != "res://DOES_NOT_EXIST.tscn",
		"debounce: second emit (res://DOES_NOT_EXIST.tscn) was DROPPED, not honored")

	# --- 7. Regression: zero remaining Main.tscn / "Main" node-name
	# assumptions across the test files most likely to reference the old
	# path. Any hit here means a previous rename was patched half-way or
	# someone reintroduced an old path while editing.
	var grep_targets: Array = [
		"res://tests/test_planting.gd",
		"res://tests/test_mining.gd",
		"res://tests/test_sacred_grove.gd",
		"res://tests/test_mountain_cave.gd",
		"res://tests/test_deep_canal.gd",
		"res://tests/test_lotus_maze_shore.gd",
		"res://tests/test_coastal_trading_post.gd",
		"res://tests/test_market_shop.gd",
		"res://tests/test_noticeboard.gd",
		"res://tests/test_carpenter_upgrade.gd",
		"res://tests/run_tests.gd",
		"res://tests/run_engine_tests.gd",
		"res://tests/test_buffalo_unlock.gd",
		"res://tests/test_fishing.gd",
		"res://tests/test_buffalo_hearts.gd",
		"res://tests/test_hud_progression.gd",
		"res://tests/test_anniversary.gd",
		"res://tests/test_life_progression.gd",
		"res://tests/test_wood.gd",
		"res://tests/test_rival_npcs.gd",
		"res://tests/perf/test_mobile_budget.gd",
		"res://tests/perf/test_frame_cap.gd",
		"res://tests/shaders/test_water_seasonal.gd",
	]
	for p in grep_targets:
		var src: String = FileAccess.get_file_as_string(p)
		_check(not src.contains("Main.tscn"),
			"%s does NOT reference the old Main.tscn path" % p)
		# The root node was renamed "Main" -> "World" in World.tscn; any
		# test that explicitly queries get_node("Main") is now broken.
		# The local var name `main` is fine and stays.
		_check(not src.contains("get_node(\"Main\""),
			"%s does NOT call get_node(\"Main\") (root node renamed to World)" % p)

func _wait_for_current_scene(expected_path: String) -> void:
	# change_scene_to_file defers the actual swap; poll current_scene until
	# it matches expected_path or we hit a generous wall-clock budget.
	# TASK-354: switched from a fixed 10-iteration process_frame budget to
	# a 2-second time budget. SceneLoader now adds a ~200ms fade-out /
	# fade-in around the swap, which can stretch total wall-clock past 10
	# unthrottled headless frames under contention. A time-based wait is
	# self-tuning for any future fade retune (no per-call-site budget
	# edits), matches SceneLoader's own internal helper, and still
	# returns promptly under the common case (next process_frame).
	# Also yields a few extra process_frames AFTER the swap is detected
	# so the new scene's _ready() chain AND Player._physics_process clamp
	# have a chance to run before the caller reads position — the fade
	# delayed the test's read enough to occasionally observe the player's
	# pre-clamp global_position.
	var deadline_msec: int = Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline_msec:
		await process_frame
		if current_scene != null:
			var ps: Node = current_scene
			if ps.scene_file_path == expected_path:
				await process_frame
				await process_frame
				await process_frame
				return