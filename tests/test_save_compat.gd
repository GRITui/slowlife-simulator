extends SceneTree
# TASK-026 save compatibility gate — versioned schema + migration round-trip.
# Run: godot --headless --path . --script res://tests/test_save_compat.gd
# Exit 0 = green, 1 = failures. Additive to content/engine gates (run_gate.sh).

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
	_check(int(m.get("version", 0)) == 2, "migrate tags version 2")
	var inv: Dictionary = m.get("inventory", {}) as Dictionary
	_check(inv.get("rice_grain") is int and int(inv["rice_grain"]) == 3,
		"migrate coerces inventory floats to int (rice_grain)")
	_check(inv.get("krathong") is int and int(inv["krathong"]) == 1,
		"migrate coerces inventory floats to int (krathong)")
	_check(m.get("harmony") is int and int(m["harmony"]) == 12, "migrate coerces harmony to int")
	_check(v1.get("inventory", {}).get("rice_grain") is float,
		"migrate does not mutate input payload")

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

	# --- migrate(): already-v2 payload is a no-op pass-through ---
	var v2: Dictionary = {"version": 2, "inventory": {"mango": 2}, "harmony": 5, "season": "hot"}
	var m2: Dictionary = sm.migrate(v2)
	_check(int(m2.get("version", 0)) == 2, "migrate keeps version 2 payload")
	_check((m2.get("inventory", {}) as Dictionary).get("mango") == 2, "v2 inventory preserved")

	# --- round-trip via real file IO (user://) ---
	root.get_node("GameData").add_item("rice_grain", 7)
	root.get_node("GameData").add_item("krathong", 1)
	root.get_node("GameData").harmony = 21
	var saved: bool = sm.save_game()
	_check(saved, "save_game() writes user://savegame.json")
	# Mutate state, then load restores it.
	root.get_node("GameData").inventory.clear()
	root.get_node("GameData").harmony = 0
	var loaded: bool = sm.load_game()
	_check(loaded, "load_game() reads saved file back")
	var gd: Node = root.get_node("GameData")
	_check(int(gd.inventory.get("rice_grain", 0)) == 7, "round-trip restores rice_grain=7")
	_check(int(gd.inventory.get("krathong", 0)) == 1, "round-trip restores krathong=1")
	_check(int(gd.harmony) == 21, "round-trip restores harmony=21")

	# --- saved file carries the version tag ---
	var f: FileAccess = FileAccess.open("user://savegame.json", FileAccess.READ)
	var raw: String = f.get_as_text() if f else ""
	var parsed: Variant = JSON.parse_string(raw)
	_check(parsed is Dictionary and int((parsed as Dictionary).get("version", 0)) == 2,
		"saved JSON carries version=2")

	sm.queue_free()
	print("\n=== SAVE-COMPAT TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("SAVE-COMPAT GATE FAILED: %d failing checks" % _failed)
	await process_frame
	quit(1 if _failed > 0 else 0)
