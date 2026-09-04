extends SceneTree
# TASK-378: Unified completion tracker tests (perfection % / checklist screen)
# Tests the percentage/category computation logic and UI screen behavior.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  completion-tracker :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  completion-tracker :: %s" % label)

func _run_tests() -> void:
	# Setup test data
	var gd: Node = root.get_node_or_null("GameData") as GameData
	var hud: Node = root.get_node_or_null("HUD") as CanvasLayer
	_check(gd != null, "GameData autoload present")
	_check(hud != null, "HUD present")
	
	# Test 1: completion_percentage static method exists
	_check(gd.has_method("completion_percentage"), "GameData has completion_percentage()")
	
	# Test 2: completion_percentage returns 0 when no progress
	var percent: float = gd.completion_percentage()
	_check(percent == 0.0, "completion_percentage() returns 0 when no progress")
	
	# Test 3: milestones earned category
	gd.milestones_earned["deep_miner"] = true
	gd.milestones_earned["master_angler"] = true
	gd.milestones_earned["inseparable"] = true
	gd.milestones_earned["herd_keeper"] = true
	gd.milestones_earned["storm_catch"] = true
	percent = gd.completion_percentage()
	_check(percent > 0.0, "completion_percentage() increases when milestones earned")
	_check(percent <= 16.666, "completion_percentage() <= 16.67% for milestones only")  # 1/6 = 16.67%
	
	# Test 4: fish almanac category
	var fish_entry: Dictionary = {}
	fish_entry["species"] = "test_fish"
	fish_entry["size"] = {"width": 1, "height": 1, "harmony_value": 1}
	gd.fish_almanac[Json.stringify(fish_entry)] = true
	percent = gd.completion_percentage()
	_check(percent > 16.666, "completion_percentage() increases when fish almanac has entries")
	_check(percent <= 33.333, "completion_percentage() <= 33.33% for milestones+fish almanac")  # 2/6 = 33.33%
	
	# Test 5: recipe unlocks category
	gd.recipe_unlocks["test_recipe"] = true
	percent = gd.completion_percentage()
	_check(percent > 33.333, "completion_percentage() increases when recipe unlocks has entries")
	_check(percent <= 50.0, "completion_percentage() <= 50% for milestones+fish almanac+recipe_unlocks")  # 3/6 = 50%
	
	# Test 6: decor choices category
	gd.decor_choices["shrine"] = {"default": "plain", "styles": {"ornate": "ornate_shrine"}}
	percent = gd.completion_percentage()
	_check(percent > 50.0, "completion_percentage() increases when decor_choices has entries")
	_check(percent <= 66.666, "completion_percentage() <= 66.67% for milestones+fish almanac+recipe_unlocks+decor_choices")  # 4/6 = 66.67%
	
	# Test 7: romance spouse category
	gd.spouse = "ek"
	percent = gd.completion_percentage()
	_check(percent > 66.666, "completion_percentage() increases when spouse is set")
	_check(percent <= 83.333, "completion_percentage() <= 83.33% for milestones+fish almanac+recipe_unlocks+decor_choices+spouse")  # 5/6 = 83.33%
	
	# Test 8: romance candidates category
	gd.affinity["ek"] = 30  # Level 3 (30 affinity)
	percent = gd.completion_percentage()
	_check(percent > 83.333, "completion_percentage() increases when romance candidate has affinity >= 30")
	_check(percent <= 100.0, "completion_percentage() <= 100% for all categories")
		
	# Test 9: UI instantiation and display
	var tracker_scene: PackedScene = load("res://scenes/ui/CompletionTracker.tscn")
	_check(tracker_scene != null, "CompletionTracker.tscn loads successfully")
	
	var tracker: Node = tracker_scene.instantiate()
	_check(tracker != null, "CompletionTracker scene instantiates")
	_check(tracker.has_method("open"), "CompletionTracker has open() method")
	_check(tracker.has_method("close"), "CompletionTracker has close() method")
	
	# Test 10: HUD button wiring
	_check(hud.has_method("open_completion_tracker"), "HUD has open_completion_tracker() method")
	
print("\n=== COMPLETION TRACKER TESTS: %d passed, %d failed ===" % [_passed, _failed])

if _failed == 0:
	print("SUCCESS: All completion tracker tests passed!")
	quit(0)
else:
	print("FAILURE: Some completion tracker tests failed.")
	quit(1)

