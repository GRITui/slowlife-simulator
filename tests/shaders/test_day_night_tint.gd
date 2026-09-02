extends SceneTree
# TASK-034 day/night tint gate. This shader has now shipped the SAME class
# of bug twice — an alpha formula that reads as "fade to transparent
# during the day" but actually evaluates to (or stays near) fully opaque
# for large stretches of the cycle, turning a subtle screen-grade overlay
# into a solid wall hiding the whole game world. Godot's headless RD
# cannot rasterize canvas-item fragment shaders (see
# tests/shaders/test_water_seasonal.gd's own note on this), so this test
# mirrors the shader's exact alpha/color formula in GDScript and sweeps
# every hour of the day, asserting alpha never approaches opaque. This is
# a math-contract test: if the .gdshader's formula changes, this file's
# mirrored copy must be updated to match, or it will (correctly) start
# failing to warn that the two have drifted apart.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  day-night-tint :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  day-night-tint :: %s" % label)

const GRADE_STRENGTH: float = 0.22

## Mirrors assets/shaders/day_night_tint.gdshader's fragment() math exactly.
## Returns the alpha (== blend strength) the overlay renders at for a given
## day_fraction (0.0 = midnight, 0.5 = noon).
func _shader_alpha(day_fraction: float) -> float:
	var dawn_w: float = clampf(1.0 - absf(day_fraction - 0.25) * 18.0, 0.0, 1.0)
	var dusk_w: float = clampf(1.0 - absf(day_fraction - 0.78) * 18.0, 0.0, 1.0)
	var night_w: float = (1.0 if day_fraction >= 0.8125 else 0.0) + (1.0 if day_fraction < 0.208 else 0.0)
	night_w = clampf(night_w, 0.0, 1.0)
	return GRADE_STRENGTH * (dawn_w + dusk_w + night_w)

func _initialize() -> void:
	var shader: Shader = load("res://assets/shaders/day_night_tint.gdshader") as Shader
	_check(shader != null and shader.get_rid().is_valid(), "day_night_tint.gdshader compiles/loads")
	var mat: ShaderMaterial = load("res://assets/shaders/day_night_tint.tres") as ShaderMaterial
	_check(mat != null and mat.shader == shader, "day_night_tint ShaderMaterial bound to shader")

	# Sweep every hour (24 samples) plus the exact minutes this bug hit
	# hardest (full night hours and the dawn/dusk peaks). Regression bar:
	# alpha must never exceed a generous 0.4 ceiling anywhere in the cycle
	# (comfortably above the ~0.31 real peak where dusk/night briefly
	# overlap, comfortably below "hides the world").
	var worst_alpha: float = 0.0
	var worst_hour: float = 0.0
	for h in range(0, 24):
		var day_fraction: float = h / 24.0
		var alpha: float = _shader_alpha(day_fraction)
		if alpha > worst_alpha:
			worst_alpha = alpha
			worst_hour = h
		_check(alpha <= 0.4, "hour %02d:00 alpha stays subtle (got %.3f)" % [h, alpha])
	_check(worst_alpha < 1.0, "worst-case alpha across the full day (%.3f at hour %d) never approaches opaque" % [worst_alpha, worst_hour])

	# Specifically re-assert the two failure modes this bug has now taken:
	# (1) the original bug — permanently opaque regardless of time.
	_check(_shader_alpha(0.5) < 0.05, "noon (day_fraction=0.5) is near-invisible, not opaque")
	# (2) the second bug — opaque for the ENTIRE night stretch, not just a
	# brief transition instant. Sample deep night (02:00) and the exact
	# dawn peak (06:00, day_fraction=0.25) where the second bug's alpha
	# formula (1.0 - day_w) evaluated to a full 1.0.
	_check(_shader_alpha(2.0 / 24.0) < 0.4, "deep night (02:00) stays a subtle tint, not a solid wall")
	_check(_shader_alpha(6.0 / 24.0) < 0.4, "dawn peak (06:00) stays a subtle tint, not a solid wall")
	_check(_shader_alpha(19.0 / 24.0) < 0.4, "dusk (19:00) stays a subtle tint, not a solid wall")

	print("\n=== DAY-NIGHT-TINT TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("DAY-NIGHT-TINT GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
