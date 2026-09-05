extends Node

# GameData — Persistent game state autoload
# Holds stamina, harmony, inventory, and infrastructure state.

# Stamina
var max_stamina: float = 100.0
var current_stamina: float = 100.0:
	set(value):
		current_stamina = clamp(value, 0.0, max_stamina)
		SignalBus.stamina_changed.emit(current_stamina, max_stamina)

# Village harmony (Binthabat offering target)
var harmony: int = 0
var max_harmony: int = 100

# Inventory: item_id -> quantity
var inventory: Dictionary = {}

# Infrastructure: structure_id -> repaired bool
var infrastructure: Dictionary = {}

# Placed furniture: location_id -> Array<{item_id: String, cell: Vector2i}>
var placed_furniture: Dictionary = {}

# Season helper — mirrors TimeManager.season
var current_season: String = "cool"  # hot | monsoon | cool
var current_weather: String = "clear"

# Binthabat morning offering (TASK-004)
var binthabat_yields: Dictionary = {
	"rice_grain": 3,
	"lotus_root": 5,
	"mango": 6,
	"sticky_rice": 4,
}
var daily_offerings: int = 0
var last_offering_day: int = -1

# TASK-025 Evening Market Stall — 1:1 barter pairings per season.
# Bidirectional: (have=sticky_rice, want=rice_grain) and (have=rice_grain,
# want=sticky_rice) are both accepted during the cool season.
# Item ids reuse binthabat_yields entries so the market cycles crops the
# player can actually grow (cool = paddy core, hot = mango, monsoon = lotus).
# Note: typed Dictionary[String, Array[String]] isn't supported in 4.7
# (nested typed collections are a 4.4+ feature but parse-rejected here).
# Use untyped Dictionary + manual casting at the lookup site.
const BARTER_PAIRS: Dictionary = {
	"cool": ["sticky_rice", "rice_grain"],
	"hot": ["mango", "lotus_root"],
	"monsoon": ["lotus_root", "sticky_rice"],
	# TASK-047 coastal trade (market-only goods, boats): unblocks
	# nam_prik / som_tam / tom_yum in recipes.json.
	"coastal_1": ["rice_grain", "fish_sauce"],
	"coastal_2": ["mango", "shrimp_paste"],
	"coastal_3": ["lotus_root", "shrimp_paste"],
	"tools_1": ["rice_grain", "axe"],
}

# Village dialogue / seasonal quest state (TASK-012) — cozy, no heavy exposition
var villager_talked_days: Dictionary = {} # npc_id -> last_day talked
var binthabat_streak: int = 0
var last_binthabat_day: int = -1

# TASK-027 accessibility preferences (persisted via SaveManager v2 fields)
var font_scale: float = 1.0
var high_contrast: bool = false

# TASK-050 fishing skill — 1..4, gates fish.json skill_required tiers.
var fishing_skill: int = 1

# TASK-321 mining skill — 1..3, gates ore.json skill_required tiers.
var mining_skill: int = 1

# TASK-346: uniform 10-level scale used across every affinity-like value
# in the game (romance, buffalo, chicken, companion, and villagers).
# Replaces the previous inconsistent granularities (buffalo/chicken/
# companion used /25.0 = 0-4 "hearts"; romance used hard 25/60/90
# thresholds = ~4 tiers) with one shared 0-10 scale. Values themselves
# stay stored 0-100 exactly as before — this is a pure derived function,
# no schema change.
static func level_for(value: int) -> int:
	return clampi(int(value / 10.0), 0, 10)

# ISSUE-129 buffalo affinity ('hearts'): 0..100, 10 per heart, max 10 hearts.
# TASK-348: scale unified with the romance/chicken/companion 10-level system
# (TASK-346's level_for()). Underlying storage still 0..100 — only the
# derived 0..10 hearts value changed.
var buffalo_affinity: int = 0

func add_buffalo_affinity(amount: int) -> void:
	buffalo_affinity = clampi(buffalo_affinity + amount, 0, 100)

func buffalo_hearts() -> int:
	return level_for(buffalo_affinity)

# TASK-323 chicken affinity ('hearts'): mirrors buffalo pattern, 0..100.
# TASK-348: scale unified with the 10-level system (see buffalo_hearts()).
var chicken_affinity: int = 0

func add_chicken_affinity(amount: int) -> void:
	chicken_affinity = clampi(chicken_affinity + amount, 0, 100)

func chicken_hearts() -> int:
	return level_for(chicken_affinity)

# TASK-325 companion bond: 0..100. TASK-348: scale unified with the 10-level
# system (TASK-346's level_for()); max is now level 10, not the legacy /25.0
# level 4 cap.
var companion_bond: int = 0

func add_companion_bond(amount: int) -> void:
	companion_bond = clampi(companion_bond + amount, 0, 100)

