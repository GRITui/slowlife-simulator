extends SceneTree
# TASK-369 gate — FestivalVisualDriver's PondGlow/FestivalLanterns were
# complete, correct scripts that were never actually instanced as nodes
# in World.tscn (same orphan-wiring class as TASK-366). This test
# instances the real World.tscn and drives SignalBus.festival_triggered
# to confirm the glow/lanterns actually toggle — not just that the
# script exists.
#
# Found and fixed while reviewing the delegate's own fix for this exact
# bug class: the delegate added the PondGlowLayer/PondGlowRect and
# FestivalLanterns effect nodes correctly, but never actually instanced
# a FestivalVisualDriver node with the script attached (reproducing the
# very bug class it was dispatched to fix), left a duplicate ext_resource
# declaration, and set PondGlowRect's alpha to 0.7 -- a near-opaque
# overlay, far outside this project's established "haze not wall"
# convention (TintLayer 0.078, HazeRect 0.08, FogRect 0.12) -- corrected
# to 0.12 to match FogRect's precedent.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  festival-visual-driver :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  festival-visual-driver :: %s" % label)

func _initialize() -> void:
	var sb: Node = root.get_node("SignalBus")
	var world: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	# --- A. Scene-tree wiring ---
	var driver: CanvasLayer = world.get_node_or_null("FestivalVisualDriver") as CanvasLayer
	_check(driver != null, "World.tscn has a real FestivalVisualDriver node (not just the script)")

	var glow: ColorRect = world.get_node_or_null("PondGlowLayer/PondGlowRect") as ColorRect
	_check(glow != null, "World.tscn has a real PondGlowLayer/PondGlowRect node")

	var lanterns: GPUParticles2D = world.get_node_or_null("WorldRender/FestivalLanterns") as GPUParticles2D
	_check(lanterns != null, "World.tscn has a real WorldRender/FestivalLanterns node")

	if driver == null or glow == null or lanterns == null:
		world.queue_free()
		print("\n=== FESTIVAL-VISUAL-DRIVER TESTS: %d passed, %d failed ===" % [_passed, _failed])
		quit(1)
		return

	# --- B. Color hygiene: "haze not wall" convention ---
	_check(glow.color.a > 0.0 and glow.color.a < 0.3,
		"PondGlowRect.color.alpha is in haze range (0, 0.3) (got %.3f)" % glow.color.a)

	# --- C. Signal-flow ---
	_check(glow.visible == false, "PondGlowRect starts hidden")
	_check(lanterns.emitting == false, "FestivalLanterns starts not emitting")

	sb.festival_triggered.emit("Songkran")
	await process_frame
	_check(glow.visible == true, "festival_triggered makes PondGlowRect visible")
	_check(lanterns.emitting == true, "festival_triggered makes FestivalLanterns emit")

	# --- D. Auto-hide (drive the timer's own timeout callback directly
	# rather than waiting 30 real seconds in a headless test). ---
	driver.call("_on_hide_timeout")
	await process_frame
	_check(glow.visible == false, "hide timeout hides PondGlowRect again")
	_check(lanterns.emitting == false, "hide timeout stops FestivalLanterns emitting")

	world.queue_free()
	print("\n=== FESTIVAL-VISUAL-DRIVER TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("FESTIVAL-VISUAL-DRIVER GATE FAILED")
	quit(1 if _failed > 0 else 0)
