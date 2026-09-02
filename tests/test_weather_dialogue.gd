extends SceneTree
# TASK-329 gate — weather branch on DialogueDB.get_seasonal_line().

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  weather-dialogue :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  weather-dialogue :: %s" % label)

func _initialize() -> void:
	var db: GDScript = load("res://scripts/narrative/DialogueDB.gd")

	# Weather defaults to "clear" — existing callers (no weather arg) unaffected.
	var clear_line: String = db.get_seasonal_line("elder", "cool", false, 0)
	_check(not clear_line.is_empty(), "get_seasonal_line still works with no weather arg")

	# With weather="rain" and hint_roll landing in the rain branch (roll % 5 < 2,
	# and roll 1 avoids the binthabat_hint branch which fires on roll % 3 == 0).
	var rain_line: String = db.get_seasonal_line("elder", "cool", false, 1, "rain")
	var rain_pool: Array = (db.DIALOGUE["elder"] as Dictionary)["rain"] as Array
	_check(rain_pool.has(rain_line), "roll 1 (in rain branch, not hint) returns an elder rain line")

	# roll 2 is outside the rain branch (2 % 5 == 2, not < 2) -> falls to season.
	var season_line: String = db.get_seasonal_line("elder", "cool", false, 2, "rain")
	var season_pool: Array = (db.DIALOGUE["elder"] as Dictionary)["cool"] as Array
	_check(season_pool.has(season_line), "roll 2 (outside rain branch) falls through to season pool")

	# binthabat_done still takes priority over rain.
	var binthabat_line: String = db.get_seasonal_line("elder", "cool", true, 0, "rain")
	var done_pool: Array = (db.DIALOGUE["elder"] as Dictionary)["binthabat_done"] as Array
	_check(done_pool.has(binthabat_line), "binthabat_done still outranks the rain branch")

	# Unknown npc_id stays the existing safe no-op regardless of weather.
	var unknown_line: String = db.get_seasonal_line("nobody", "cool", false, 0, "rain")
	_check(unknown_line == "...", "unknown npc_id stays a safe no-op with weather set")

	print("\n=== WEATHER-DIALOGUE TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("WEATHER-DIALOGUE GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
