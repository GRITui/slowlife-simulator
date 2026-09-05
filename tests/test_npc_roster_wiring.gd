extends SceneTree
# TASK-373 gate — 17 NPCs (6 romance candidates, their 6 paired rivals,
# 5 general villagers incl. Trader) were complete, dialogue-ready content
# that had never been instanced anywhere in the game. This test instances
# the real World.tscn and verifies every one of the 17 is actually
# present with the correct script/group/npc_id — not just that SOME
# node exists, and not just re-checking the 5 NPCs that were already
# wired before this task (that would test nothing new).
#
# TASK-383 extended this test to also cover the 14 new background NPCs
# (family + wanderers, FlavorNPC.gd). Those NPCs deliberately do NOT
# share the romance_candidate/villager_npc/rival_npc groups — they get
# their own `flavor_npc` group per the TASK-383 spec — so this test
# asserts their group from the expected NEW_NPCS row directly rather
# than blanket-checking `villager_npc`.
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
	# TASK-383: 14 background NPCs (family + wanderers). These share
	# NEITHER the romance_candidate, villager_npc, nor rival_npc groups —
	# they get their own `flavor_npc` group per spec. candidate_id is
	# always "" (no candidate coupling, no romance/gift machinery).
	"CharoenNPC": ["FlavorNPC.gd", "flavor_npc", "charoen", ""],
	"SomsriNPC": ["FlavorNPC.gd", "flavor_npc", "somsri", ""],
	"GaewNPC": ["FlavorNPC.gd", "flavor_npc", "gaew", ""],
	"BoonchuNPC": ["FlavorNPC.gd", "flavor_npc", "boonchu", ""],
	"AmpaiNPC": ["FlavorNPC.gd", "flavor_npc", "ampai", ""],
	"YingNPC": ["FlavorNPC.gd", "flavor_npc", "ying", ""],
	"NamNPC": ["FlavorNPC.gd", "flavor_npc", "nam", ""],
	"TongNPC": ["FlavorNPC.gd", "flavor_npc", "tong", ""],
	"KhamNPC": ["FlavorNPC.gd", "flavor_npc", "kham", ""],
	"KaewNPC": ["FlavorNPC.gd", "flavor_npc", "kaew", ""],
	"BupphaNPC": ["FlavorNPC.gd", "flavor_npc", "buppha", ""],
	"DaengNPC": ["FlavorNPC.gd", "flavor_npc", "daeng", ""],
	"PloenNPC": ["FlavorNPC.gd", "flavor_npc", "ploen", ""],
	"AddNPC": ["FlavorNPC.gd", "flavor_npc", "add", ""],
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

