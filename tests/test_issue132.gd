extends SceneTree
var _passed: int = 0
var _failed: int = 0
func _check(cond: bool, label: String) -> void:
	if cond: _passed += 1; print("  PASS  issue132 :: %s" % label)
	else: _failed += 1; print("  FAIL  issue132 :: %s" % label)
func _initialize() -> void:
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var nt: Node = main.get_node_or_null("NongTonNPC")
	var sc: Node = main.get_node_or_null("SomchaiNPC")
	_check(nt != null and nt.has_method("talk"), "NongTonNPC scripted + instanced")
	_check(sc != null and sc.has_method("talk"), "SomchaiNPC scripted + instanced")
	if nt != null: _check(String(nt.npc_id) == "nong_ton", "NongTon npc_id")
	if sc != null: _check(String(sc.npc_id) == "somchai", "Somchai npc_id")
	var db: GDScript = load("res://scripts/narrative/DialogueDB.gd")
	_check(not String(db.get_line("nong_ton", "cool", 0)).is_empty(), "nong_ton dialogue")
	_check(not String(db.get_line("somchai", "cool", 0)).is_empty(), "somchai dialogue")
	main.queue_free()
	print("\n=== ISSUE-132 TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0: push_error("ISSUE-132 GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
