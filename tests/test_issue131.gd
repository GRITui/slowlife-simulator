extends SceneTree
var _passed: int = 0
var _failed: int = 0
func _check(cond: bool, label: String) -> void:
	if cond: _passed += 1; print("  PASS  issue131 :: %s" % label)
	else: _failed += 1; print("  FAIL  issue131 :: %s" % label)
func _initialize() -> void:
	var main: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var h: Node = main.get_node_or_null("HeadmanNPC")
	var v: Node = main.get_node_or_null("VetNPC")
	_check(h != null, "HeadmanNPC instanced")
	_check(v != null, "VetNPC instanced")
	if h != null:
		_check(h.is_in_group("villager_npc") and h.has_method("talk"), "Headman scripted + interactive")
	if v != null:
		_check(String(v.npc_id) == "vet", "Vet npc_id set")
	main.queue_free()
	print("\n=== ISSUE-131 TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0: push_error("ISSUE-131 GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