func companion_bond_tier() -> int:
	return level_for(companion_bond)

# TASK-323B herd-size counter. Starts at 1 (a single chicken / a single
# buffalo), grown by breeding on each daily interact once hearts >= 2.
# Cap of 3 is enforced at the breeding call site in
# scenes/entities/ChickenCoop.gd / Buffalo.gd, not here — this var is
# just storage the breed step mutates and the yield step reads (egg
# grant scales with chicken_count, milk grant with buffalo_count).
var chicken_count: int = 1
var buffalo_count: int = 1

# TASK-326 shipping-milestone stamina progression. Every item shipped via
# sell_item / sell_item_premium counts toward lifetime_items_shipped; crossing
# each threshold [25, 50, 100, 200] permanently grants +15 max_stamina and
# +15 current_stamina, capped at tier 4 (160.0 max).
var lifetime_items_shipped: int = 0
var stamina_tier: int = 0

func _check_stamina_milestone() -> void:
	const THRESHOLDS: Array[int] = [25, 50, 100, 200]
	var new_tier: int = 0
	for t: int in THRESHOLDS:
		if lifetime_items_shipped >= t:
			new_tier += 1
	while stamina_tier < new_tier:
		stamina_tier += 1
		max_stamina += 15.0
		current_stamina += 15.0 # setter already clamps + emits stamina_changed

# TASK-331 milestone collectibles — permanent, one-time achievements
# across varied activities (distinct from TASK-326's single-axis
# shipping milestones above). Not yet persisted — see SaveManager.gd
# note; a human-reviewed follow-up adds that (save-format changes are
# always-escalate in this project's pipeline).
var milestones_earned: Dictionary = {}

## Idempotent: returns true only the first time an id is earned (and
## grants the reward then); returns false on every later call for the
## same id, with no further mutation.
func earn_milestone(id: String, reward_harmony: int = 10) -> bool:
	if milestones_earned.get(id, false):
		return false
	milestones_earned[id] = true
	add_harmony(reward_harmony)
	return true

# TASK-358 fish almanac — a first-catch collection log for the fishing
# system. Same idempotent shape as `earn_milestone` (which is a one-shot
# per-id boolean) but tracking every unique (species_id, size) pair ever
# caught, so a species seen as "small" still grants +5 when later caught
# as "big". Keyed by "%s|%s" so persistence stays
# primitives-only — matching the project's existing save-compat
# conventions for Dictionary fields.
var fish_almanac: Dictionary = {}

## Idempotent. Records that (species_id, size) was caught at least once;
## returns true ONLY the first time that exact pair is seen (and grants
## +5 harmony then). All later calls for the same pair return false with
## no further mutation. Mirrors earn_milestone()'s shape exactly so
## SaveManager/save-compat code can treat them uniformly.
func record_catch(species_id: String, size: String) -> bool:
	var key: String = "%s|%s" % [species_id, size]
	if fish_almanac.get(key, false):
		return false
	fish_almanac[key] = true
	add_harmony(5)
	return true

# TASK-060 tool upgrade tiers (1=basic, 2=bronze, 3=iron). Effects:
#   watering_can: watered plots also pre-advance growth (tier*30 effective
#   minutes) and watering costs no stamina above tier 1.
#   hoe: planting stamina cost -20% per tier above 1.
#   sickle: harvest yield +1 per tier above 1.
var tool_tiers: Dictionary = {"watering_can": 1, "hoe": 1, "sickle": 1}

# TASK-378: unified completion tracker (perfection % / checklist screen).
# Purely computed-on-demand aggregation of existing data sources — no new
# persisted schema fields (matches project's default-on-add discipline).
# Simple even-weighted formula: categories completed / categories total.
# Categories: 1) milestones_earned (5 known), 2) fish_almanac (any catches),
# 3) recipe_unlocks (any unlocked), 4) decor_choices (any choices),
# 5) romance completion (spouse non-empty), 6) romance candidates roster
# completion (romanced how many of 6 candidates). Total = 6 categories.

const ROMANCE_CANDIDATE_IDS: Array[String] = ["ek", "fah", "ploy", "klong", "chang", "yaa"]

