extends SceneTree
# TASK-373 gate — 17 NPCs (6 romance candidates, their 6 paired rivals,
# 5 general villagers incl. Trader) were complete, dialogue-ready content
# that had never been instanced anywhere in the game. This test instances
# the real World.tscn and verifies every one of the 17 is actually
# present with the correct script/group/npc_id — not just that SOME
# node exists, and not just re-checking the 5 NPCs that were already
# wired before this task (that would test nothing new).
#
# Also verifies real positional safety (walkable ground, no overlap with
# water/farmland/each other/existing NPCs) — this project already got
# burned once by an unverified spatial claim reaching implementation
# (TASK-357), and a first pass at this exact task placed 2 NPCs
# completely off the map, 1 inside a water tile, and 6 on farmable soil,
# caught only by this check, not by node-presence testing alone.

var _passed: int = 0
var _failed: int = 0

const TILE: int = 48
const GRID_W: int = 20
const GRID_H: int = 16
# (x0,y0,x1,y1) in tile units — mirrors WorldRender.gd's own ground-rects.
const WATER_ZONES: Array = [
	[0, 0, 5, 4],      # lotus_pond
	[14, 10, 17, 13],  # lotus_maze_islet (deep_pond)
	[9, 13, 17, 14],   # canal_row
]
const FARMLAND_ZONES: Array = [
	[3, 4, 17, 10],   # paddy_core
	[9, 10, 14, 13],  # paddy_south
]

# name -> [script_path_suffix, group, npc_id, candidate_id_or_empty]
const NEW_NPCS: Dictionary = {
	"ChangNPC": ["RomanceNPC.gd", "romance_candidate", "chang", ""],
	"YaaNPC": ["RomanceNPC.gd", "romance_candidate", "yaa", ""],
	"PloyNPC": ["RomanceNPC.gd", "romance_candidate", "ploy", ""],
	"EkNPC": ["RomanceNPC.gd", "romance_candidate", "ek", ""],
	"FahNPC": ["RomanceNPC.gd", "romance_candidate", "fah", ""],
	"KlongNPC": ["RomanceNPC.gd", "romance_candidate", "klong", ""],
	"NoteNPC": ["RivalNPC.gd", "rival_npc", "note", "chang"],
	"FonNPC": ["RivalNPC.gd", "rival_npc", "fon", "klong"],
	"BoonNPC": ["RivalNPC.gd", "rival_npc", "boon", "yaa"],
	"YaiNPC": ["RivalNPC.gd", "rival_npc", "yai", "ek"],
	"RungNPC": ["RivalNPC.gd", "rival_npc", "rung", "ploy"],
	"OhmNPC": ["RivalNPC.gd", "rival_npc", "ohm", "fah"],
	"HeadmanNPC": ["VillagerNPC.gd", "villager_npc", "headman", ""],
	"SomchaiNPC": ["VillagerNPC.gd", "villager_npc", "somchai", ""],
	"VetNPC": ["VillagerNPC.gd", "villager_npc", "vet", ""],
	"NongTonNPC": ["VillagerNPC.gd", "villager_npc", "nong_ton", ""],
	"TraderNPC": ["VillagerNPC.gd", "villager_npc", "trader", ""],
}

# npc_ids with a registered ScheduleDB waypoint override their static
# .tscn position at _ready() (VillagerNPC.gd line ~32) — the static
# position below is only ever the pre-_ready() initial frame for these,
# not their real gameplay position, so the water/farmland checks below
# don't apply to them (ScheduleDB.gd's own waypoint data is a separate,
# pre-existing system — TASK-373 is scene-wiring, not schedule content).
const SCHEDULED_NPC_IDS: Array = ["ek", "headman", "vet", "fah"]

