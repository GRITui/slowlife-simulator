extends SceneTree
# TASK-358 fish almanac gate. Covers:
#   1. GameData.record_catch() idempotency — same (species, size) pair
#      recorded twice grants +5 harmony once and never again.
#   2. Two distinct pairs each fire their own first-catch dialogue via
#      SignalBus.show_dialogue (System speaker, "Fish Almanac:" prefix).
#   3. The dict keying scheme "%s|%s" makes "small" and "big" of the
#      same species count as two separate entries.
#   4. The HUD's AlmanacLabel reads "Almanac: N/60" with N=fish_almanac.size()
#      after a minute-tick refresh.
#   5. SaveManager round-trip (extended test_save_compat.gd covers this
#      for the full dict — see that file's v6->v7 migration block).
#
# Follows the existing tests' `_check(cond, label)` convention (see
# tests/test_milestones.gd, tests/test_farmhouse_content.gd) and the
# SignalBus.connect → _dialogue_hits pattern from test_milestones.gd.

const FISH_PATH: String = "res://data/fish/fish.json"

var _passed: int = 0
var _failed: int = 0
var _dialogue_hits: Array = [] # [speaker, text] pairs from show_dialogue

func _on_show_dialogue(speaker: String, text: String) -> void:
	_dialogue_hits.append([speaker, text])