func completion_percentage() -> float:
	# Plain instance method — GameData is the autoload itself, so this
	# already runs with direct access to its own vars. The original
	# draft used a static method that re-fetched the singleton via
	# Engine.get_main_loop().root.get_node("GameData") as GameData —
	# pointless indirection, and `as GameData` doesn't even parse (no
	# `class_name GameData` exists), which made this whole autoload
	# fail to compile and crash the entire game on boot.
	var milestones_done: int = 0
	for id in ["deep_miner", "master_angler", "inseparable", "herd_keeper", "storm_catch"]:
		if milestones_earned.get(id, false):
			milestones_done += 1

	var completed_categories: int = 0
	if milestones_done == 5:
		completed_categories += 1
	if not fish_almanac.is_empty():
		completed_categories += 1
	if not recipe_unlocks.is_empty():
		completed_categories += 1
	if not decor_choices.is_empty():
		completed_categories += 1
	if spouse != "":
		completed_categories += 1

	var romance_candidates_done: int = 0
	for candidate_id in ROMANCE_CANDIDATE_IDS:
		if affinity.has(candidate_id) and level_for(int(affinity[candidate_id])) >= 5:
			romance_candidates_done += 1
	if romance_candidates_done >= 1:
		completed_categories += 1

	return float(completed_categories) / 6.0 * 100.0

func tool_tier(tool_id: String) -> int:
	return int(tool_tiers.get(tool_id, 1))

func upgrade_tool(tool_id: String) -> bool:
	var tier: int = tool_tier(tool_id)
	if tier >= 3:
		return false
	var cost: int = tier * 8 # rice-grain barter price: 8, 16
	if not has_item("rice_grain", cost):
		return false
	# TASK-321: ore material sink. tier 1->2 needs 2x copper_ore; tier 2->3
	# needs 2x iron_ore. Additive on top of the rice_grain cost (unchanged).
	var ore_id: String = "copper_ore" if tier == 1 else "iron_ore"
	var ore_cost: int = 2
	if not has_item(ore_id, ore_cost):
		return false
	remove_item("rice_grain", cost)
	remove_item(ore_id, ore_cost)
	tool_tiers[tool_id] = tier + 1
	SignalBus.tool_upgraded.emit(tool_id, tier + 1)
	return true

# TASK-360 farmhouse decor anchor-slots. Per-slot style choice, persisted
# alongside the rest of the inventory-style Dictionaries (tool_tiers,
# affinity, etc.). The absence of a key for a given slot means "use the
# base / default style" — no migration needed for existing saves that
# have nothing chosen yet (matches tool_tiers' default-initializer shape).
#
# Catalogue of all valid (slot, style) pairs the player can ever own. New
# slots/styles MUST be added here in two places: the catalogue (this file),
# and the MarketManager.BUY_OFFERS list (so it can actually be purchased).
# Single source of truth: the market's BUY_OFFERS rows below must use the
# same item_id strings declared in `purchased` here — otherwise purchase
# succeeds but the style picker silently never unlocks.
var decor_choices: Dictionary = {}

# Each entry: slot -> { "default": "<style>", "styles": { style -> item_id } }
# `item_id` is what the market sells and what the player must own (>=1 in
# inventory) before the style is selectable; it is *not* consumed — picking
# a style is free, only purchasing it is gated. The first style in the
# `styles` map is also the fallback returned by decor_choice() when no
# explicit choice has been stored yet.
const DECOR_CATALOGUE: Dictionary = {
	"shrine": {
		"default": "basic",
		"styles": {
			"basic": "",
			"ornate": "ornate_shrine_blueprint",
		},
	},
	"bed": {
		"default": "basic",
		"styles": {
			"basic": "",
			"ornate": "ornate_bed_blueprint",
		},
	},
}

func _decor_default_style(slot: String) -> String:
	# Internal helper — the catalogue's "default" key for a slot, or
	# "basic" if the slot isn't catalogued at all (defensive: missing
	# catalogue entry should not break the lookup path).
	if not DECOR_CATALOGUE.has(slot):
		return "basic"
	return String((DECOR_CATALOGUE[slot] as Dictionary).get("default", "basic"))

func decor_choice(slot: String) -> String:
	# Returns the stored style for `slot`, or the catalogue's default
	# style when unset. An unset key MUST NOT be persisted (we only
	# write on explicit set_decor_choice calls) so a save/load round
	# trip of an untouched slot continues to return the default —
	# matching the spec's "absence means base/default style" contract.
	return String(decor_choices.get(slot, _decor_default_style(slot)))

func set_decor_choice(slot: String, style: String) -> bool:
	# Validates the (slot, style) pair against DECOR_CATALOGUE and
	# ownership before mutating. Returns true on accepted change,
	# false on rejected (unknown slot, unknown style for the slot, or
	# the style requires an item the player doesn't hold).
	if not DECOR_CATALOGUE.has(slot):
		return false
	var styles: Dictionary = (DECOR_CATALOGUE[slot] as Dictionary).get("styles", {}) as Dictionary
	if not styles.has(style):
		return false
	var required_item: String = String(styles[style])
	if not required_item.is_empty() and not has_item(required_item, 1):
		return false
	decor_choices[slot] = style
	return true

