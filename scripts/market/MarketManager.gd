extends Node
## MarketManager — TASK-025 Evening Market Stall (Cozy Gameplay)
## Scene-attached Node (NOT an autoload — instantiated by MarketStall.tscn).
## Owns the seasonal 1:1 barter offer table and caches the active offer in
## sync with SignalBus.season_changed. Decoupled from UI: callers query
## get_offers(season) and the rest of the world listens via SignalBus.

# Per-season offer table. Single entry per season (TASK-025 spec).
# `label` is a human-readable hint for any prompt UI; barter logic only
# reads `have` and `want`.
# TASK-047: per-season OFFER LIST (was single dict). Coastal-trade goods
# fish_sauce / shrimp_paste arrive with the boats (hot/monsoon) — they are
# market-only by design (fermented, not farm-growable) and unblock
# nam_prik / som_tam / tom_yum in recipes.json.
const OFFERS: Dictionary[String, Array] = {
	"cool": [
		{"have": "sticky_rice", "want": "rice_grain", "label": "Sticky rice <-> Rice grain"},
	],
	"hot": [
		{"have": "mango",       "want": "lotus_root",   "label": "Mango <-> Lotus root"},
		{"have": "rice_grain",  "want": "fish_sauce",   "label": "Rice grain <-> Fish sauce (boats)"},
		{"have": "mango",       "want": "shrimp_paste", "label": "Mango <-> Shrimp paste (boats)"},
	],
	"monsoon": [
		{"have": "lotus_root",  "want": "sticky_rice",  "label": "Lotus root <-> Sticky rice"},
		{"have": "rice_grain",  "want": "fish_sauce",   "label": "Rice grain <-> Fish sauce (boats)"},
		{"have": "lotus_root",  "want": "shrimp_paste", "label": "Lotus root <-> Shrimp paste (boats)"},
	],
}

