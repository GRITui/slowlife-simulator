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

	# TASK-349: level defaults to 0 so callers without a level arg
	# (MonkNPC.gd, any older test) are unaffected.
	var no_level_line: String = db.get_seasonal_line("elder", "cool", false, 0)
	_check(not no_level_line.is_empty(),
		"get_seasonal_line still works with no level arg (defaults to 0)")

	# TASK-349: level < 6 must never fire high_affiliation, regardless of
	# hint_roll. Sweep several roll values at level 5 (just under) and
	# confirm every result is in the season pool, not high_affiliation.
	var high_pool: Array = (db.DIALOGUE["elder"] as Dictionary)["high_affiliation"] as Array
	_check(not high_pool.is_empty(),
		"elder has a high_affiliation pool defined (TASK-349)")
	for roll in range(0, 10):
		var lvl5_line: String = db.get_seasonal_line("elder", "cool", false, roll, "clear", 5)
		_check(not high_pool.has(lvl5_line),
			"level 5 (below 6): roll %d never returns a high_affiliation line" % roll)

	# TASK-349: level >= 6 with a favorable hint_roll (roll % 5 < 2, same
	# convention as the rain branch) returns a high_affiliation line,
	# distinct from the season pool.
	var lvl6_fav_line: String = db.get_seasonal_line("elder", "cool", false, 1, "clear", 6)
	_check(high_pool.has(lvl6_fav_line),
		"level 6, roll 1 (favorable): returns a high_affiliation line")
	_check(not season_pool.has(lvl6_fav_line),
		"high_affiliation line is distinct from the cool season pool")

	# Same favorable roll at level 10 still fires high_affiliation.
	var lvl10_fav_line: String = db.get_seasonal_line("elder", "cool", false, 1, "clear", 10)
	_check(high_pool.has(lvl10_fav_line),
		"level 10, roll 1 (favorable, clear): still returns a high_affiliation line")

	# Unfavorable roll at level 10 falls through to the season pool —
	# high_affiliation is ~40% chance, not a hard override. Roll must
	# avoid BOTH hint (roll%3!=0) and high (roll%5>=2) — roll 2 satisfies
	# both (2%3=2, 2%5=2). Roll 3 is favorable for hint, so cannot be used
	# here (hint would intercept even at level 10).
	var lvl10_unfav_line: String = db.get_seasonal_line("elder", "cool", false, 2, "clear", 10)
	_check(season_pool.has(lvl10_unfav_line),
		"level 10, roll 2 (unfavorable): falls through to season pool")

	# TASK-349: existing priority branches outrank high_affiliation even at
	# level 10. binthabat_done (roll 0 is favorable for done %2==0 AND
	# high %5<2 — but done runs first).
	var lvl10_done_line: String = db.get_seasonal_line("elder", "cool", true, 0, "clear", 10)
	_check(done_pool.has(lvl10_done_line),
		"level 10: binthabat_done still outranks high_affiliation")

	# binthabat_hint (false-bin + roll%3==0). roll 0: 0%3==0 (hint) and
	# 0%5<2 (high also favorable) — confirms hint takes priority over high
	# even when both would fire, isolating ordering rather than trigger
	# inequality.
	var lvl10_hint_line: String = db.get_seasonal_line("elder", "cool", false, 0, "clear", 10)
	var hint_pool: Array = (db.DIALOGUE["elder"] as Dictionary)["binthabat_hint"] as Array
	_check(hint_pool.has(lvl10_hint_line),
		"level 10: binthabat_hint still outranks high_affiliation")

	# rain outranks high_affiliation at level 10.
	var lvl10_rain_line: String = db.get_seasonal_line("elder", "cool", false, 1, "rain", 10)
	_check(rain_pool.has(lvl10_rain_line),
		"level 10: rain still outranks high_affiliation")

	# TASK-349: graceful fallback for a villager with no high_affiliation
	# pool. "monk" is a real, known npc with a season pool but no
	# high_affiliation pool — branch enters (level >= 6), finds the pool
	# empty, and falls through to the existing season fallback.
	var monk_season_line: String = db.get_seasonal_line("monk", "cool", false, 1, "clear", 10)
	var monk_pool: Array = (db.DIALOGUE["monk"] as Dictionary)["cool"] as Array
	_check(monk_pool.has(monk_season_line),
		"npc without high_affiliation pool falls through to season at level 10")

	print("\n=== WEATHER-DIALOGUE TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("WEATHER-DIALOGUE GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
