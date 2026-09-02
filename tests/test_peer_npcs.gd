extends SceneTree
# TASK-052 peer NPC gate — instanced, scripted, gift->affinity->tier flow.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  peer-npc :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  peer-npc :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var niran: Node = main.get_node_or_null("NiranNPC")
	var fah: Node = main.get_node_or_null("FahNPC")
	var ploy: Node = main.get_node_or_null("PloyNPC")
	_check(niran != null, "NiranNPC instanced")
	_check(fah != null, "FahNPC instanced")
	_check(ploy != null, "PloyNPC instanced (TASK-335 third romance candidate)")
	if niran == null or fah == null or ploy == null:
		await process_frame
		quit(1)
		return
	_check(niran.is_in_group("romance_candidate"), "Niran tagged romance_candidate")
	_check(niran.has_method("try_interact"), "RomanceNPC script attached")
	_check(String(niran.npc_id) == "niran", "Niran npc_id set")
	# Gift flow: mango -> +10 affinity, item consumed. (Picker takes the
	# FIRST held food — clear boot-seeded rice_grain to isolate mango.)
	gd.inventory.erase("rice_grain")
	gd.add_item("mango", 1)
	_check(niran.try_interact(), "gift interact consumes food")
	_check(int(gd.inventory.get("mango", 0)) == 0, "gift item consumed")
	_check(int(gd.get_affinity("niran")) == 20, "loved gift (mango) grants +20 (TASK-054 prefs)")
	# Tier talk: at 10 affinity -> stranger tier line emitted (no crash).
	gd.inventory.clear()
	niran.try_interact()
	_check(int(gd.get_affinity("niran")) == 20, "talk adds no affinity")
	# Cross-tier: push Fah to friendly threshold -> friendly line (not stranger).
	gd.add_affinity("fah", 25)
	fah.try_interact()
	_check(int(gd.get_affinity("fah")) == 25, "fah affinity 25")
	# TASK-335: Ploy — same gift/tier flow, distinct npc_id and group tags.
	_check(ploy.is_in_group("romance_candidate"), "Ploy tagged romance_candidate")
	_check(String(ploy.npc_id) == "ploy", "Ploy npc_id set")
	_check(String(ploy.display_name) == "Ploy", "Ploy display_name set")
	gd.inventory.clear()
	gd.add_item("banana_rice_cake", 1)
	_check(ploy.try_interact(), "Ploy gift interact consumes food")
	_check(int(gd.inventory.get("banana_rice_cake", 0)) == 0, "Ploy gift item consumed")
	_check(int(gd.get_affinity("ploy")) == 20, "Ploy loved gift (banana_rice_cake) grants +20")
	# TASK-335: Ploy's specialty-sell channel — cooked desserts at premium,
	# close-tier gated (60+), takes priority over the gift branch.
	gd.affinity["ploy"] = 60
	gd.inventory.clear()
	gd.add_item("banana_rice_cake", 1)
	var silver_before: int = gd.silver
	_check(ploy.try_interact(), "Ploy specialty-sell interact succeeds at close tier")
	_check(int(gd.inventory.get("banana_rice_cake", 0)) == 0, "specialty item consumed")
	_check(gd.silver > silver_before, "specialty sell grants silver premium")

	# TASK-340: rival win/loss clock — npc_first_met_day set on first
	# interact (niran was already interacted with above, at boot day 1).
	_check(int(gd.npc_first_met_day.get("niran", -1)) == 1, "npc_first_met_day set on first interact")
	var met_before: int = int(gd.npc_first_met_day.get("niran", -1))
	niran.try_interact()
	_check(int(gd.npc_first_met_day.get("niran", -1)) == met_before,
		"npc_first_met_day is not overwritten on later interacts")
	# _check_proposal() hard-blocks a candidate lost to their rival, at any
	# affinity, with a krathong held — the permanent enforcement point.
	gd.affinity["fah"] = 100
	gd.add_item("krathong", 1)
	gd.lost_to_rival["fah"] = true
	_check(fah.call("_check_proposal") == false, "lost_to_rival permanently blocks proposal even at affinity 100")
	_check(not gd.married, "proposal block leaves married=false")
	gd.lost_to_rival.erase("fah")
	_check(fah.call("_check_proposal") == true, "proposal succeeds normally once not lost_to_rival")
	main.queue_free()
	print("\n=== PEER-NPC TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("PEER-NPC GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