# ISSUE-135 silver economy: goods purchasable with silver. Prices scale
# gently by season (coastal goods cheaper in monsoon, boats in port).
# TASK-327: seed entries added per crop's allowed_seasons (data/crops/*.tres).
# jasmine_rice intentionally excluded — stays free via GridManager.plant()'s
# existing exception, not duplicated as a purchase.
const BUY_OFFERS: Dictionary[String, Array] = {
	"cool": [
		{"item": "fish_sauce", "price": 18},
		{"item": "shrimp_paste", "price": 20},
		{"item": "axe", "price": 30},
		# TASK-360: ornate_shrine_blueprint unlocks the "ornate" style for the
		# FarmHouseShrine decor slot. item_id MUST match the string in
		# GameData.DECOR_CATALOGUE exactly — any drift silently locks the
		# blueprint out of every owned_decor_styles() check. Listed in all
		# three seasons (the decor slot isn't season-gated, no reason to
		# gate the purchase either). Price sits between the wood-cutting
		# tools (axe=30, machete=45) and the heaviest decor so a player
		# who's done a few carpenter upgrades can afford it without
		# grinding a full season.
		{"item": "ornate_shrine_blueprint", "price": 50},
		# TASK-367: ornate_bed_blueprint unlocks the "ornate" style for the
		# FarmHouseBed decor slot -- same convention as ornate_shrine_blueprint
		# above (item_id must match GameData.DECOR_CATALOGUE exactly, not
		# season-gated, listed in all three seasons).
		{"item": "ornate_bed_blueprint", "price": 50},
		{"item": "seed_cabbage", "price": 8},
		{"item": "seed_garlic", "price": 8},
		{"item": "seed_lettuce", "price": 8},
		{"item": "seed_tomato", "price": 10},
		{"item": "seed_pandan", "price": 15},
		{"item": "seed_coconut", "price": 20},
		{"item": "seed_eggplant", "price": 12},
		{"item": "seed_papaya", "price": 20},
		{"item": "seed_soybean", "price": 12},
		{"item": "seed_sticky_rice", "price": 15},
		{"item": "seed_basil", "price": 12},
		# TASK-374: floor_rug placeable decor for FarmHouse interior. Reuses
		# existing cloth textures (mohom_cloth.png or pha_khao_ma.png). Not
		# season-gated (a decor item, unlike seeds) -- price sits between
		# the basic seeds (8-15) and tools (30-50) to be accessible early.
		{"item": "floor_rug", "price": 25},
		# TASK-375: floor_cushion — a smaller cloth decor (reuses
		# pha_khao_ma.png). Priced below floor_rug (25) because a
		# cushion is a smaller/simpler decor piece — the rug is the
		# "anchor" floor decor and the cushion is the secondary accent,
		# so 15 keeps the pair together below the tool tier (axe=30,
		# machete=45).
		{"item": "floor_cushion", "price": 15},
		# TASK-375: small_table — the largest decor piece in the new
		# trio (reuses clay_stove.png as a placeholder until proper
		# table art exists). Priced at 30 — above floor_rug (25) and
		# floor_cushion (15) because a table is a more substantial
		# furniture piece, but still below the heavy tools (45) so
		# it's an attainable mid-game home improvement.
		{"item": "small_table", "price": 30},
		{"item": "seed_yardlong_bean", "price": 12},
	],
	"hot": [
		{"item": "fish_sauce", "price": 14},
		{"item": "shrimp_paste", "price": 16},
		{"item": "fishing_rod", "price": 40},
		{"item": "ornate_shrine_blueprint", "price": 50},
		{"item": "ornate_bed_blueprint", "price": 50},
		{"item": "floor_rug", "price": 25},
		# TASK-375: floor_cushion — see the cool-season entry above
		# for the price-reasoning comment (identical placement across
		# all three seasons because decor is not season-gated).
		{"item": "floor_cushion", "price": 15},
		# TASK-375: small_table — see the cool-season entry above.
		{"item": "small_table", "price": 30},
		{"item": "seed_banana", "price": 15},
		{"item": "seed_chili", "price": 9},
		{"item": "seed_durian", "price": 30},
		{"item": "seed_mango", "price": 30},
		{"item": "seed_peanut", "price": 9},
		{"item": "seed_sesame", "price": 9},
		{"item": "seed_sugarcane", "price": 18},
		{"item": "seed_watermelon", "price": 18},
		{"item": "seed_coconut", "price": 20},
		{"item": "seed_eggplant", "price": 12},
		{"item": "seed_papaya", "price": 20},
		{"item": "seed_soybean", "price": 12},
		{"item": "seed_sticky_rice", "price": 15},
		{"item": "seed_basil", "price": 12},
		{"item": "seed_yardlong_bean", "price": 12},
	],
	"monsoon": [
		{"item": "fish_sauce", "price": 12},
		{"item": "shrimp_paste", "price": 14},
		{"item": "ornate_shrine_blueprint", "price": 50},
		{"item": "ornate_bed_blueprint", "price": 50},
		{"item": "floor_rug", "price": 25},
		# TASK-375: floor_cushion — see the cool-season entry above.
		{"item": "floor_cushion", "price": 15},
		# TASK-375: small_table — see the cool-season entry above.
		{"item": "small_table", "price": 30},
		{"item": "seed_ginger", "price": 10},
		{"item": "seed_lotus", "price": 12},
		{"item": "seed_taro", "price": 10},
		{"item": "seed_water_spinach", "price": 10},
		{"item": "seed_pandan", "price": 15},
		{"item": "seed_coconut", "price": 20},
		{"item": "seed_eggplant", "price": 12},
		{"item": "seed_papaya", "price": 20},
		{"item": "seed_soybean", "price": 12},
		{"item": "seed_sticky_rice", "price": 15},
		{"item": "seed_basil", "price": 12},
		{"item": "seed_yardlong_bean", "price": 12},
		{"item": "machete", "price": 45},
	],
}

## Silver buy offers for a season (fresh array per call).
func get_buy_offers(season: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if BUY_OFFERS.has(season):
		for offer: Dictionary in BUY_OFFERS[season]:
			out.append(offer)
	return out

# Cached offers for the season we last saw via SignalBus.season_changed.
# Updated by the listener; read by any prompt/HUD code that wants the
# current season's offering without re-querying OFFERS.
var _current_offers: Array[Dictionary] = []

func _ready() -> void:
	_refresh_offers(get_current_season())
	SignalBus.season_changed.connect(_on_season_changed)

func _on_season_changed(new_season: String) -> void:
	_refresh_offers(new_season)

func _refresh_offers(season: String) -> void:
	_current_offers.clear()
	if OFFERS.has(season):
		for offer: Dictionary in OFFERS[season]:
			_current_offers.append(offer)

func get_offers(season: String) -> Array[Dictionary]:
	# Per-call season lookup so callers can query any season without forcing
	# a state change. Returns a fresh Array each call to avoid the caller
	# mutating the internal cache.
	var out: Array[Dictionary] = []
	if OFFERS.has(season):
		for offer: Dictionary in OFFERS[season]:
			out.append(offer)
	return out

func get_current_season() -> String:
	# Prefer the registered TimeManager (ENGINE-006 registry pattern), then
	# the GameData mirror, then the spec default. Avoids hard node-path
	# tree walks from non-UI scripts.
	var tm: Node = SignalBus.time_manager
	if tm != null and "current_season" in tm:
		return String(tm.current_season)
	if "current_season" in GameData:
		return String(GameData.current_season)
	return "cool"