## All (slot, style) pairs the player can currently select — a style is
## "owned" when its required item is in inventory (the market blueprint is
## never consumed, so picking a style is always free once purchased).
## Used by the style picker interactable to drive its cycle list.
func owned_decor_styles(slot: String) -> Array[String]:
	var out: Array[String] = []
	if not DECOR_CATALOGUE.has(slot):
		return out
	var styles: Dictionary = (DECOR_CATALOGUE[slot] as Dictionary).get("styles", {}) as Dictionary
	for style_id: String in styles.keys():
		var required: String = String(styles[style_id])
		if required.is_empty() or has_item(required, 1):
			out.append(style_id)
	return out

# TASK-051 affinity/dating MVP — npc_id -> 0..100. Tiers (25/60/90) map to
# DialogueDB's stranger/friendly/close/romantic branches. No marriage/
# jealousy systems (explicitly out of scope per PO_INBOX r6).
var affinity: Dictionary = {}
const AFFINITY_CAP: int = 100

# TASK-363: recipe discovery via villager friendship (gift-based unlocks).
# Idempotent set: recipe_id -> true once unlocked. Empty by default, so
# a fresh game / a save from before this task has no unlocks — which
# is the exact same state as "every gated recipe is still locked", so
# no migration is required (mirrors the milestones_earned /
# fish_almanac / decor_choices additive-Dict discipline).
# CookingStation filters RECIPE_UNLOCKS_BY_NPC's nested recipe keys
# against this dict to decide which recipes are craftable.
var recipe_unlocks: Dictionary = {}

# Curated mapping: which NPC teaches which recipe at which friendship
# level (0-10 scale via level_for()). Every triple is cross-referenced
# against scripts/narrative/DialogueDB.gd's GIFT_PREFERENCES so each
# NPC's "teach me X" matches a recipe they actually love/like, instead
# of being arbitrary. Required levels stay in the reachable early-mid
# range (2-4) — these are milestone-of-care unlocks, not end-game
# rewards. Simple staple / ingredient-prep recipes (rice_flour,
# sticky_rice_flour, coconut_milk, palm_sugar, tofu, khai_jiao, etc.)
# are deliberately NOT in this table, so they stay always-craftable
# exactly as today and early cooking is never gated behind a
# relationship.
#
#  ploy    -> mango_sticky_rice  (lvl 3) — she loves it; hot-season
#                                      festival dessert, mango season.
#  ploy    -> banana_rice_cake   (lvl 4) — she also loves it; her
#                                      second dessert, slightly higher
#                                      investment than the mango one.
#  fah     -> lotus_soup         (lvl 3) — she loves it AND lotus_root;
#                                      monsoon, ties into the Lotus
#                                      Maze gathering loop.
#  elder   -> kluay_buat_chi     (lvl 3) — she likes banana; a gentle
#                                      banana-in-coconut-milk dessert
#                                      that fits her sweet tooth (no
#                                      direct loved match, but the
#                                      elder's only dessert is the
#                                      rice_cake and ploy already
#                                      teaches that one).
#  klong   -> pandan_sticky_rice (lvl 3) — she loves it; monsoon
#                                      seasonal that requires
#                                      sluice_gate.
#  child   -> durian_sticky_rice (lvl 3) — child loves durian; the
#                                      festival-tier durian dessert,
#                                      hot season.
#  nok     -> khao_tan           (lvl 3) — nok loves sticky_rice;
#                                      market-stall sesame rice
#                                      crackers, any season.
#  handler -> tom_yum            (lvl 3) — handler loves it; the
#                                      village's sour-spicy soup, any
#                                      season.
const RECIPE_UNLOCKS_BY_NPC: Dictionary = {
	"ploy":    {"mango_sticky_rice": 3, "banana_rice_cake": 4},
	"fah":     {"lotus_soup": 3},
	"elder":   {"kluay_buat_chi": 3},
	"klong":   {"pandan_sticky_rice": 3},
	"child":   {"durian_sticky_rice": 3},
	"nok":     {"khao_tan": 3},
	"handler": {"tom_yum": 3},
}

## Idempotent. Returns true only the first time recipe_id is unlocked;
## returns false on every later call for the same id, with no further
## mutation. Mirrors earn_milestone()'s shape so the unlock state
## survives the same save/load round-trip treatment, but with NO
## harmony side effect — the unlock IS the reward; the caller decides
## what dialogue/feedback to fire from the true return.
func unlock_recipe(recipe_id: String) -> bool:
	if recipe_unlocks.get(recipe_id, false):
		return false
	recipe_unlocks[recipe_id] = true
	return true

# Is recipe_id gated at all (i.e. is it listed as a teachable recipe
# for any NPC in RECIPE_UNLOCKS_BY_NPC)? Recipes that aren't gated are
# always-craftable; recipes that are gated are craftable iff
# recipe_unlocks[recipe_id] is true. Mirrors the shape CookingStation's
# filter needs to do its single-line check.
func is_recipe_gated(recipe_id: String) -> bool:
	for npc_id: String in RECIPE_UNLOCKS_BY_NPC.keys():
		if (RECIPE_UNLOCKS_BY_NPC[npc_id] as Dictionary).has(recipe_id):
			return true
	return false