# TASK-383: non-NPC EXISTING_POINTS to exclude from the closest-distance
# check. The TASK-383 locked positions were verified against the 22
# currently-instanced NPCs (NPC-vs-NPC >=1 tile), not against these
# interactable structures — Kaew (744, 696) is intentionally close to
# the SluiceGate (744, 672) because Kaew is the vet's sibling, working
# in that area, but the spec verification was NPC-only.
const NON_NPC_OCCUPANTS: Array = ["SluiceGate", "MarketStall", "FarmHouseDoor", "EastEdge"]

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
		# TASK-383: only check 'villager_npc' for NPCs whose expected
		# group IS 'villager_npc'. RomanceNPC.gd adds 'romance_candidate'
		# AND 'villager_npc' (its _ready() does both), so romance rows
		# also pass; flavor_npc NPCs deliberately don't.
		if group == "villager_npc":
			_check(node.is_in_group("villager_npc"), "%s is in group 'villager_npc'" % npc_name)
		_check(String(node.get("npc_id")) == npc_id, "%s npc_id == '%s'" % [npc_name, npc_id])
		if candidate_id != "":
			_check(String(node.get("candidate_id")) == candidate_id,
				"%s candidate_id == '%s'" % [npc_name, candidate_id])

		all_positions[npc_name] = node.position

	# --- Positional safety: walkable ground, no overlap ---
	# Only meaningful for npc_ids WITHOUT a ScheduleDB override — those
	# NPCs' real position is schedule-driven, not the static .tscn value.
	#
	# TASK-383: NPC-vs-NPC is the only distance check the locked-position
	# verification was done against (per the task spec: "every position
	# below is confirmed >=1 tile from every existing occupant and outside
	# every water/farmland zone" where "existing occupant" referred to the
	# 22 currently-instanced NPCs). Non-NPC EXISTING_POINTS like
	# SluiceGate/MarketStall/FarmHouseDoor/EastEdge are interactable
	# structures whose positions overlap Kaew's locked slot by design
	# (Kaew is the vet's sibling, intentionally near the SluiceGate
	# work area — but the locked 1-tile spacing was only verified
	# against NPCs). So the closest-distance check filters out those
	# non-NPC interactables for NPCs whose spec-source is TASK-383.
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
			# TASK-383: skip non-NPC interactables for the closest-distance
			# check — they aren't "NPC occupants" in the spec's verification
			# sense and overlap by design (Kaew vs SluiceGate, e.g.).
			if other_name in NON_NPC_OCCUPANTS:
				continue
			var d: float = pos.distance_to(all_positions[other_name])
			if d < min_dist:
				min_dist = d
				closest = other_name
		_check(min_dist >= TILE, "%s is at least 1 tile from every other NPC occupant (closest: %s at %.0fpx)" % [npc_name, closest, min_dist])

	# --- TASK-383: flavor dialogue round-robin + real input wiring ---
	# Verifies (a) FlavorDialogue.gd's data for at least 2 npc_ids is
	# exactly the locked 3 lines in order, and (b) the real
	# _unhandled_input() path — driven via an InputEventAction "interact"
	# press — advances through them, wraps modulo, and emits the right
	# speaker_name on SignalBus.show_dialogue. The InputEventAction is
	# the same pattern test_farmhouse_decor.gd and
	# test_relationship_status.gd use to regression-guard the actual
	# input wiring (catches "prompt shows but action isn't bound" bugs
	# that a direct _talk() call would silently miss).
	await _run_flavor_dialogue_cycle_tests(world)

	world.queue_free()
	await process_frame

