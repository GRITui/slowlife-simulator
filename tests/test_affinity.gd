extends SceneTree
# TASK-051 affinity MVP gate — add/get/cap.
# TASK-346: tier mapping replaced by GameData.level_for()'s 10-level scale.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  affinity :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  affinity :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	_check(int(gd.get_affinity("niran")) == 0, "affinity defaults to 0")
	gd.add_affinity("niran", 10)
	_check(int(gd.get_affinity("niran")) == 10, "add_affinity +10")
	gd.add_affinity("niran", 500)
	_check(int(gd.get_affinity("niran")) == 100, "affinity caps at 100")
	_check(int(gd.level_for(0)) == 0, "level_for(0) == 0")
	_check(int(gd.level_for(9)) == 0, "level_for(9) == 0")
	_check(int(gd.level_for(10)) == 1, "level_for(10) == 1")
	_check(int(gd.level_for(55)) == 5, "level_for(55) == 5")
	_check(int(gd.level_for(89)) == 8, "level_for(89) == 8")
	_check(int(gd.level_for(90)) == 9, "level_for(90) == 9")
	_check(int(gd.level_for(100)) == 10, "level_for(100) == 10")
	var db: GDScript = load("res://scripts/narrative/DialogueDB.gd")
	# Level pools 1-10 (plus the "rival" flavor pool) exist for every
	# romance candidate.
	for npc in ["niran", "fah", "ploy"]:
		for level in range(1, 11):
			_check(not String(db.get_line(npc, str(level), 0)).is_empty(),
				"%s has level %d dialogue" % [npc, level])
		_check(not String(db.get_line(npc, "rival", 0)).is_empty(),
			"%s has 'rival' dialogue" % npc)
	print("\n=== AFFINITY TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("AFFINITY GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