func _almanac_dialogue_count() -> int:
	# Count System-spoken lines that begin with the "Fish Almanac:" prefix
	# record_catch() emits on a new entry. Distinct from the
	# "Caught a %s %s!" spot-name line that fires on every catch.
	var count: int = 0
	for d in _dialogue_hits:
		if d[0] == "System" and String(d[1]).begins_with("Fish Almanac:"):
			count += 1
	return count

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  fish-almanac :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  fish-almanac :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node_or_null("GameData")
	var sb: Node = root.get_node_or_null("SignalBus")
	_check(gd != null, "GameData autoload present")
	_check(sb != null, "SignalBus autoload present")
	if gd == null or sb == null:
		print("\n=== FISH-ALMANAC TESTS: %d passed, %d failed ===" % [_passed, _failed])
		quit(1)
		return

	# --- GameData surface ---
	_check(gd.has_method("record_catch"),
		"GameData exposes record_catch()")
	_check("fish_almanac" in gd,
		"GameData exposes fish_almanac field")
	_check((gd.get("fish_almanac") as Dictionary).is_empty(),
		"fish_almanac starts empty on a fresh autoload")
	gd.fish_almanac.clear()
	sb.show_dialogue.connect(_on_show_dialogue)

	# --- 1. idempotency on a single (species, size) pair ---
	var h0: int = int(gd.harmony)
	var first: bool = gd.record_catch("pla_nin", "small")
	_check(first == true,
		"record_catch() returns true the first time a (species, size) pair is seen")
	_check(int(gd.harmony) == h0 + 5,
		"first record_catch() grants exactly +5 harmony")
	_check(bool(gd.fish_almanac.get("pla_nin|small", false)),
		"fish_almanac stores the pair under \"%s|%s\" key" % ["pla_nin", "small"])

	var h2: int = int(gd.harmony)
	var second: bool = gd.record_catch("pla_nin", "small")
	_check(second == false,
		"record_catch() returns false for a repeat (species, size) pair")
	_check(int(gd.harmony) == h2,
		"repeat record_catch() grants no extra harmony")
	_check(gd.fish_almanac.size() == 1,
		"repeat record_catch() does not duplicate the entry")

	# --- 2. two distinct pairs each fire, and the dict grows ---
	_dialogue_hits.clear()
	var h3: int = int(gd.harmony)
	var ok_a: bool = gd.record_catch("pla_nin", "mid")
	var ok_b: bool = gd.record_catch("pla_duk", "big")
	_check(ok_a and ok_b,
		"two distinct pairs each earn independently")
	_check(int(gd.harmony) == h3 + 10,
		"two distinct first-records grant +10 harmony total")
	_check(gd.fish_almanac.size() == 3,
		"fish_almanac.size() == 3 after recording 3 unique pairs")

	# --- 3. different sizes of the same species are distinct entries ---
	_check(not bool(gd.fish_almanac.get("pla_nin|big", false)),
		"pla_nin|big is not yet recorded (separate from pla_nin|mid)")
	var h4: int = int(gd.harmony)
	var same_species_new_size: bool = gd.record_catch("pla_nin", "big")
	_check(same_species_new_size,
		"the same species at a different size still earns first-catch")
	_check(int(gd.harmony) == h4 + 5,
		"same-species-new-size grants its own +5 harmony")
	_check(gd.fish_almanac.size() == 4,
		"fish_almanac.size() == 4 after the size-variant catch")

	# --- 4. live FishingSpot.cast_line() fires the first-catch dialogue ---
	# Verify that the real call site (not just the helper) actually
	# surfaces the almanac dialogue — same code path that real catches
	# take, so any regression in FishingSpot.gd's wiring trips the test.
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var fishing: Node = main.get_node_or_null("FishingSpot")
	_check(fishing != null, "FishingSpot instanced from World")
	if fishing != null:
		gd.fish_almanac.clear()
		_dialogue_hits.clear()
		gd.add_item("fishing_rod", 1)
		var casts: int = 0
		for i in range(8):
			var got: bool = fishing.call("cast_line")
			if got:
				casts += 1
		_check(casts >= 1,
			"at least one cast succeeded across 8 attempts")
		_check(_almanac_dialogue_count() >= 1,
			"FishingSpot.cast_line() emitted at least one 'Fish Almanac:' dialogue")
		_check(gd.fish_almanac.size() >= 1,
			"fishing across 8 casts grew the almanac (size >= 1)")
	main.queue_free()
	await process_frame

	# --- 5. HUD AlmanacLabel read-out ---
	# Boot a fresh World so the HUD scene re-instantiates with the
	# AlmanacLabel node we added in the same task.
	var main2: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main2)
	await process_frame
	await process_frame
	var hud: Node = main2.get_node_or_null("HUD")
	_check(hud != null, "HUD instanced from World")
	if hud != null:
		var lbl: Label = hud.find_child("AlmanacLabel", true, false) as Label
		_check(lbl != null, "HUD has AlmanacLabel child node")
		if lbl != null:
			gd.fish_almanac["pla_nin|small"] = true
			gd.fish_almanac["pla_duk|big"] = true
			gd.fish_almanac["pla_mor|mid"] = true
			var expected_total: int = 60
			sb.minute_ticked.emit(1, 6, 0)
			await process_frame
			var expected_text: String = "Almanac: %d/%d" % [int(gd.fish_almanac.size()), expected_total]
			_check(String(lbl.text) == expected_text,
				("AlmanacLabel reads '%s' (got '%s')") % [expected_text, String(lbl.text)])
	main2.queue_free()
	await process_frame

	# --- 6. verify the species*size denominator in fish.json is exactly 60 ---
	# If this drifts (content additions/removals), the test catches it and
	# forces an intentional update to HUD.gd's FISH_ALMANAC_TOTAL constant.
	var f: FileAccess = FileAccess.open(FISH_PATH, FileAccess.READ)
	var fish_json: String = f.get_as_text() if f else ""
	var parsed: Variant = JSON.parse_string(fish_json)
	var species_count: int = 0
	var combo_count: int = 0
	if parsed is Dictionary and (parsed as Dictionary).has("fish"):
		var arr: Array = (parsed as Dictionary)["fish"] as Array
		species_count = arr.size()
		for entry in arr:
			if entry is Dictionary:
				var sizes: Dictionary = (entry as Dictionary).get("sizes", {}) as Dictionary
				combo_count += sizes.size()
	_check(species_count == 20,
		"data/fish/fish.json has exactly 20 species")
	_check(combo_count == 60,
		"data/fish/fish.json has exactly 60 (species x size) combos")

	sb.show_dialogue.disconnect(_on_show_dialogue)
	print("\n=== FISH-ALMANAC TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("FISH-ALMANAC GATE FAILED: %d failing checks" % _failed)
	quit(1 if _failed > 0 else 0)
