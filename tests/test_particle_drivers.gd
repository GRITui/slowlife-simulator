extends SceneTree
# TASK-366 gate — RainDriver/HeatHazeDriver/LeafDriver actually wired into
# World.tscn as real nodes, and their effects actually toggle. Written
# because a real bug existed here: both scripts were complete and
# "fixed" but neither was ever instanced as a node anywhere, so the
# rain/haze effects never ran in a real session despite passing review.
# This test instances the real World.tscn (not just the driver script in
# isolation) specifically so a future regression of the same shape
# (script correct, node missing) fails loudly here.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  particle-drivers :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  particle-drivers :: %s" % label)

func _initialize() -> void:
	var sb: Node = root.get_node("SignalBus")
	var world: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	# --- RainDriver ---
	var rain_particles: Node = world.get_node_or_null("RainDriver/RainParticles")
	_check(rain_particles != null, "World.tscn has a real RainDriver/RainParticles node (not just the script)")
	if rain_particles != null:
		_check(rain_particles.emitting == false, "RainParticles starts NOT emitting (weather defaults to clear)")
		sb.weather_changed.emit("rain")
		await process_frame
		_check(rain_particles.emitting == true, "RainParticles.emitting becomes true on weather_changed('rain')")
		sb.weather_changed.emit("clear")
		await process_frame
		_check(rain_particles.emitting == false, "RainParticles.emitting becomes false on weather_changed('clear')")

	# --- HeatHazeDriver ---
	var haze_rect: Node = world.get_node_or_null("HazeLayer/HazeRect")
	_check(haze_rect != null, "World.tscn has a real HazeLayer/HazeRect node (not just the script)")
	if haze_rect != null:
		_check(haze_rect.visible == false, "HazeRect starts NOT visible (season defaults to cool)")
		sb.season_changed.emit("hot")
		await process_frame
		_check(haze_rect.visible == true, "HazeRect.visible becomes true on season_changed('hot')")
		sb.season_changed.emit("cool")
		await process_frame
		_check(haze_rect.visible == false, "HazeRect.visible becomes false on season_changed('cool')")

	# --- LeafDriver (always-on ambiance, no gating) ---
	var leaf_particles: Node = world.get_node_or_null("LeafDriver/LeafParticles")
	_check(leaf_particles != null, "World.tscn has a real LeafDriver/LeafParticles node")
	if leaf_particles != null:
		_check(leaf_particles.emitting == true, "LeafParticles is emitting immediately (always-on ambiance, no gate)")

	world.queue_free()
	await process_frame

	print("\n=== PARTICLE-DRIVERS TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("PARTICLE-DRIVERS GATE FAILED: %d failing checks" % _failed)
	quit(1 if _failed > 0 else 0)