# Cached recipe_id -> display_name lookup, lazily loaded from
# data/recipes/recipes.json on first use. Same path CookingStation.gd
# already uses for its _recipes array, so we don't duplicate a full
# JSON parse just to get a friendly name for one show_dialogue line.
static var _recipe_display_name_cache: Dictionary = {}

func _recipe_display_name(recipe_id: String) -> String:
	# Returns the human-readable name from recipes.json for use in the
	# "New recipe unlocked: <name>!" dialogue. Falls back to the raw
	# id if the JSON is missing the entry (defensive: the catalogue
	# is the source of truth, the JSON is the display layer).
	if _recipe_display_name_cache.has(recipe_id):
		return String(_recipe_display_name_cache[recipe_id])
	var f: FileAccess = FileAccess.open(
		"res://data/recipes/recipes.json", FileAccess.READ)
	if f == null:
		_recipe_display_name_cache[recipe_id] = recipe_id
		return recipe_id
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary and (parsed as Dictionary).has("recipes"):
		for r in (parsed as Dictionary)["recipes"]:
			if r is Dictionary and String((r as Dictionary).get("id", "")) == recipe_id:
				var name_str: String = String((r as Dictionary).get("display_name", recipe_id))
				_recipe_display_name_cache[recipe_id] = name_str
				return name_str
	_recipe_display_name_cache[recipe_id] = recipe_id
	return recipe_id

# Internal helper: called by add_affinity() after a successful mutation.
# For the given npc_id, fires at most ONE unlock per call: the first
# recipe in RECIPE_UNLOCKS_BY_NPC[npc_id] whose required_level is now
# met (post-mutation level >= required_level) but WASN'T met before
# (pre_level < required_level), and that isn't already unlocked. On a
# successful unlock, emits the standard "New recipe unlocked: <name>!"
# System dialogue so the player has a one-line feedback hook without
# needing a new UI screen.
#
# One-recipe-per-call is deliberate: a single +N gift can cross
# multiple thresholds, but stacking N unlock toasts in one frame
# would be noisy. The next add_affinity() (next gift/talk) will pick
# up the next one naturally.
func _check_recipe_unlocks(npc_id: String, pre_level: int) -> void:
	if not RECIPE_UNLOCKS_BY_NPC.has(npc_id):
		return
	var npc_recipes: Dictionary = RECIPE_UNLOCKS_BY_NPC[npc_id] as Dictionary
	var post_level: int = level_for(int(affinity.get(npc_id, 0)))
	for recipe_id: String in npc_recipes.keys():
		var required: int = int(npc_recipes[recipe_id])
		if pre_level < required and post_level >= required:
			if unlock_recipe(recipe_id):
				SignalBus.show_dialogue.emit("System",
					"New recipe unlocked: %s!" % _recipe_display_name(recipe_id))
				return

## v1 gift rule: any of these held items is gift-able (no per-NPC table yet).
const FOOD_ITEMS: Array[String] = [
	"rice_grain", "sticky_rice", "mango", "durian", "banana", "egg",
	"thai_basil", "lotus_root", "pandan_leaf", "banana_leaf",
	"thai_basil_stirfry", "pandan_sticky_rice", "mango_sticky_rice",
	"durian_sticky_rice", "lotus_soup", "banana_rice_cake",
	"nam_prik", "som_tam", "tom_yum",
]

# TASK-053 quest-state primitive: quest_id -> {"stage": int, "objectives_done": Array[String]}
var active_quests: Dictionary = {}

# TASK-280 long-term play: veteran-year scaling. Each completed year
# grants +1 flat bonus yield on harvests (Year 2 = +1, Year 3 = +2, cap 3)
# and a veteran dialogue flavor line — repetition softening without new chains.
var veteran_year: int = 1

func veteran_yield_bonus() -> int:
	return clampi(veteran_year - 1, 0, 3)

# ISSUE-135 (owner-reversed decision): SILVER currency economy. Wallet +
# sell prices; barter system coexists (1:1 trades remain valid). Market
# stall handles sell (items -> silver) and buy (silver -> goods).
var silver: int = 0

