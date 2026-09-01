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
	_check(niran != null, "NiranNPC instanced")
	_check(fah != null, "FahNPC instanced")
	if niran == null or fah == null:
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
	main.queue_free()
	print("\n=== PEER-NPC TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("PEER-NPC GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