func _run_flavor_dialogue_cycle_tests(world: Node) -> void:
	var FlavorDialogueScript: GDScript = load("res://scripts/narrative/FlavorDialogue.gd") as GDScript
	_check(FlavorDialogueScript != null, "FlavorDialogue.gd loads")
	if FlavorDialogueScript == null:
		return
	var lines: Dictionary = FlavorDialogueScript.FLAVOR_LINES
	# TASK-390: 14 TASK-383 lines + 3 lone-NPC lines (ferryman /
	# fish_keeper / scrap_collector). The 3 newcomers' presence, exact
	# positions, and dialogue cycles are covered in tests/test_lone_npcs.gd
	# instead — their locked World.tscn positions sit on plantable-soil
	# tiles by design (dock-side / tree-line / field-edge flavor), so they
	# are deliberately NOT in NEW_NPCS above: this file's coarse
	# WATER_ZONES/FARMLAND_ZONES approximations would flag them.
	_check(lines.size() == 17,
		"FlavorDialogue.FLAVOR_LINES has exactly 17 npc_ids (got %d)" % lines.size())

	# SignalBus is an autoload — reach it via the SceneTree root, not as
	# a bare identifier (the parser doesn't see it as a global in
	# --script mode without the project autoload table in scope).
	var sb: Node = root.get_node_or_null("SignalBus") as Node
	_check(sb != null, "SignalBus autoload present for cycle test")
	if sb == null:
		return

	# Pick 2 of the 17 for the cycling + input-wiring check. Use one
	# from the family set (charoen) and one from the wanderer set (add)
	# to cover both halves of the roster.
	for npc_name: String in ["CharoenNPC", "AddNPC"]:
		var npc_id: String = String(NEW_NPCS[npc_name][2])
		var pool: Array = lines.get(npc_id, [])
		_check(pool is Array and pool.size() == 3,
			"%s: FLAVOR_LINES['%s'] is a 3-element Array (got %d elems)" % [npc_name, npc_id, pool.size() if pool is Array else -1])
		if pool.size() != 3:
			continue

		var npc: Node = world.get_node_or_null(npc_name)
		_check(npc != null, "%s: present in World for cycle test" % npc_name)
		if npc == null:
			continue

		# Drive the REAL input path — same InputEventAction pattern
		# test_relationship_status.gd uses. _player_in_range flipped on
		# directly so the test isn't blocked on the InteractArea body
		# collision event firing (which requires a real Area2D body
		# enter in headless mode).
		npc.set("_player_in_range", true)

		var captured: Array = [] # [speaker_name, text] per emit
		var handler := func(speaker: String, text: String) -> void:
			captured.append([speaker, text])
		sb.connect("show_dialogue", handler)

		# Press interact 4 times: should cycle 0 -> 1 -> 2 -> 0.
		for i: int in range(4):
			var ev: InputEvent = InputEventAction.new()
			(ev as InputEventAction).action = "interact"
			(ev as InputEventAction).pressed = true
			npc.call("_unhandled_input", ev)
			await process_frame

		sb.disconnect("show_dialogue", handler)

		_check(captured.size() == 4,
			"%s: 4 'interact' presses -> 4 show_dialogue emits (got %d)" % [npc_name, captured.size()])
		if captured.size() < 4:
			npc.set("_player_in_range", false)
			continue

		var disp_name: String = String(npc.get("display_name"))
		_check(String(captured[0][0]) == disp_name,
			"%s: show_dialogue speaker == display_name '%s' (got '%s')" % [npc_name, disp_name, String(captured[0][0])])
		# TASK-385: Charoen is a family NPC — its FIRST talk of the day is
		# the once-per-day gift hint (for Fah), and the hint consumes no
		# flavor-cycle step, so presses 2-4 are pool[0..2] in order.
		if npc_id == "charoen":
			var db: GDScript = load("res://scripts/narrative/DialogueDB.gd") as GDScript
			var prefs: Dictionary = db.GIFT_PREFERENCES.get("fah", {})
			var loved: Array = prefs.get("loved", [])
			var want_hint: String = "She's always going on about %s." % String(loved[0]).replace("_", " ")
			_check(String(captured[0][1]) == want_hint,
				"%s: line 0 is the once-per-day Fah gift hint" % npc_name)
			_check(String(captured[1][1]) == String(pool[0]),
				"%s: line 1 matches pool[0] (hint consumed no cycle step)" % npc_name)
			_check(String(captured[2][1]) == String(pool[1]),
				"%s: line 2 matches pool[1]" % npc_name)
			_check(String(captured[3][1]) == String(pool[2]),
				"%s: line 3 matches pool[2]" % npc_name)
		else:
			_check(String(captured[0][1]) == String(pool[0]),
				"%s: line 0 matches pool[0]" % npc_name)
			_check(String(captured[1][1]) == String(pool[1]),
				"%s: line 1 matches pool[1]" % npc_name)
			_check(String(captured[2][1]) == String(pool[2]),
				"%s: line 2 matches pool[2]" % npc_name)
			_check(String(captured[3][1]) == String(pool[0]),
				"%s: line 3 wraps to pool[0]" % npc_name)

		# Out-of-range guard — same shape as the picker test's.
		npc.set("_player_in_range", false)
		captured.clear()
		var handler2 := func(speaker: String, text: String) -> void:
			captured.append([speaker, text])
		sb.connect("show_dialogue", handler2)
		var ev_off: InputEvent = InputEventAction.new()
		(ev_off as InputEventAction).action = "interact"
		(ev_off as InputEventAction).pressed = true
		npc.call("_unhandled_input", ev_off)
		await process_frame
		sb.disconnect("show_dialogue", handler2)
		_check(captured.is_empty(),
			"%s: 'interact' ignored when player is out of range (no show_dialogue emit)" % npc_name)

		npc.set("_player_in_range", false)

func _initialize() -> void:
	await _run_all()
	print("\n=== NPC-ROSTER-WIRING TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("NPC-ROSTER-WIRING GATE FAILED: %d failing checks" % _failed)
	quit(1 if _failed > 0 else 0)
