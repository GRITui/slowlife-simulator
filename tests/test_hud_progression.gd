extends SceneTree
# Phase 3 audit (2026-09-02) gate — companion_bond_changed signal + the
# FarmHeartsLabel/SkillsLabel HUD additions for previously-invisible
# progression (companion bond, chicken hearts/herd, fishing/mining skill).

var _passed: int = 0
var _failed: int = 0
var _bond_events: Array = []

func _on_bond(bond: int, tier: int) -> void:
	_bond_events.append([bond, tier])

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  hud-progression :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  hud-progression :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var sb: Node = root.get_node("SignalBus")
	sb.companion_bond_changed.connect(_on_bond)
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var hud: Node = main.get_node_or_null("HUD")
	_check(hud != null, "HUD present")
	if hud == null:
		await process_frame
		quit(1)
		return

	# --- init state: labels populated from GameData on _ready, no signal needed ---
	var farm_lbl: Label = hud.find_child("FarmHeartsLabel", true, false) as Label
	var skills_lbl: Label = hud.find_child("SkillsLabel", true, false) as Label
	_check(farm_lbl != null, "FarmHeartsLabel node exists")
	_check(skills_lbl != null, "SkillsLabel node exists")
	_check(farm_lbl != null and farm_lbl.text.contains("Chicken") and farm_lbl.text.contains("Cat"),
		"FarmHeartsLabel shows chicken + cat on init")
	_check(skills_lbl != null and skills_lbl.text.contains("Fish") and skills_lbl.text.contains("Mine"),
		"SkillsLabel shows fish + mine on init")

	# --- companion_bond_changed drives FarmHeartsLabel live ---
	var companion: Node = main.get_node_or_null("CompanionNPC")
	if companion != null:
		# TASK-348: one tick from tier 1 is now bond=9 (10/tier), was 24
		# (25/tier) in the legacy /25.0 era.
		gd.companion_bond = 9
		companion.call("_on_minute_ticked", 1, 6, 0)
		# BOND_MINUTES_PER_POINT is 60 nearby-minutes; drive enough ticks while
		# forcing distance to read as "within COMFORT" via direct state.
		companion.set("_nearby_minutes", 59)
		var player: Node = main.get_node_or_null("Player")
		if player != null:
			companion.global_position = (player as Node2D).global_position
		companion.call("_on_minute_ticked", 1, 6, 1)
		_check(int(gd.companion_bond) == 10, "companion_bond advanced to 10 (tier 1)")
		_check(_bond_events.size() >= 1, "companion_bond_changed emitted")
		if not _bond_events.is_empty():
			_check(_bond_events.back()[1] == 1, "companion_bond_changed reports tier 1")
		# TASK-348: HeartsLabel/FarmHeartsLabel switched from repeating "♥"
		# glyphs to a numeric "Lv N/10" format (see HUD.gd's
		# _on_farm_hearts_changed()) — the 0-10 scale would need up to 10
		# glyphs, too crowded for the compact HUD.
		_check(farm_lbl.text.contains("Lv 1/10"), "FarmHeartsLabel reflects cat bond live (Lv 1/10)")
	else:
		_check(false, "Companion node present (skip live-signal checks)")

	# --- skills label refresh piggybacks on minute_ticked ---
	gd.fishing_skill = 3
	gd.mining_skill = 2
	sb.minute_ticked.emit(1, 7, 0)
	_check(skills_lbl.text == "Skills: Fish Lv3 | Mine Lv2", "SkillsLabel refreshes on minute_ticked")

	sb.companion_bond_changed.disconnect(_on_bond)
	main.queue_free()
	print("\n=== HUD-PROGRESSION TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("HUD-PROGRESSION GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
