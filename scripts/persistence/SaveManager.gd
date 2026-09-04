extends Node
# SaveManager — ENGINE-003 JSON schema for player/world state, headless-safe.
# TASK-026: versioned schema (SAVE_VERSION) + v1->v2 migration + int coercion
# + default-on-add for new fields (krathong). Dynamic GameData/SignalBus
# lookups keep this script parse-safe under `godot --headless --script`.
#
# Phase 3 save-compat audit (2026-09-02): v2 only ever persisted inventory/
# harmony/season/silver/a11y prefs — every other piece of long-term
# progression (tool tiers, fishing/mining skill, buffalo/chicken/companion
# affinity, herd counts, NPC affinity, quests, marriage, infrastructure
# repairs, veteran year) was silently dropped on every save/load cycle,
# including all of it added across TASK-321..326. v3 persists all of it.
# v7 (TASK-358): fish_almanac — first-catch collection log for the fishing
# system. Same idempotent-Dictionary shape as milestones_earned (added in
# v4), so persistence follows the same default-on-add pattern.

const SAVE_PATH: String = "user://savegame.json"
const SAVE_VERSION: int = 7
# TASK-363: recipe_unlocks is the latest additive-Dict-of-bool field
# saved on top of v7. Saved but not gated by a SAVE_VERSION bump —
# see the per-line save/load comments in save_game() and load_game()
# below for the rationale (additive, defaults to {} which is
# bit-identical to a fresh start).

# Dynamic autoload helpers — safe in main scene, --script, and packaged export.
func _gd() -> Node:
	return Engine.get_main_loop().root.get_node("GameData")

func _sb() -> Node:
	return Engine.get_main_loop().root.get_node("SignalBus")

func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree

# TASK-357: real player position + the scene the player is actually in.
# Previously "player_pos" was a hardcoded [480, 384] literal, never the
# player's actual position, and there was no scene field at all — harmless
# while the game had exactly one scene, silently wrong the moment a second
# scene (FarmHouse, and TASK-357's planned CoastalArea) exists.
func _current_player_pos() -> Array:
	var player: Node = _tree().get_first_node_in_group("player")
	if player is Node2D:
		var p: Vector2 = (player as Node2D).global_position
		return [p.x, p.y]
	return [480, 384] # no player in the tree (e.g. some test setups) — historical default

func _current_scene_path() -> String:
	var cur: Node = _tree().current_scene
	if cur != null and cur.scene_file_path != "":
		return cur.scene_file_path
	return String(ProjectSettings.get_setting("application/run/main_scene", "res://scenes/core/World.tscn"))

func save_game() -> bool:
	var gd: Node = _gd()
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"scene_path": _current_scene_path(),
		"player_pos": _current_player_pos(),
		"inventory": gd.inventory,
		"harmony": gd.harmony,
		"season": gd.current_season,
		# TASK-027 a11y prefs (additive v2 fields, tolerate absence on old saves)
		"font_scale": gd.font_scale,
		"high_contrast": gd.high_contrast,
		# ISSUE-135 silver wallet (additive v2 field)
		"silver": gd.silver,
		# v3 additive fields — see Phase 3 audit note above.
		"max_stamina": gd.max_stamina,
		"current_stamina": gd.current_stamina,
		"infrastructure": gd.infrastructure,
		"daily_offerings": gd.daily_offerings,
		"last_offering_day": gd.last_offering_day,
		"villager_talked_days": gd.villager_talked_days,
		"binthabat_streak": gd.binthabat_streak,
		"last_binthabat_day": gd.last_binthabat_day,
		"fishing_skill": gd.fishing_skill,
		"mining_skill": gd.mining_skill,
		"buffalo_affinity": gd.buffalo_affinity,
		"chicken_affinity": gd.chicken_affinity,
		"companion_bond": gd.companion_bond,
		"chicken_count": gd.chicken_count,
		"buffalo_count": gd.buffalo_count,
		"lifetime_items_shipped": gd.lifetime_items_shipped,
		"stamina_tier": gd.stamina_tier,
		"tool_tiers": gd.tool_tiers,
		"affinity": gd.affinity,
		"active_quests": gd.active_quests,
		"veteran_year": gd.veteran_year,
		"specialty_sales_this_week": gd.specialty_sales_this_week,
		"last_specialty_week": gd.last_specialty_week,
		"spouse": gd.spouse,
		"married": gd.married,
		"married_year": gd.married_year,
		"child_stage": gd.child_stage,
		# v4 additive fields — TASK-340 rival win/loss + TASK-331 milestones
		# (the latter was deliberately deferred at TASK-331 time; closing it
		# here since a schema bump is already in progress for this task).
		"npc_first_met_day": gd.npc_first_met_day,
		"lost_to_rival": gd.lost_to_rival,
		"rival_warning_shown": gd.rival_warning_shown,
		"milestones_earned": gd.milestones_earned,
		# v5 additive fields — TASK-347 rival progress meter + friendship/
		# confession system (the latter built by TASK-342).
		"rival_progress": gd.rival_progress,
		"rival_friendship": gd.rival_friendship,
		"rival_confessed": gd.rival_confessed,
		# v7 additive field — TASK-358 fish_almanac — first-catch collection
		# log. Same primitives-only Dict-of-bool shape as milestones_earned.
		# (v6's scene_path lives at the top of the data dict alongside
		# player_pos; see load_game() and the v5->v6 migration block below.)
		"fish_almanac": gd.fish_almanac,
		# TASK-363: per-recipe unlock state (recipe_id -> true once
		# unlocked by a villager friendship level crossing). Same
		# primitives-only Dict-of-bool shape as milestones_earned and
		# fish_almanac. Additive field, NO SAVE_VERSION bump: the
		# initializer is `{}` and an absent key already means "nothing
		# unlocked yet", which is bit-identical to a fresh start —
		# matching the spec's backward-compat contract.
		"recipe_unlocks": gd.recipe_unlocks,
		# TASK-360: per-slot decor style choice (slot -> style). Additive
		# field, no SAVE_VERSION bump: an absent key is the exact default
		# GameData.decor_choices starts at ({}), and decor_choice() already
		# returns the catalogue default for any unset slot — so a save
		# from before TASK-360 loads as if the player had picked nothing,
		# which is bit-identical to a fresh start (see the spec's
		# "absence means default style" contract).
		"decor_choices": gd.decor_choices,
		# TASK-374: placed furniture (location -> list of {item_id, cell}).
		# No SAVE_VERSION bump: empty {} matches GameData.placed_furniture's init exactly,
		# so old saves load as if no furniture was ever placed.
		"placed_furniture": gd.placed_furniture,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data))
	return true

