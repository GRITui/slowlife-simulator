extends SceneTree
# TASK-365 fog-driver gate. Verifies that the new FogDriver.gd node,
# authored as a real child of World.tscn (not just a script on disk —
# see TASK-366 for the orphan-bug class this guards against), actually
# toggles its sibling FogLayer/FogRect's `visible` property in response
# to SignalBus.weather_changed emissions.
#
# Three groups of checks:
#   A. Scene-tree wiring: FogLayer (CanvasLayer), FogRect (ColorRect),
#      and FogDriver (CanvasLayer + FogDriver.gd script) are present in
#      World at the documented locations. If World.tscn ever regresses
#      to author only the script without the nodes (TASK-366 pattern),
#      this section catches it before any signal-flow check runs.
#   B. Signal-flow: emitting weather_changed("fog") flips FogRect.visible
#      to true; emitting weather_changed("clear") and ("rain") flips it
#      back to false. Initial sync from TimeManager autoload already set
#      the baseline before these calls run (FogDriver._ready mirrors
#      RainDriver's initial-sync pattern from GameData.current_weather).
#   C. Color hygiene: the overlay's color alpha stays in the
#      "haze not wall" range (alpha < 0.3) the project established —
#      a regression that set it to 1.0 would silently hide the world
#      under fog even though the toggle still works.
#
# Follows the existing tests' `_check(cond, label)` convention (see
# tests/test_weather_dialogue.gd, tests/test_audio.gd). Runs directly
# against /root/SignalBus + an instantiated World scene, mirroring
# run_tests.gd's "main-boot" pattern.

const WORLD_PATH: String = "res://scenes/core/World.tscn"
const FOG_DRIVER_SCRIPT_PATH: String = "res://scenes/core/FogDriver.gd"

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  fog-driver :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  fog-driver :: %s" % label)

func _run_all() -> void:
	var sb: Node = root.get_node_or_null("SignalBus")
	var main_scene: PackedScene = load(WORLD_PATH)
	_check(main_scene != null, "World.tscn loads (PackedScene non-null)")
	var main: Node = (main_scene as PackedScene).instantiate() if main_scene else null
	if main == null:
		return
	root.add_child(main)
	# Two frames so the autoload TimeManager._ready() fires its initial
	# SignalBus.weather_changed.emit(current_weather) and FogDriver._ready
	# has consumed that initial sync before we start driving the signal
	# manually. Same pattern as run_tests.gd "main-boot" lines ~71-79.
	await process_frame
	await process_frame

	# --- A. Scene-tree wiring.
	var fog_layer: CanvasLayer = main.get_node_or_null("FogLayer") as CanvasLayer
	_check(fog_layer != null,
		"FogLayer (CanvasLayer) present in World")
	var fog_rect: ColorRect = (fog_layer.get_node_or_null("FogRect") as ColorRect) if fog_layer else null
	_check(fog_rect != null,
		"FogRect (ColorRect) present under FogLayer")
	var fog_driver: CanvasLayer = main.get_node_or_null("FogDriver") as CanvasLayer
	_check(fog_driver != null,
		"FogDriver (CanvasLayer) present in World")
	# Confirm the script is actually attached — catches the TASK-366
	# orphan-bug class where World.tscn is missing the `script =`
	# assignment for the driver.
	var fog_driver_script: GDScript = load(FOG_DRIVER_SCRIPT_PATH) as GDScript
	_check(fog_driver != null and fog_driver.get_script() == fog_driver_script,
		"FogDriver script is the real FogDriver.gd (not orphaned)")

	# --- B. Signal-flow.
	if sb and fog_rect:
		# Initial baseline: force a known state rather than trusting
		# TimeManager's _ready roll. TimeManager._roll_daily_weather()
		# uses real randf() (~25% fog chance in cool season) with no
		# fixed seed, so asserting on whatever it happened to roll at
		# boot is flaky by design — confirmed failing ~1/64 runs in
		# practice while landing TASK-368 (unrelated diff, same flake).
		sb.weather_changed.emit("clear")
		await process_frame
		_check(fog_rect.visible == false,
			"baseline FogRect.visible == false (forced weather='clear')")

		sb.weather_changed.emit("fog")
		await process_frame
		_check(fog_rect.visible == true,
			"weather_changed.emit('fog') sets FogRect.visible == true")

		# A second fog emission must remain visible (no flicker).
		sb.weather_changed.emit("fog")
		await process_frame
		_check(fog_rect.visible == true,
			"weather_changed.emit('fog') twice still leaves FogRect visible")

		# Non-fog weathers must NOT show the overlay. Cover 'clear' and
		# 'rain' specifically because they're both real rolled values
		# (and 'rain' is the RainDriver's branch — confirming fog doesn't
		# cross-fire with rain).
		sb.weather_changed.emit("clear")
		await process_frame
		_check(fog_rect.visible == false,
			"weather_changed.emit('clear') clears FogRect")

		sb.weather_changed.emit("rain")
		await process_frame
		_check(fog_rect.visible == false,
			"weather_changed.emit('rain') does NOT show fog (no cross-fire)")

		sb.weather_changed.emit("overcast")
		await process_frame
		_check(fog_rect.visible == false,
			"weather_changed.emit('overcast') does NOT show fog")

		# Re-arm: one more fog emission must turn it on again — the driver
		# is idempotent, not sticky-off after a clear.
		sb.weather_changed.emit("fog")
		await process_frame
		_check(fog_rect.visible == true,
			"weather_changed.emit('fog') re-arms after a clear")

	# --- C. Color hygiene.
	if fog_rect:
		var c: Color = fog_rect.color
		# Project convention is "haze not wall" — Task-365 brief called
		# out the existing precedent (TintLayer alpha 0.078) and warned
		# against full-opacity. Alpha must stay below the cozy limit.
		_check(c.a > 0.0 and c.a < 0.3,
			"FogRect.color.alpha is in haze range (0, 0.3) (got %.3f)" % c.a)
		# mouse_filter == IGNORE so the overlay never blocks input.
		_check(fog_rect.mouse_filter == Control.MOUSE_FILTER_IGNORE,
			"FogRect.mouse_filter is IGNORE (never blocks input)")
		# Rect should be full-screen so the haze covers the whole view.
		_check(fog_rect.anchor_right == 1.0 and fog_rect.anchor_bottom == 1.0,
			"FogRect anchored full-screen (anchor_right/bottom == 1.0)")

	main.queue_free()

func _initialize() -> void:
	await _run_all()
	print("\n=== FOG-DRIVER TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("FOG-DRIVER GATE FAILED")
	quit(1 if _failed > 0 else 0)