extends SceneTree
# Phase 3 audit (2026-09-02) gate — VillagerNPC's headless-safe idle-texture
# fallback had cases for elder/child/handler but not headman/vet, so both
# silently rendered as Elder despite having dedicated portrait assets. A
# purely visual bug headless tests hadn't caught until this check.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  villager-portraits :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  villager-portraits :: %s" % label)

func _initialize() -> void:
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var expectations: Dictionary = {
		"ElderNPC": "res://assets/characters/npc_elder_idle_01.png",
		"ChildNPC": "res://assets/characters/npc_child_idle_01.png",
		"HandlerNPC": "res://assets/characters/npc_handler_idle_01.png",
		"HeadmanNPC": "res://assets/characters/headman_idle_01.png",
		"VetNPC": "res://assets/characters/vet_idle_01.png",
	}
	for node_name: String in expectations.keys():
		var npc: Node = main.get_node_or_null(node_name)
		_check(npc != null, "%s instanced" % node_name)
		if npc == null:
			continue
		var sprite: Sprite2D = npc.get_node_or_null("Sprite2D") as Sprite2D
		_check(sprite != null and sprite.texture != null, "%s has a texture assigned" % node_name)
		if sprite != null and sprite.texture != null:
			_check(sprite.texture.resource_path == String(expectations[node_name]),
				"%s renders its own portrait, not Elder's fallback (got %s)" % [node_name, sprite.texture.resource_path])
	main.queue_free()
	print("\n=== VILLAGER-PORTRAITS TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("VILLAGER-PORTRAITS GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
