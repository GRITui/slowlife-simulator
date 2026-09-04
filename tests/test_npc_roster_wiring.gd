extends SceneTree

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  npc-roster-wiring :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  npc-roster-wiring :: %s" % label)

func _initialize() -> void:
	await _run_all()

func _run_all() -> void:
	var world_scene: PackedScene = load("res://scenes/core/World.tscn")
	_check(world_scene != null, "World.tscn loads (PackedScene non-null)")
	if world_scene == null:
		return
	var world = world_scene.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	# --- NPC wiring verification ---
	# ElderNPC (VillagerNPC.gd)
	var elder := world.get_node_or_null("ElderNPC") as Node
	_check(elder != null and elder.get_script().get_path().endsWith("VillagerNPC.gd"), "ElderNPC exists with VillagerNPC.gd script")
	if elder:
		_check(elder.get("npc_id") == "elder", "ElderNPC npc_id == elder")
		_check(elder.is_in_group("villager_npc"), "ElderNPC in group villager_npc")

	# ChildNPC (VillagerNPC.gd)
	var child := world.get_node_or_null("ChildNPC") as Node
	_check(child != null and child.get_script().get_path().endsWith("VillagerNPC.gd"), "ChildNPC exists with VillagerNPC.gd script")
	if child:
		_check(child.get("npc_id") == "child", "ChildNPC npc_id == child")
		_check(child.is_in_group("villager_npc"), "ChildNPC in group villager_npc")

	# NokNPC (VillagerNPC.gd)
	var nok := world.get_node_or_null("NokNPC") as Node
	_check(nok != null and nok.get_script().get_path().endsWith("VillagerNPC.gd"), "NokNPC exists with VillagerNPC.gd script")
	if nok:
		_check(nok.get("npc_id") == "nok", "NokNPC npc_id == nok")
		_check(nok.is_in_group("villager_npc"), "NokNPC in group villager_npc")

	# HandlerNPC (VillagerNPC.gd)
	var handler := world.get_node_or_null("HandlerNPC") as Node
	_check(handler != null and handler.get_script().get_path().endsWith("VillagerNPC.gd"), "HandlerNPC exists with VillagerNPC.gd script")
	if handler:
		_check(handler.get("npc_id") == "handler", "HandlerNPC npc_id == handler")
		_check(handler.is_in_group("villager_npc"), "HandlerNPC in group villager_npc")

	# MonkNPC (RomanceNPC.gd)
	var monk := world.get_node_or_null("MonkNPC") as Node
	_check(monk != null and monk.get_script().get_path().endsWith("RomanceNPC.gd"), "MonkNPC exists with RomanceNPC.gd script")
	if monk:
		_check(monk.get("npc_id") == "monk", "MonkNPC npc_id == monk")
		_check(monk.is_in_group("romance_candidate"), "MonkNPC in group romance_candidate")

	world.queue_free()
	await process_frame

	print("\\n=== NPC-ROSTER-WIRING TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("NPC-ROSTER-WIRING GATE FAILED: %d failing checks" % _failed)
	quit(1 if _failed > 0 else 0)
