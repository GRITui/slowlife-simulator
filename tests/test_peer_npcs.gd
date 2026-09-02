extends SceneTree
# TASK-052 peer NPC gate — instanced, scripted, gift->affinity->tier flow.

var _passed: int = 0
var _failed: int = 0
var _last_dialogue_line: String = ""

func _on_show_dialogue(_speaker: String, line: String) -> void:
	_last_dialogue_line = line

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

	# TASK-341: 3 more romance candidates (Kiet, Malee, Kanya), authored
	# directly in TASK-346's 10-level shape.
	var kiet: Node = main.get_node_or_null("KietNPC")
	var malee: Node = main.get_node_or_null("MaleeNPC")
	var kanya: Node = main.get_node_or_null("KanyaNPC")
	_check(kiet != null, "KietNPC instanced")
	_check(malee != null, "MaleeNPC instanced")
	_check(kanya != null, "KanyaNPC instanced")
	var trio: Array = [
		{"node": kiet, "id": "kiet", "name": "Kiet", "loved_gift": "thai_basil_stirfry", "specialty": "wood"},
		{"node": malee, "id": "malee", "name": "Malee", "loved_gift": "mango_sticky_rice", "specialty": "wan_sart_basket"},
		{"node": kanya, "id": "kanya", "name": "Kanya", "loved_gift": "thai_basil", "specialty": "thai_basil_stirfry"},
	]
	for c: Dictionary in trio:
		var npc: Node = c["node"]
		if npc == null:
			continue
		var id: String = c["id"]
		_check(npc.is_in_group("romance_candidate"), "%s tagged romance_candidate" % c["name"])
		_check(String(npc.npc_id) == id, "%s npc_id set" % c["name"])
		_check(String(npc.display_name) == c["name"], "%s display_name set" % c["name"])
		gd.affinity[id] = 0
		gd.inventory.clear()
		gd.add_item(c["loved_gift"], 1)
		_check(npc.try_interact(), "%s gift interact consumes food" % c["name"])
		_check(int(gd.inventory.get(c["loved_gift"], 0)) == 0, "%s gift item consumed" % c["name"])
		_check(int(gd.get_affinity(id)) == 20, "%s loved gift grants +20" % c["name"])
		# Specialty-sell (close-tier gated, 60+), takes priority over gift.
		gd.affinity[id] = 60
		gd.inventory.clear()
		gd.add_item(c["specialty"], 1)
		var silver_before_c: int = gd.silver
		_check(npc.try_interact(), "%s specialty-sell interact succeeds at close tier" % c["name"])
		_check(int(gd.inventory.get(c["specialty"], 0)) == 0, "%s specialty item consumed" % c["name"])
		_check(gd.silver > silver_before_c, "%s specialty sell grants silver premium" % c["name"])

	# TASK-345/341: "1_warned" early-warning fix — fires at level 1 once a
	# rival warning has shown, does NOT fire at level 1 with no warning yet.
	var sb: Node = root.get_node("SignalBus")
	sb.show_dialogue.connect(_on_show_dialogue)
	var db: GDScript = load("res://scripts/narrative/DialogueDB.gd")
	for c2: Dictionary in [
		{"node": kiet, "id": "kiet"}, {"node": malee, "id": "malee"}, {"node": kanya, "id": "kanya"},
		{"node": niran, "id": "niran"}, {"node": fah, "id": "fah"}, {"node": ploy, "id": "ploy"},
	]:
		var npc2: Node = c2["node"]
		if npc2 == null:
			continue
		var id2: String = c2["id"]
		var warned_lines: Array = db.DIALOGUE.get(id2, {}).get("1_warned", [])
		_check(not warned_lines.is_empty(), "%s has a '1_warned' pool" % id2)
		gd.affinity[id2] = 5 # level 1
		gd.rival_warning_shown[id2] = 0
		_last_dialogue_line = ""
		npc2.call("_talk")
		_check(_last_dialogue_line not in warned_lines, "%s no warning yet -> normal level-1 line" % id2)
		gd.rival_warning_shown[id2] = 1
		_last_dialogue_line = ""
		npc2.call("_talk")
		_check(_last_dialogue_line in warned_lines, "%s warning shown -> '1_warned' line at level 1" % id2)
		gd.rival_warning_shown.erase(id2)
	sb.show_dialogue.disconnect(_on_show_dialogue)

	main.queue_free()
	print("\n=== PEER-NPC TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("PEER-NPC GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
