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

const SAVE_PATH: String = "user://savegame.json"
const SAVE_VERSION: int = 3

# Dynamic autoload helpers — safe in main scene, --script, and packaged export.
func _gd() -> Node:
	return Engine.get_main_loop().root.get_node("GameData")

func _sb() -> Node:
	return Engine.get_main_loop().root.get_node("SignalBus")

func save_game() -> bool:
	var gd: Node = _gd()
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"player_pos": [480, 384],
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
		sb.show_dialogue.emit("System", "Game loaded.")
		return true
	return false