# Migrate any older payload to SAVE_VERSION shape. Pure function: returns a
# new Dictionary, never mutates the input. Idempotent for v=SAVE_VERSION payloads.
func migrate(data: Dictionary) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	var version: int = int(out.get("version", 1))
	# v1 -> v2: tag version, coerce JSON-float inventory/harmony to int,
	# default-add any new fields that didn't exist in older saves.
	if version < 2:
		var inv: Dictionary = out.get("inventory", {}) as Dictionary
		var fixed: Dictionary = {}
		for item_id: String in inv.keys():
			fixed[item_id] = int(inv[item_id])
		# Default-on-add: new v2 fields must exist on every migrated save so
		# callers can use `inventory[key]` without `.get(key, 0)` everywhere.
		if not fixed.has("krathong"):
			fixed["krathong"] = 0
		out["inventory"] = fixed
		out["harmony"] = int(out.get("harmony", 0))
		out["version"] = 2
	# v2 -> v3: default-add every field the Phase 3 audit found was never
	# being saved at all (see file header). Defaults mirror GameData.gd's
	# own var initializers exactly, so a v1/v2 save loads identically to a
	# freshly-started game for anything that wasn't persisted before.
	if version < 3:
		if not out.has("max_stamina"):
			out["max_stamina"] = 100.0
		if not out.has("current_stamina"):
			out["current_stamina"] = 100.0
		if not out.has("infrastructure"):
			out["infrastructure"] = {}
		if not out.has("daily_offerings"):
			out["daily_offerings"] = 0
		if not out.has("last_offering_day"):
			out["last_offering_day"] = -1
		if not out.has("villager_talked_days"):
			out["villager_talked_days"] = {}
		if not out.has("binthabat_streak"):
			out["binthabat_streak"] = 0
		if not out.has("last_binthabat_day"):
			out["last_binthabat_day"] = -1
		if not out.has("fishing_skill"):
			out["fishing_skill"] = 1
		if not out.has("mining_skill"):
			out["mining_skill"] = 1
		if not out.has("buffalo_affinity"):
			out["buffalo_affinity"] = 0
		if not out.has("chicken_affinity"):
			out["chicken_affinity"] = 0
		if not out.has("companion_bond"):
			out["companion_bond"] = 0
		if not out.has("chicken_count"):
			out["chicken_count"] = 1
		if not out.has("buffalo_count"):
			out["buffalo_count"] = 1
		if not out.has("lifetime_items_shipped"):
			out["lifetime_items_shipped"] = 0
		if not out.has("stamina_tier"):
			out["stamina_tier"] = 0
		if not out.has("tool_tiers"):
			out["tool_tiers"] = {"watering_can": 1, "hoe": 1, "sickle": 1}
		if not out.has("affinity"):
			out["affinity"] = {}
		if not out.has("active_quests"):
			out["active_quests"] = {}
		if not out.has("veteran_year"):
			out["veteran_year"] = 1
		if not out.has("specialty_sales_this_week"):
			out["specialty_sales_this_week"] = {}
		if not out.has("last_specialty_week"):
			out["last_specialty_week"] = -1
		if not out.has("spouse"):
			out["spouse"] = ""
		if not out.has("married"):
			out["married"] = false
		if not out.has("married_year"):
			out["married_year"] = 0
		if not out.has("child_stage"):
			out["child_stage"] = 0
		out["version"] = 3
	# v3 -> v4: TASK-340 rival win/loss fields (a save from before this
	# task loads as if the player had met nobody and no rival had ever
	# progressed -- fully backward-compatible, no behavior change).
	# Also closes TASK-331's deliberately-deferred milestones_earned
	# persistence gap in the same pass, since a schema bump is already
	# happening here.
	if version < 4:
		if not out.has("npc_first_met_day"):
			out["npc_first_met_day"] = {}
		if not out.has("lost_to_rival"):
			out["lost_to_rival"] = {}
		if not out.has("rival_warning_shown"):
			out["rival_warning_shown"] = {}
		if not out.has("milestones_earned"):
			out["milestones_earned"] = {}
		out["version"] = 4
	# v4 -> v5: TASK-347 rival progress meter + friendship/confession fields.
	# A save from before this task loads as if no rival clock had ever
	# advanced past day-zero and no rival friendship had ever been built --
	# fully backward-compatible, no behavior change.
	if version < 5:
		if not out.has("rival_progress"):
			out["rival_progress"] = {}
		if not out.has("rival_friendship"):
			out["rival_friendship"] = {}
		if not out.has("rival_confessed"):
			out["rival_confessed"] = {}
		out["version"] = 5
	# v5 -> v6: TASK-357 scene_path field. A save from before this task has
	# no scene_path at all (every save was implicitly "in the main scene" —
	# there was only ever one). Default it to the project's actual main
	# scene rather than a hardcoded literal, so this stays correct even if
	# run/main_scene ever changes. player_pos already defaulted to
	# [480, 384] in every prior version, which is exactly the right
	# fallback for a save with no real recorded position.
	if version < 6:
		if not out.has("scene_path"):
			out["scene_path"] = String(ProjectSettings.get_setting(
				"application/run/main_scene", "res://scenes/core/World.tscn"))
		out["version"] = 6
	# v6 -> v7: TASK-358 fish_almanac — first-catch collection log.
	# Pure additive Dict-of-bool (same shape as v4's milestones_earned),
	# so default to {} for any save from before this task: a player who
	# never had a fish_almanac starts with an empty one, fully
	# backward-compatible, no behavior change for existing saves.
	# TASK-363: recipe_unlocks is a NEW additive-Dict-of-bool field saved
	# on top of v7 with NO SAVE_VERSION bump — also default to {} for
	# any save from before this task: a player who never had any recipe
	# unlocks starts with an empty one, fully backward-compatible.
	if version < 7:
		if not out.has("fish_almanac"):
			out["fish_almanac"] = {}
		if not out.has("recipe_unlocks"):
			out["recipe_unlocks"] = {}
		out["version"] = 7
	return out

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var j: Variant = JSON.parse_string(f.get_as_text())
	if j is Dictionary:
		var data: Dictionary = migrate(j as Dictionary)
		var gd: Node = _gd()
		var sb: Node = _sb()
		gd.inventory.clear()
		var inv: Dictionary = data.get("inventory", {}) as Dictionary
		for item_id: String in inv.keys():
			gd.inventory[item_id] = int(inv[item_id])
		gd.harmony = int(data.get("harmony", 0))
		gd.current_season = String(data.get("season", "cool"))
		# TASK-027: restore a11y prefs when present (old saves keep defaults).
		gd.font_scale = float(data.get("font_scale", 1.0))
		gd.high_contrast = bool(data.get("high_contrast", false))
		gd.silver = int(data.get("silver", 0))
		# v3 fields — max_stamina must be restored before current_stamina,
		# since current_stamina's setter clamps to the (already-restored)
		# max_stamina rather than the pre-load default.
		gd.max_stamina = float(data.get("max_stamina", 100.0))
		gd.current_stamina = float(data.get("current_stamina", 100.0))
		gd.infrastructure = (data.get("infrastructure", {}) as Dictionary).duplicate(true)
		gd.daily_offerings = int(data.get("daily_offerings", 0))
		gd.last_offering_day = int(data.get("last_offering_day", -1))
		gd.villager_talked_days = (data.get("villager_talked_days", {}) as Dictionary).duplicate(true)
		gd.binthabat_streak = int(data.get("binthabat_streak", 0))
		gd.last_binthabat_day = int(data.get("last_binthabat_day", -1))
		gd.fishing_skill = int(data.get("fishing_skill", 1))
		gd.mining_skill = int(data.get("mining_skill", 1))
		gd.buffalo_affinity = int(data.get("buffalo_affinity", 0))
		gd.chicken_affinity = int(data.get("chicken_affinity", 0))
		gd.companion_bond = int(data.get("companion_bond", 0))
		gd.chicken_count = int(data.get("chicken_count", 1))
		gd.buffalo_count = int(data.get("buffalo_count", 1))
		gd.lifetime_items_shipped = int(data.get("lifetime_items_shipped", 0))
		gd.stamina_tier = int(data.get("stamina_tier", 0))
		gd.tool_tiers = (data.get("tool_tiers", {"watering_can": 1, "hoe": 1, "sickle": 1}) as Dictionary).duplicate(true)
		gd.affinity = (data.get("affinity", {}) as Dictionary).duplicate(true)
		gd.active_quests = (data.get("active_quests", {}) as Dictionary).duplicate(true)
		gd.veteran_year = int(data.get("veteran_year", 1))
		gd.specialty_sales_this_week = (data.get("specialty_sales_this_week", {}) as Dictionary).duplicate(true)
		gd.last_specialty_week = int(data.get("last_specialty_week", -1))
		gd.spouse = String(data.get("spouse", ""))
		gd.married = bool(data.get("married", false))
		gd.married_year = int(data.get("married_year", 0))
		gd.child_stage = int(data.get("child_stage", 0))
		gd.npc_first_met_day = (data.get("npc_first_met_day", {}) as Dictionary).duplicate(true)
		gd.lost_to_rival = (data.get("lost_to_rival", {}) as Dictionary).duplicate(true)
		gd.rival_warning_shown = (data.get("rival_warning_shown", {}) as Dictionary).duplicate(true)
		gd.milestones_earned = (data.get("milestones_earned", {}) as Dictionary).duplicate(true)
		# TASK-360: restore per-slot decor choice. Default {} matches
		# GameData.decor_choices' initializer exactly, so the absence-on-
		# old-saves case is the same as "never picked a style" — no
		# behaviour change for saves that predate this task.
		gd.decor_choices = (data.get("decor_choices", {}) as Dictionary).duplicate(true)
		# TASK-374: restore placed furniture. Default {} matches
		# GameData.placed_furniture's initializer exactly, so a save from
		# before this task loads as if no furniture was ever placed.
		gd.placed_furniture = (data.get("placed_furniture", {}) as Dictionary).duplicate(true)
		gd.rival_progress = (data.get("rival_progress", {}) as Dictionary).duplicate(true)
		gd.rival_friendship = (data.get("rival_friendship", {}) as Dictionary).duplicate(true)
		gd.rival_confessed = (data.get("rival_confessed", {}) as Dictionary).duplicate(true)
		# TASK-358: fish_almanac first-catch collection log. Defaults to {}
		# for any save from before v7 (the v6->v7 migration block supplies
		# that exact default).
		gd.fish_almanac = (data.get("fish_almanac", {}) as Dictionary).duplicate(true)
		# TASK-363: per-recipe unlock state. Default {} matches
		# GameData.recipe_unlocks' initializer exactly, so the
		# absence-on-old-saves case is the same as "never unlocked
		# anything" — no behaviour change for saves that predate
		# this task. (No SAVE_VERSION bump: additive-safe per
		# task spec.)
		gd.recipe_unlocks = (data.get("recipe_unlocks", {}) as Dictionary).duplicate(true)
		# TASK-357: restore the actual scene + position the save was made in,
		# instead of leaving the player wherever they currently are (which,
		# before this fix, was always whatever the main scene's own default
		# spawn happened to be -- silently wrong for a save made in FarmHouse
		# or any future area).
		var target_scene: String = String(data.get("scene_path",
			String(ProjectSettings.get_setting("application/run/main_scene", "res://scenes/core/World.tscn"))))
		var pp: Array = data.get("player_pos", [480, 384]) as Array
		var target_pos: Vector2 = Vector2(float(pp[0]), float(pp[1])) if pp.size() == 2 else Vector2(480, 384)
		sb.pending_load_position = target_pos
		sb.has_pending_load_position = true
		sb.scene_transition_requested.emit(target_scene, "")
		sb.show_dialogue.emit("System", "Game loaded.")
		return true
	return false
