extends SceneTree
# TASK-054 gift preference gate — tiers scale affinity.
# TASK-349: extended with a high-affiliation end-to-end check
# (villager.talk() at level 6+ surfaces a high_affiliation line ~40% of the time).

var _passed: int = 0
var _failed: int = 0
var _last_dialogue_line: String = ""

func _on_show_dialogue(_speaker: String, line: String) -> void:
	_last_dialogue_line = line

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  gifts :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  gifts :: %s" % label)

func _initialize() -> void:
	var db: GDScript = load("res://scripts/narrative/DialogueDB.gd")
	_check(String(db.gift_tier("ek", "mango")) == "loved", "ek loves mango (loved)")
	_check(String(db.gift_tier("fah", "lotus_root")) == "loved", "fah loves lotus_root")
	_check(String(db.gift_tier("ek", "rice_grain")) == "liked", "ek likes rice_grain")
	_check(String(db.gift_tier("ek", "egg")) == "neutral", "neutral fallback")
	_check(int(db.gift_affinity("loved")) == 20, "loved = +20")
	_check(int(db.gift_affinity("liked")) == 10, "liked = +10")
	_check(int(db.gift_affinity("neutral")) == 5, "neutral = +5")
	# End-to-end through RomanceNPC.
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var ek: Node = main.get_node_or_null("EkNPC")
	gd.inventory.clear()
	gd.add_item("mango", 1)
	ek.try_interact()
	_check(int(gd.get_affinity("ek")) == 20, "loved gift grants +20 via NPC flow")

	# Phase 3 audit (2026-09-02): gifting was RomanceNPC-only even though
	# GIFT_PREFERENCES already covered elder/child/handler — extended
	# VillagerNPC.talk() to call the same _give_gift() mechanic.
	var elder: Node = main.get_node_or_null("ElderNPC")
	_check(elder != null, "ElderNPC present")
	if elder != null:
		gd.inventory.clear()
		gd.add_item("lotus_root", 1)
		var affinity_before: int = int(gd.get_affinity("elder"))
		elder.talk()
		_check(int(gd.get_affinity("elder")) == affinity_before + 20,
			"elder (villager, not romance) gains +20 from a loved gift via talk()")
		_check(int(gd.inventory.get("lotus_root", 0)) == 0, "gifted lotus_root consumed from inventory")

	# TASK-338: Nok, the new veteran-farmer villager.
	var nok: Node = main.get_node_or_null("NokNPC")
	_check(nok != null, "NokNPC present")
	if nok != null:
		gd.inventory.clear()
		gd.add_item("sticky_rice", 1)
		var nok_before: int = int(gd.get_affinity("nok"))
		nok.talk()
		_check(int(gd.get_affinity("nok")) == nok_before + 20,
			"nok gains +20 from a loved gift (sticky_rice) via talk()")

	# TASK-349: high-affiliation end-to-end — push elder's affinity to 60+
	# (level 6) and call talk() enough times to hit the ~40% roll at least
	# once. Clear inventory so _give_gift() doesn't intercept, and pin
	# binthabat_done=false / weather=clear so the only active branches are
	# binthabat_hint (roll%3==0) and high_affiliation (roll%5<2).
	if elder != null:
		gd.inventory.clear()
		gd.last_offering_day = -1
		gd.daily_offerings = 0
		gd.current_weather = "clear"
		gd.affinity["elder"] = 60
		var sb: Node = root.get_node("SignalBus")
		sb.show_dialogue.connect(_on_show_dialogue)
		var high_pool_e2e: Array = (db.DIALOGUE["elder"] as Dictionary)["high_affiliation"] as Array
		var saw_high: bool = false
		for _i in range(20):
			_last_dialogue_line = ""
			elder.talk()
			if high_pool_e2e.has(_last_dialogue_line):
				saw_high = true
				break
		sb.show_dialogue.disconnect(_on_show_dialogue)
		_check(saw_high,
			"villager.talk() at level 6+ surfaces a high_affiliation line within 20 calls")
		# Reset for any later (none currently, but defensive).
		gd.affinity["elder"] = 0
	main.queue_free()
	print("\n=== GIFT-PREFS TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("GIFT-PREFS GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
