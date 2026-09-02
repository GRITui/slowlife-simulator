extends SceneTree
# TASK-059 wedding gate — proposal gates, one-spouse, festival event.

var _passed: int = 0
var _failed: int = 0
var _events: Array = []

func _on_festival(name: String) -> void:
	_events.append(name)

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  wedding :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  wedding :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var sb: Node = root.get_node("SignalBus")
	sb.festival_triggered.connect(_on_festival)
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var ek: Node = main.get_node_or_null("EkNPC")
	_check(ek != null, "Ek available")
	if ek == null:
		await process_frame
		quit(1)
		return
	# Below romantic tier: proposal blocked even with krathong. Clean pantry
	# first (boot-seeded rice_grain would be gifted instead of talked to).
	gd.inventory.clear()
	gd.add_item("krathong", 1)
	gd.add_affinity("ek", 80)
	ek.try_interact()
	_check(gd.married == false, "affinity < 90 blocks proposal")
	# Romantic tier + krathong -> proposal accepted.
	gd.add_affinity("ek", 20) # 100
	ek.try_interact()
	_check(gd.married and gd.spouse == "ek", "proposal accepted at romantic tier")
	_check(_events.has("wedding_ek"), "wedding festival event fired")
	_check(int(gd.get_affinity("ek")) == 100, "affinity stays capped at 100")
	# Married dialogue: one-spouse enforced.
	var fah: Node = main.get_node_or_null("FahNPC")
	gd.add_affinity("fah", 100)
	gd.add_item("krathong", 1)
	fah.try_interact()
	_check(gd.spouse == "ek", "second proposal blocked (one spouse)")
	sb.festival_triggered.disconnect(_on_festival)
	main.queue_free()
	print("\n=== WEDDING TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("WEDDING GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