## Sell prices (silver per unit). Items not listed are not sellable.
const SELL_PRICES: Dictionary = {
	"rice_grain": 2, "sticky_rice": 4, "mango": 5, "durian": 8, "banana": 4,
	"egg": 4, "buffalo_milk": 5, "buffalo_milk_high": 9, "egg_gold": 7, "goat_milk": 6, "wood": 3, "banana_leaf": 2,
	"lotus_root": 5, "thai_basil": 3, "pandan_leaf": 3, "banana_leaf_stem": 2,
	"thai_basil_stirfry": 14, "pandan_sticky_rice": 15, "mango_sticky_rice": 14,
	"durian_sticky_rice": 18, "lotus_soup": 16, "banana_rice_cake": 12,
	"nam_prik": 16, "som_tam": 15, "tom_yum": 18, "wan_sart_basket": 10,
	"khao_soi": 20, "massaman_curry": 24,
}

func add_silver(amount: int) -> void:
	silver = maxi(0, silver + amount)
	SignalBus.silver_changed.emit(silver)

func spend_silver(amount: int) -> bool:
	if silver < amount:
		return false
	silver -= amount
	SignalBus.silver_changed.emit(silver)
	return true

## Sell one unit of an item; returns silver gained (0 if unsellable/not held).
func sell_item(item_id: String) -> int:
	var price: int = int(SELL_PRICES.get(item_id, 0))
	if price <= 0 or not has_item(item_id, 1):
		return 0
	if not remove_item(item_id, 1):
		return 0
	add_silver(price)
	lifetime_items_shipped += 1
	_check_stamina_milestone()
	return price

## Cheapest sellable item currently held (market sells lowest-value first).
func cheapest_sellable() -> String:
	var best: String = ""
	var best_price: int = 0
	for item_id: String in inventory.keys():
		var price: int = int(SELL_PRICES.get(item_id, 0))
		if price > 0 and int(inventory[item_id]) > 0:
			if best == "" or price < best_price:
				best = item_id
				best_price = price
	return best

## TASK-344: Priciest sellable item currently held (Coastal Trading Post
## sells the highest-value item, mirroring cheapest_sellable()'s shape
## with the comparison inverted). Used by CoastalTradingPost.trade()
## — returns "" when nothing sellable is held.
func priciest_sellable() -> String:
	var best: String = ""
	var best_price: int = 0
	for item_id: String in inventory.keys():
		var price: int = int(SELL_PRICES.get(item_id, 0))
		if price > 0 and int(inventory[item_id]) > 0:
			if best == "" or price > best_price:
				best = item_id
				best_price = price
	return best

# TASK-313 3-channel sell economy: Channel A (Cart, base), B (Market +15%), C (Specialty +45% gated).
# Specialty weekly cap tracking (Binthabat-style daily reset, but 7-day window).
var specialty_sales_this_week: Dictionary = {} # npc_id -> count this week
var last_specialty_week: int = -1

func _get_specialty_week(day: int) -> int:
	return int(day / 7)

func _reset_specialty_if_new_week(day: int) -> void:
	var week: int = _get_specialty_week(day)
	if week != last_specialty_week:
		specialty_sales_this_week.clear()
		last_specialty_week = week

func can_specialty_sell(npc_id: String, day: int) -> bool:
	_reset_specialty_if_new_week(day)
	if get_affinity(npc_id) < 60:
		return false
	return int(specialty_sales_this_week.get(npc_id, 0)) < 3

func record_specialty_sale(npc_id: String, day: int) -> void:
	_reset_specialty_if_new_week(day)
	specialty_sales_this_week[npc_id] = int(specialty_sales_this_week.get(npc_id, 0)) + 1

# TASK-333 (2026-09-02): weekly interaction streak — a non-punishing
# alternative to affinity decay, which was flagged as conflicting with
# this project's established no-fail-state precedent (TASK-319/324).
# Keeping up an interaction with an NPC every week grants a small BONUS
# on top of normal affinity gains; missing a week only forfeits that
# week's bonus and resets the streak to restart — it never reduces
# affinity already earned. Reuses _get_specialty_week's week concept.
var npc_weekly_streak: Dictionary = {} # npc_id -> consecutive weeks interacted
var npc_last_interaction_week: Dictionary = {} # npc_id -> week int of last count

## Call on any affinity-bearing interaction with npc_id. Returns the bonus
## affinity to grant this call (0 on most calls — only when the streak
## actually advances past its first week, and only once per npc per week).
func record_weekly_engagement(npc_id: String, day: int) -> int:
	var week: int = _get_specialty_week(day)
	var last_week: int = int(npc_last_interaction_week.get(npc_id, -999))
	if last_week == week:
		return 0 # already counted this NPC this week
	if last_week == week - 1:
		npc_weekly_streak[npc_id] = int(npc_weekly_streak.get(npc_id, 0)) + 1
	else:
		npc_weekly_streak[npc_id] = 1 # first interaction, or streak broken — restart
	npc_last_interaction_week[npc_id] = week
	var streak: int = int(npc_weekly_streak[npc_id])
	if streak < 2:
		return 0 # first week of a streak just establishes it, no bonus yet
	return mini(streak - 1, 5) # +1 affinity per streak week, capped at +5

