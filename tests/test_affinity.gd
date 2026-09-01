extends SceneTree
# TASK-051 affinity MVP gate — add/get/cap + tier mapping.

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
	var db: GDScript = load("res://scripts/narrative/DialogueDB.gd")
	_check(String(db.get_affinity_tier(0)) == "stranger", "tier 0 -> stranger")
	_check(String(db.get_affinity_tier(25)) == "friendly", "tier 25 -> friendly")
	_check(String(db.get_affinity_tier(60)) == "close", "tier 60 -> close")
	_check(String(db.get_affinity_tier(90)) == "romantic", "tier 90 -> romantic")
	_check(String(db.get_affinity_tier(100)) == "romantic", "tier 100 -> romantic")
	# Tier branches exist for the romance candidates.
	for npc in ["niran", "fah"]:
		for tier in ["stranger", "friendly", "close", "romantic"]:
			_check(not String(db.get_line(npc, tier, 0)).is_empty(),
				"%s has '%s' dialogue" % [npc, tier])
	print("\n=== AFFINITY TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("AFFINITY GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
