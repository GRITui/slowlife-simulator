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