func get_sell_price(item_id: String, channel: String) -> int:
	var base: int = int(SELL_PRICES.get(item_id, 0))
	if base <= 0:
		return 0
	match channel:
		"market":
			return int(ceil(base * 1.15))
		"coastal":
			# TASK-344: between market (+15%) and specialty (+45%). The
			# Coastal Trading Post sells the priciest held item at this
			# mid-tier premium.
			return int(ceil(base * 1.25))
		"specialty":
			return int(ceil(base * 1.45))
		_:
			return base

func sell_item_premium(item_id: String, channel: String) -> int:
	var price: int = get_sell_price(item_id, channel)
	if price <= 0 or not has_item(item_id, 1):
		return 0
	if not remove_item(item_id, 1):
		return 0
	add_silver(price)
	lifetime_items_shipped += 1
	_check_stamina_milestone()
	return price

# TASK-059 romance payoff: spouse npc_id ("" until wed). Proposal requires
# romantic tier (affinity >= 90) + a krathong as the offering. One spouse.
var spouse: String = ""
var married: bool = false

# TASK-324 life progression. `married_year` records the calendar year of the
# wedding (set at proposal; 0 until then or for test paths that bypass
# proposal). `child_stage` advances 0 -> 1 -> 2 -> 3 on anniversary calls:
# 0 = none, 1 = pregnant, 2 = born, 3 = toddler (terminal, no further bonuses).
var married_year: int = 0
var child_stage: int = 0

# TASK-340 rival win/loss system. npc_first_met_day: npc_id -> day the
# player first ever interacted with them (clock start). lost_to_rival:
# npc_id -> true once the rival has won (permanent, one-way). No other
# consequence — the candidate remains a normal friendly NPC.
# rival_warning_shown: npc_id -> highest warning index (0-3) already
# surfaced, so a warning line is shown at most once per threshold.
var npc_first_met_day: Dictionary = {}
var lost_to_rival: Dictionary = {}
var rival_warning_shown: Dictionary = {}
# TASK-347: rival_progress replaces pure day-elapsed tracking for the win/
# loss clock -- candidate_id -> float 0-100 (100 = the rival wins), advances
# automatically ~1.11/day (100/RivalClock.WINDOW_DAYS) and is nudgeable by
# festival wins/losses via RivalClock.nudge_progress(). rival_friendship /
# rival_confessed are for TASK-342's rival gift/confession system -- this
# task only adds the fields, TASK-342 owns the behavior.
var rival_progress: Dictionary = {}
var rival_friendship: Dictionary = {}
var rival_confessed: Dictionary = {}

func start_quest(quest_id: String, objective_count: int = 0) -> void:
	if active_quests.has(quest_id):
		return
	active_quests[quest_id] = {"stage": 0, "objectives_done": [], "objective_count": objective_count}

func advance_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	var q: Dictionary = active_quests[quest_id] as Dictionary
	q["stage"] = int(q.get("stage", 0)) + 1

