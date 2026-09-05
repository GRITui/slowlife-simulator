extends SceneTree
# TASK-031 mobile perf budget gate (headless-safe).
# Run: godot --headless --path . --script res://tests/perf/test_mobile_budget.gd
# On device/real renderer this asserts the draw-call ceiling; headless the
# dummy renderer reports 0 draws, so the ceiling check is trivially green and
# the structural checks (ring bake parity, sprite count) carry the gate.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  perf-budget :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  perf-budget :: %s" % label)

func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/core/World.tscn")
	_check(main_scene != null, "World.tscn loads")
	var main: Node = main_scene.instantiate() if main_scene else null
	if main:
		root.add_child(main)
		await process_frame
		await process_frame
		var wr: Node = main.get_node_or_null("WorldRender")
		_check(wr != null, "WorldRender present")
		if wr:
			# Ring bake parity: 76 tiles, single sprite (1 draw, was 76).
			_check(wr.ring_count() == 76, "ring_count parity == 76 after bake")
			var ring: Node = main.get_node_or_null("BambooRing")
			_check(ring != null and ring.get_child_count() == 0,
				"BambooRing is a single baked sprite (0 children)")
			# Y-sort budget: visible actors/props (z>=0) <= 49, excluding
			# ground dressing (z<0) and logic containers.
			# History: 32->36 (TASK-029: +Buffalo/+CookingStation/+MarketStall);
			# 36->40 (TASK-052: peer NPCs Mali + Fah); 40->44 (#131: Headman +
			# Vet); 44->49 (Phase 3 audit, 2026-09-02: TASK-322's
			# CarpenterUpgrade has a Sprite2D and legitimately counts. TASK-321's
			# MiningSpot does NOT — it's a logic-only interactable with no
			# visual footprint, added to the exclusion list below instead of
			# inflating the budget for a node with nothing to sort).
			# TASK-332: Noticeboard joins the same exclusion list for the same
			# reason (logic-only interactable, invisible interact zone).
			# 49->50 (TASK-335: Ploy, third romance candidate, has a real
			# Sprite2D and legitimately counts, same as CarpenterUpgrade).
			# 50->51 (TASK-338: Nok, new villager, same treatment).
			# TASK-337: MountainCaveSpot joins the same exclusion list for the
			# same reason (logic-only interactable, no visible sprite, same
			# treatment as MiningSpot/Noticeboard).
			# TASK-343: DeepCanalSpot and SacredGroveSpot join the same
			# exclusion list for the same reason (logic-only interactables,
			# no visible sprite, same treatment as the prior unlockable
			# spots).
			# TASK-344: LotusMazeShoreSpot and CoastalTradingPost join the
			# same exclusion list for the same reason (logic-only
			# interactables, no visible sprite, same treatment as the prior
			# unlockable spots — both ship as invisible interact zones).
			# 51->54 (TASK-341: Kwan/Rin/Yaa, 3 more romance candidates,
			# each with a real Sprite2D — same treatment as Ploy/Nok).
			# 54->60 (TASK-342: Yai/Ohm/Rung/Note/Fon/Boon, 6 rival NPCs,
			# each with a real Sprite2D — same treatment as the romance
			# candidates. RivalNPC.talk/_give_gift/_maybe_trigger_confession
			# never enters the Y-sort (no body, no sprite), only the .tscn
			# instanced under World does).
			# TASK-352: FarmHouseDoor (the outdoor door to the farmhouse
			# interior) joins the same exclusion list for the same reason
			# as MiningSpot/Noticeboard — a logic-only interactable, no
			# visible sprite, just an InteractArea child. Budget stays at
			# 60 (BUGFIX: a prior draft of this diff bumped the ceiling to
			# 61 alongside adding this exclusion, which is self-
			# contradictory — if the door is correctly excluded, the count
			# doesn't change and the ceiling shouldn't move either. The
			# actual measured count with the door present is still 60).
			# TASK-357: EastEdge (the World->CoastalArea walk-through
			# transition at the east map edge) joins the same exclusion
			# list for the same reason as FarmHouseDoor / MiningSpot /
			# Noticeboard — a logic-only interactable, no visible sprite,
			# just an Area2D + RectangleShape2D collision child. The
			# corresponding CoastalArea->World WestEdge lives under
			# CoastalArea, not World, so it doesn't appear in this World-
			# tree count at all.
			# 60->59 (TASK-357 Phase-1 split: CarpenterUpgrade moved out
			# of World.tscn into CoastalArea.tscn as a static child —
			# legitimately counted toward the Y-sort budget when it lived
			# here because it has a Sprite2D, no longer contributes once
			# it lives under CoastalArea). CoastalTradingPost /
			# SacredGroveSpot were already on the exclusion list
			# (logic-only interactables, no sprite) so they don't move
			# the count when their spawn site changes from World to
			# CoastalArea. EastEdge is added to the list (no sprite).
			# MEASURED actual count is 59 — do not change this ceiling
			# without re-running and matching the printed "got N".
			var sorted_kids: int = 0
			for c in main.get_children():
				if c is Node2D and (c as Node2D).z_index >= 0:
					var cn: String = String(c.get("name"))
					if cn == "WorldRender" or cn == "Bounds" or cn == "GridManager" or cn == "MiningSpot" or cn == "Noticeboard" or cn == "MountainCaveSpot" or cn == "DeepCanalSpot" or cn == "SacredGroveSpot" or cn == "LotusMazeShoreSpot" or cn == "CoastalTradingPost" or cn == "FarmHouseDoor" or cn == "EastEdge":
						continue
					sorted_kids += 1
			_check(sorted_kids <= 59, "y-sorted participants <= 59 (got %d)" % sorted_kids)
		# Draw-call ceiling (meaningful on device; headless reports 0).
		var draws: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		_check(draws <= 120, "idle draw calls <= 120 budget (got %d)" % draws)
		main.queue_free()
	print("\n=== PERF-BUDGET TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("PERF BUDGET GATE FAILED: %d failing checks" % _failed)
	await process_frame
	quit(1 if _failed > 0 else 0)
