extends SceneTree
# TASK-026 save compatibility gate — versioned schema + migration round-trip.
# Run: godot --headless --path . --script res://tests/test_save_compat.gd
# Exit 0 = green, 1 = failures. Additive to content/engine gates (run_gate.sh).
#
# Phase 3 audit (2026-09-02): extended to v3, which persists everything the
# audit found was previously silently dropped on every save/load cycle —
# tool tiers, skills, affinity/hearts, herd counts, quests, marriage,
# infrastructure. See scripts/persistence/SaveManager.gd's header comment.

const SaveManagerScript: GDScript = preload("res://scripts/persistence/SaveManager.gd")

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  save-compat :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  save-compat :: %s" % label)

func _initialize() -> void:
	var sm: Node = SaveManagerScript.new()

	# --- migrate(): v1 payload (floats from JSON, no version tag) ---
	var v1: Dictionary = {
		"player_pos": [480, 384],
		"inventory": {"rice_grain": 3.0, "krathong": 1.0},
		"harmony": 12.0,
		"season": "cool",
	}
	var m: Dictionary = sm.migrate(v1)
	_check(int(m.get("version", 0)) == 4, "migrate advances v1 all the way to version 4")
	var inv: Dictionary = m.get("inventory", {}) as Dictionary
	_check(inv.get("rice_grain") is int and int(inv["rice_grain"]) == 3,
		"migrate coerces inventory floats to int (rice_grain)")
	_check(inv.get("krathong") is int and int(inv["krathong"]) == 1,
		"migrate coerces inventory floats to int (krathong)")
	_check(m.get("harmony") is int and int(m["harmony"]) == 12, "migrate coerces harmony to int")
	_check(v1.get("inventory", {}).get("rice_grain") is float,
		"migrate does not mutate input payload")
	# v3 default-adds: a v1 save has none of these fields, so migrate must
	# supply every default so a v1 save loads like a fresh game for anything
	# that was never persisted before v3 (see SaveManager.gd's migrate()).
	_check(int(m.get("fishing_skill", -1)) == 1, "v1->v3 default-adds fishing_skill=1")
	_check(int(m.get("chicken_count", -1)) == 1, "v1->v3 default-adds chicken_count=1")
	_check((m.get("tool_tiers", {}) as Dictionary).get("hoe", 0) == 1,
		"v1->v3 default-adds tool_tiers with hoe=1")
	_check(bool(m.get("married", true)) == false, "v1->v3 default-adds married=false")
	_check((m.get("npc_first_met_day", {"x": 1}) as Dictionary).is_empty(), "v1->v4 default-adds npc_first_met_day={}")
	_check((m.get("lost_to_rival", {"x": 1}) as Dictionary).is_empty(), "v1->v4 default-adds lost_to_rival={}")
	_check((m.get("milestones_earned", {"x": 1}) as Dictionary).is_empty(), "v1->v4 default-adds milestones_earned={}")

	# --- migrate(): v1 without new v2 fields gets default-added ---
	var v1_no_krathong: Dictionary = {
		"player_pos": [480, 384],
		"inventory": {"rice_grain": 2.0},
		"harmony": 5.0,
		"season": "hot",
	}
	var mk: Dictionary = sm.migrate(v1_no_krathong)
	var invk: Dictionary = mk.get("inventory", {}) as Dictionary
	_check(invk.has("krathong") and int(invk["krathong"]) == 0,
		"migrate default-adds krathong=0 on v1 saves that lack it")

	# --- migrate(): a v2 payload (no v3 fields yet) advances to v3 with defaults ---
	var v2: Dictionary = {"version": 2, "inventory": {"mango": 2}, "harmony": 5, "season": "hot"}
	var m2: Dictionary = sm.migrate(v2)
	_check(int(m2.get("version", 0)) == 4, "migrate advances v2 payload to version 4")
	_check((m2.get("inventory", {}) as Dictionary).get("mango") == 2, "v2 inventory preserved")
	_check(int(m2.get("veteran_year", -1)) == 1, "v2->v3 default-adds veteran_year=1")
	_check(int(m2.get("married_year", -1)) == 0, "v2->v3 default-adds married_year=0")

	# --- migrate(): a v3 payload (no v4 fields yet) advances to v4 with defaults ---
	var v3: Dictionary = {"version": 3, "inventory": {"mango": 2}, "harmony": 5, "season": "hot",
		"fishing_skill": 3, "married": true, "spouse": "niran"}
	var m3: Dictionary = sm.migrate(v3)
	_check(int(m3.get("version", 0)) == 4, "migrate advances v3 payload to version 4")
	_check(int(m3.get("fishing_skill", 0)) == 3, "v3 fishing_skill preserved, not reset to default")
	_check(bool(m3.get("married", false)) == true and String(m3.get("spouse", "")) == "niran",
		"v3 marriage state preserved, not reset to default")
	_check((m3.get("npc_first_met_day", {"x": 1}) as Dictionary).is_empty(), "v3->v4 default-adds npc_first_met_day={}")

	# --- migrate(): already-v4 payload is a no-op pass-through ---
	var v4: Dictionary = {"version": 4, "inventory": {"mango": 2}, "harmony": 5, "season": "hot",
		"fishing_skill": 3, "married": true, "spouse": "niran",
		"lost_to_rival": {"fah": true}, "milestones_earned": {"deep_miner": true}}
	var m4: Dictionary = sm.migrate(v4)
	_check(int(m4.get("version", 0)) == 4, "migrate keeps version 4 payload")
	_check(bool((m4.get("lost_to_rival", {}) as Dictionary).get("fah", false)),
		"v4 lost_to_rival preserved, not reset to default")
	_check(bool((m4.get("milestones_earned", {}) as Dictionary).get("deep_miner", false)),
		"v4 milestones_earned preserved, not reset to default")

	# --- round-trip via real file IO (user://) ---
	var gd0: Node = root.get_node("GameData")
	gd0.add_item("rice_grain", 7)
	gd0.add_item("krathong", 1)
	gd0.harmony = 21
	# v3 fields: set a representative sample across every newly-persisted
	# category (skills, affinity/hearts, herd, tools, quests, marriage,
	# infrastructure) rather than every single field — proves the plumbing
	# works end-to-end without duplicating SaveManager's own field list here.
	gd0.max_stamina = 130.0
	gd0.current_stamina = 80.0
	gd0.fishing_skill = 3
	gd0.mining_skill = 2
	gd0.buffalo_affinity = 55
	gd0.chicken_count = 2
	gd0.tool_tiers["hoe"] = 3
	gd0.affinity["niran"] = 90
	gd0.active_quests["harvest_two_crop_types"] = {"stage": 1, "objectives_done": ["harvest_a"]}
	gd0.infrastructure["sluice_gate"] = true
	gd0.veteran_year = 2
	gd0.married = true
	gd0.spouse = "niran"
	gd0.married_year = 1
	gd0.child_stage = 2
	gd0.npc_first_met_day["fah"] = 5
	gd0.lost_to_rival["kiet"] = true
	gd0.rival_warning_shown["fah"] = 2
	gd0.milestones_earned["deep_miner"] = true
	var saved: bool = sm.save_game()
	_check(saved, "save_game() writes user://savegame.json")
	# Mutate state to defaults, then load must restore every field above.
	gd0.inventory.clear()
	gd0.harmony = 0
	gd0.max_stamina = 100.0
	gd0.current_stamina = 100.0
	gd0.fishing_skill = 1
	gd0.mining_skill = 1
	gd0.buffalo_affinity = 0
	gd0.chicken_count = 1
	gd0.tool_tiers = {"watering_can": 1, "hoe": 1, "sickle": 1}
	gd0.affinity.clear()
	gd0.active_quests.clear()
	gd0.infrastructure.clear()
	gd0.veteran_year = 1
	gd0.married = false
	gd0.spouse = ""
	gd0.married_year = 0
	gd0.child_stage = 0
	gd0.npc_first_met_day.clear()
	gd0.lost_to_rival.clear()
	gd0.rival_warning_shown.clear()
	gd0.milestones_earned.clear()
	var loaded: bool = sm.load_game()
	_check(loaded, "load_game() reads saved file back")
	var gd: Node = root.get_node("GameData")
	_check(int(gd.inventory.get("rice_grain", 0)) == 7, "round-trip restores rice_grain=7")
	_check(int(gd.inventory.get("krathong", 0)) == 1, "round-trip restores krathong=1")
	_check(int(gd.harmony) == 21, "round-trip restores harmony=21")
	_check(is_equal_approx(float(gd.max_stamina), 130.0), "round-trip restores max_stamina=130")
	_check(is_equal_approx(float(gd.current_stamina), 80.0), "round-trip restores current_stamina=80")
	_check(int(gd.fishing_skill) == 3, "round-trip restores fishing_skill=3")
	_check(int(gd.mining_skill) == 2, "round-trip restores mining_skill=2")
	_check(int(gd.buffalo_affinity) == 55, "round-trip restores buffalo_affinity=55")
	_check(int(gd.chicken_count) == 2, "round-trip restores chicken_count=2")
	_check(int(gd.tool_tiers.get("hoe", 0)) == 3, "round-trip restores tool_tiers.hoe=3")
	_check(int(gd.affinity.get("niran", 0)) == 90, "round-trip restores NPC affinity")
	_check(gd.active_quests.has("harvest_two_crop_types"), "round-trip restores active_quests")
	_check(bool(gd.infrastructure.get("sluice_gate", false)), "round-trip restores infrastructure repairs")
	_check(int(gd.veteran_year) == 2, "round-trip restores veteran_year=2")
	_check(gd.married and gd.spouse == "niran" and int(gd.married_year) == 1 and int(gd.child_stage) == 2,
		"round-trip restores full marriage/family state")
	_check(int(gd.npc_first_met_day.get("fah", -1)) == 5, "round-trip restores npc_first_met_day")
	_check(bool(gd.lost_to_rival.get("kiet", false)), "round-trip restores lost_to_rival")
	_check(int(gd.rival_warning_shown.get("fah", -1)) == 2, "round-trip restores rival_warning_shown")
	_check(bool(gd.milestones_earned.get("deep_miner", false)), "round-trip restores milestones_earned")

	# --- saved file carries the version tag ---
	var f: FileAccess = FileAccess.open("user://savegame.json", FileAccess.READ)
	var raw: String = f.get_as_text() if f else ""
	var parsed: Variant = JSON.parse_string(raw)
	_check(parsed is Dictionary and int((parsed as Dictionary).get("version", 0)) == 4,
		"saved JSON carries version=4")

	sm.queue_free()
	print("\n=== SAVE-COMPAT TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("SAVE-COMPAT GATE FAILED: %d failing checks" % _failed)
	await process_frame
	quit(1 if _failed > 0 else 0)