func complete_objective(quest_id: String, objective_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	var q: Dictionary = active_quests[quest_id] as Dictionary
	var done: Array = q.get("objectives_done", []) as Array
	if not done.has(objective_id):
		done.append(objective_id)
	q["objectives_done"] = done

func is_quest_complete(quest_id: String) -> bool:
	if not active_quests.has(quest_id):
		return false
	var q: Dictionary = active_quests[quest_id] as Dictionary
	var total: int = int(q.get("objective_count", 0))
	return total > 0 and (q.get("objectives_done", []) as Array).size() >= total

func add_affinity(npc_id: String, amount: int) -> void:
	# TASK-363: capture the pre-mutation level so the unlock check fires
	# ONLY on the exact add_affinity() call that crosses a recipe's
	# required_level (i.e. we just became high enough, not the many calls
	# that follow while staying high enough). Without this snapshot, a
	# single +5 gift on a level-3 NPC would re-fire the unlock on every
	# subsequent add_affinity() while they sit at level 3.
	var pre_level: int = level_for(int(affinity.get(npc_id, 0)))
	affinity[npc_id] = clampi(int(affinity.get(npc_id, 0)) + amount, 0, AFFINITY_CAP)
	_check_recipe_unlocks(npc_id, pre_level)

func get_affinity(npc_id: String) -> int:
	return int(affinity.get(npc_id, 0))

func add_item(item_id: String, amount: int = 1) -> void:
	inventory[item_id] = inventory.get(item_id, 0) + amount

func remove_item(item_id: String, amount: int = 1) -> bool:
	if inventory.get(item_id, 0) < amount:
		return false
	inventory[item_id] -= amount
	if inventory[item_id] <= 0:
		inventory.erase(item_id)
	return true

func has_item(item_id: String, amount: int = 1) -> bool:
	return inventory.get(item_id, 0) >= amount

func add_harmony(amount: int) -> void:
	harmony = clamp(harmony + amount, 0, max_harmony)
	SignalBus.village_harmony_changed.emit(harmony)
	SignalBus.village_goodwill_changed.emit(harmony)

func repair_infrastructure(structure_id: String) -> void:
	infrastructure[structure_id] = true
	SignalBus.infrastructure_repaired.emit(structure_id)

func is_repaired(structure_id: String) -> bool:
	return infrastructure.get(structure_id, false)

# --- Placed furniture API (TASK-374) ---
func add_placed_furniture(location_id: String, item_id: String, cell: Vector2i) -> bool:
	# Returns false if the cell is invalid or already occupied.
	var list: Array = placed_furniture.get(location_id, [])
	for entry in list:
		if entry.cell == cell:
			return false # already occupied
	# Optionally enforce grid bounds and occupied tile restrictions (caller should validate).
	list.append({"item_id": item_id, "cell": cell})
	placed_furniture[location_id] = list
	SignalBus.placed_furniture_changed.emit(location_id, item_id, cell, true)
	return true

func remove_placed_furniture(location_id: String, item_id: String, cell: Vector2i) -> bool:
	var list: Array = placed_furniture.get(location_id, [])
	for i in range(list.size()):
		var entry = list[i]
		if entry.cell == cell and entry.item_id == item_id:
			list.remove_at(i)
			placed_furniture[location_id] = list
			if list.is_empty():
				placed_furniture.erase(location_id)
			SignalBus.placed_furniture_changed.emit(location_id, item_id, cell, false)
			return true
	return false

func get_placed_furniture_at(location_id: String, cell: Vector2i) -> Dictionary:
	var list: Array = placed_furniture.get(location_id, [])
	for entry in list:
		if entry.cell == cell:
			return entry
	return {}

func has_placed_furniture_at(location_id: String, cell: Vector2i) -> bool:
	var list: Array = placed_furniture.get(location_id, [])
	for entry in list:
		if entry.cell == cell:
			return true
	return false

# --- TASK-025 Market Stall 1:1 barter ---

func _is_valid_barter_pair(have_id: String, want_id: String) -> bool:
	# Bidirectional pair check: any pair (a, b) is also accepted as (b, a).
	for pair in BARTER_PAIRS.values():
		var p: Array = pair as Array
		if (p[0] == have_id and p[1] == want_id) or (p[0] == want_id and p[1] == have_id):
			return true
	return false

func barter(have_id: String, want_id: String) -> bool:
	# Validates inventory ownership and pair membership before mutating.
	# Soft-fail returns false (no exception, no removal) — the caller emits
	# a "Not enough to trade." dialogue. Zero combat, zero gold, zero fail.
	if not _is_valid_barter_pair(have_id, want_id):
		return false
	if not has_item(have_id, 1):
		return false
	if not remove_item(have_id, 1):
		return false
	add_item(want_id, 1)
	SignalBus.barter_completed.emit(have_id, want_id)
	return true

func reset_stamina() -> void:
	current_stamina = max_stamina

# --- Binthabat offering API (TASK-004) ---

func can_offer_today(day: int) -> bool:
	# One offering per calendar day. If the queried day differs from the last
	# offering day, the slot is free regardless of the counter value.
	if last_offering_day != day:
		return true
	return daily_offerings < 1

func offer_bin_thabat(item_id: String, day: int) -> int:
	# Returns harmony yield on success, 0 on failure.
	# Validates daily limit, item validity, and inventory ownership before
	# deducting the item, adding harmony, and emitting signals.
	if not can_offer_today(day):
		return 0
	if not binthabat_yields.has(item_id):
		return 0
	if not has_item(item_id, 1):
		return 0
	# Reset daily counter when the calendar rolls over.
	if last_offering_day != day:
		daily_offerings = 0
	var harmony_yield: int = int(binthabat_yields[item_id])
	# Inventory deduction must succeed after earlier check.
	if not remove_item(item_id, 1):
		return 0
	add_harmony(harmony_yield)
	daily_offerings += 1
	last_offering_day = day
	# TASK-012 streak: consecutive-day alms, no fail state, cozy bonus only.
	if last_binthabat_day == day - 1:
		binthabat_streak += 1
	elif last_binthabat_day != day:
		binthabat_streak = 1
	last_binthabat_day = day
	SignalBus.binthabat_offered.emit(item_id, harmony_yield)
	return harmony_yield
# TASK-023 typing hardening — typed accessors for gdlint clean
func get_inventory_item(id: String) -> int:
	return int(inventory.get(id, 0))

func get_infrastructure_state(id: String) -> bool:
	return bool(infrastructure.get(id, false))
