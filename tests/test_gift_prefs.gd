extends SceneTree
# TASK-054 gift preference gate — tiers scale affinity.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  gifts :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  gifts :: %s" % label)

func _initialize() -> void:
	var db: GDScript = load("res://scripts/narrative/DialogueDB.gd")
	_check(String(db.gift_tier("niran", "mango")) == "loved", "niran loves mango (loved)")
	_check(String(db.gift_tier("fah", "lotus_root")) == "loved", "fah loves lotus_root")
	_check(String(db.gift_tier("niran", "rice_grain")) == "liked", "niran likes rice_grain")
	_check(String(db.gift_tier("niran", "egg")) == "neutral", "neutral fallback")
	_check(int(db.gift_affinity("loved")) == 20, "loved = +20")
	_check(int(db.gift_affinity("liked")) == 10, "liked = +10")
	_check(int(db.gift_affinity("neutral")) == 5, "neutral = +5")
	# End-to-end through RomanceNPC.
	var gd: Node = root.get_node("GameData")
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var niran: Node = main.get_node_or_null("NiranNPC")
	gd.inventory.clear()
	gd.add_item("mango", 1)
	niran.try_interact()
	_check(int(gd.get_affinity("niran")) == 20, "loved gift grants +20 via NPC flow")

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
	main.queue_free()
	print("\n=== GIFT-PREFS TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("GIFT-PREFS GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