# Pre-existing NPCs (+ other occupied points) new NPCs must not overlap.
const EXISTING_POINTS: Dictionary = {
	"MonkNPC": Vector2(840, 168), "ElderNPC": Vector2(360, 336),
	"ChildNPC": Vector2(264, 456), "NokNPC": Vector2(216, 360),
	"HandlerNPC": Vector2(696, 600), "Player": Vector2(480, 384),
	"SluiceGate": Vector2(744, 672), "MarketStall": Vector2(480, 320),
	"FarmHouseDoor": Vector2(168, 456), "EastEdge": Vector2(940, 384),
}

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  npc-roster-wiring :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  npc-roster-wiring :: %s" % label)

func _in_any_zone(tx: float, ty: float, zones: Array) -> bool:
	for z: Array in zones:
		if tx >= z[0] and tx < z[2] and ty >= z[1] and ty < z[3]:
			return true
	return false

func _run_all() -> void:
	var world_scene: PackedScene = load("res://scenes/core/World.tscn")
	_check(world_scene != null, "World.tscn loads (PackedScene non-null)")
	if world_scene == null:
		return
	var world: Node = world_scene.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	var all_positions: Dictionary = EXISTING_POINTS.duplicate()

	for npc_name: String in NEW_NPCS.keys():
		var expect: Array = NEW_NPCS[npc_name]
		var script_suffix: String = expect[0]
		var group: String = expect[1]
		var npc_id: String = expect[2]
		var candidate_id: String = expect[3]

		var node: Node2D = world.get_node_or_null(npc_name) as Node2D
		_check(node != null, "%s exists in World.tscn" % npc_name)
		if node == null:
			continue

		var script: Script = node.get_script()
		_check(script != null and String(script.get_path()).ends_with(script_suffix),
			"%s has the correct script (%s)" % [npc_name, script_suffix])
		_check(node.is_in_group(group), "%s is in group '%s'" % [npc_name, group])
		_check(node.is_in_group("villager_npc"), "%s is in group 'villager_npc'" % npc_name)
		_check(String(node.get("npc_id")) == npc_id, "%s npc_id == '%s'" % [npc_name, npc_id])
		if candidate_id != "":
			_check(String(node.get("candidate_id")) == candidate_id,
				"%s candidate_id == '%s'" % [npc_name, candidate_id])

		all_positions[npc_name] = node.position

	# --- Positional safety: walkable ground, no overlap ---
	# Only meaningful for npc_ids WITHOUT a ScheduleDB override — those
	# NPCs' real position is schedule-driven, not the static .tscn value.
	for npc_name: String in NEW_NPCS.keys():
		if not all_positions.has(npc_name):
			continue
		var npc_id: String = String(NEW_NPCS[npc_name][2])
		if npc_id in SCHEDULED_NPC_IDS:
			continue
		var pos: Vector2 = all_positions[npc_name]
		var tx: float = pos.x / TILE
		var ty: float = pos.y / TILE

		_check(tx >= 0.0 and tx < GRID_W and ty >= 0.0 and ty < GRID_H,
			"%s is within map bounds" % npc_name)
		_check(not _in_any_zone(tx, ty, WATER_ZONES),
			"%s is not on a water tile" % npc_name)
		_check(not _in_any_zone(tx, ty, FARMLAND_ZONES),
			"%s is not standing on farmable soil" % npc_name)

		var min_dist: float = INF
		var closest: String = ""
		for other_name: String in all_positions.keys():
			if other_name == npc_name:
				continue
			var d: float = pos.distance_to(all_positions[other_name])
			if d < min_dist:
				min_dist = d
				closest = other_name
		_check(min_dist >= TILE, "%s is at least 1 tile from every other occupant (closest: %s at %.0fpx)" % [npc_name, closest, min_dist])

	world.queue_free()
	await process_frame

func _initialize() -> void:
	await _run_all()
	print("\n=== NPC-ROSTER-WIRING TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("NPC-ROSTER-WIRING GATE FAILED: %d failing checks" % _failed)
	quit(1 if _failed > 0 else 0)
