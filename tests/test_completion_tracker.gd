extends SceneTree
# TASK-378: Unified completion tracker tests (perfection % / checklist screen).
#
# Rewritten during Code Quality Review — the delegate's original file never
# actually ran: its closing block sat outside any function (GDScript parse
# error, "Unexpected identifier 'print' in class body"), and even the
# in-function logic was never invoked (no _initialize() override calling
# it). Also fixed: `Json.stringify(...)` (wrong case; and unnecessary --
# GameData.record_catch()'s real fish_almanac key format is a plain
# "species|size" string, not JSON) and the fact that the feature code
# itself (GameData.completion_percentage(), CompletionTracker.gd) failed
# to even compile — see those files' own fix history for details. This
# gate exists specifically to catch a regression of any of that.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  completion-tracker :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  completion-tracker :: %s" % label)

func _initialize() -> void:
	await _run_all()
	print("\n=== COMPLETION-TRACKER TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("COMPLETION-TRACKER GATE FAILED")
	quit(1 if _failed > 0 else 0)

func _run_all() -> void:
	var gd: Node = root.get_node("GameData")

	# Clean slate for this test run.
	gd.milestones_earned = {}
	gd.fish_almanac = {}
	gd.recipe_unlocks = {}
	gd.decor_choices = {}
	gd.spouse = ""
	gd.affinity = {}

	_check(gd.has_method("completion_percentage"), "GameData has completion_percentage()")
	_check(is_equal_approx(gd.completion_percentage(), 0.0),
		"completion_percentage() is 0%% with no progress")

	# --- Milestones: all-or-nothing (5 required for this one category) ---
	gd.milestones_earned["deep_miner"] = true
	_check(is_equal_approx(gd.completion_percentage(), 0.0),
		"partial milestones (1/5) do not count the category yet")
	for id in ["master_angler", "inseparable", "herd_keeper", "storm_catch"]:
		gd.milestones_earned[id] = true
	_check(is_equal_approx(gd.completion_percentage(), 100.0 / 6.0),
		"all 5 milestones complete the category (1/6 categories = %.2f%%)" % (100.0 / 6.0))

	# --- Fish almanac: any entry counts ---
	gd.fish_almanac["carp|small"] = true
	_check(is_equal_approx(gd.completion_percentage(), 200.0 / 6.0),
		"any fish_almanac entry completes that category (2/6)")

	# --- Recipe unlocks: any entry counts ---
	gd.recipe_unlocks["mango_sticky_rice"] = true
	_check(is_equal_approx(gd.completion_percentage(), 300.0 / 6.0),
		"any recipe_unlocks entry completes that category (3/6)")

	# --- Decor choices: any entry counts ---
	gd.decor_choices["shrine"] = "ornate"
	_check(is_equal_approx(gd.completion_percentage(), 400.0 / 6.0),
		"any decor_choices entry completes that category (4/6)")

	# --- Romance spouse ---
	gd.spouse = "ek"
	_check(is_equal_approx(gd.completion_percentage(), 500.0 / 6.0),
		"a set spouse completes that category (5/6)")

	# --- Romance candidates: at least one at level 5+ ---
	gd.affinity["ek"] = 90
	_check(gd.level_for(90) >= 5, "affinity 90 reaches level 5+ (sanity check on the real API)")
	_check(is_equal_approx(gd.completion_percentage(), 100.0),
		"at least one romanced candidate completes the final category (6/6 = 100%%)")

	# --- UI instantiation ---
	var tracker_scene: PackedScene = load("res://scenes/ui/CompletionTracker.tscn")
	_check(tracker_scene != null, "CompletionTracker.tscn loads")
	if tracker_scene == null:
		return
	var tracker: Node = tracker_scene.instantiate()
	root.add_child(tracker)
	await process_frame
	_check(tracker.has_method("open") and tracker.has_method("close"),
		"CompletionTracker has open()/close()")
	tracker.call("open")
	await process_frame
	_check(tracker.visible == true, "open() makes the tracker visible")
	tracker.call("close")
	await process_frame
	_check(tracker.visible == false, "close() hides the tracker again")
	tracker.queue_free()

	# --- HUD wiring ---
	var hud_scene: PackedScene = load("res://scenes/ui/HUD.tscn")
	var hud: Node = hud_scene.instantiate() if hud_scene else null
	if hud:
		root.add_child(hud)
		await process_frame
		_check(hud.has_method("open_completion_tracker"), "HUD has open_completion_tracker()")
		var button: Button = hud.get("completion_tracker_button")
		_check(button != null, "HUD's completion_tracker_button resolves to a real node (not just a script call target)")
		hud.queue_free()
