extends Node2D
## FishingSpot — TASK-050 (PO_INBOX r5 #5/#6). Interact adjacent to a water
## tile while holding a fishing rod: rolls a catch from data/fish/fish.json
## (20 Thai freshwater species x 3 sizes), gated by season + fishing skill.
## Zero-combat catch-and-relax: no fail states, soft "nothing biting" only.
##
## Phase 3 audit (2026-09-02): this spot is instanced dynamically via
## World.gd's _ensure_fishing_spot() (script.new(), no .tscn), which never
## added an InteractArea child — @onready $InteractArea was always null,
## so _player_in_range never became true and cast_line() could only ever
## be triggered by direct method calls (as every existing test does), never
## by a real player pressing interact. Fixed the same way MiningSpot.gd
## (TASK-321) fixed the identical latent bug: build a real Area2D +
## CollisionShape2D programmatically in _ready().
##
## TASK-359: added a second gear path — "fishing_net" — as an alternative
## to the rod. Net casts roll 3-4 common/uncommon fish per cast (no rare
## or legendary access while active) and deduct 8.0 stamina per cast
## (matches MiningSpot.gd's dig_cost_stamina: float = 8.0 exactly). The
## active gear is read from Player._primed_gear_id (session-only, set by
## the new "cycle_fishing_gear" InputMap action on Player.gd). Rod path
## behavior is UNCHANGED for every existing call site / test.

const FISH_PATH: String = "res://data/fish/fish.json"
const _WATER := ["canal", "water_lotuspond", "deep_pond"]

## TASK-359: net stamina cost per cast. Identical value to
## MiningSpot.gd's dig_cost_stamina: float = 8.0 — same order of
## interaction (one stamina-deducted action per interact), same cost.
const NET_STAMINA_COST: float = 8.0
## TASK-359: inclusive [min, max] fish per net cast.
const NET_CATCH_MIN: int = 3
const NET_CATCH_MAX: int = 4

@export var spot_name: String = "Fishing Spot"
## Proximity radius (matches SluiceGate/CarpenterUpgrade/MiningSpot InteractArea).
@export var interact_radius: float = 56.0
var fishing_rolls: int = 0 ## lifetime catches, +1 skill per 5 rolls (cap 4)

var _player_in_range: bool = false
var _roster: Array = []
var _area: Area2D = null

func _ready() -> void:
	add_to_group("fishing_spot")
	_build_interact_area()
	_load_roster()

func _build_interact_area() -> void:
	_area = Area2D.new()
	_area.name = "InteractArea"
	_area.collision_layer = 0
	_area.collision_mask = 1 # player layer
	_area.monitorable = true
	_area.monitoring = true
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = interact_radius
	var collider: CollisionShape2D = CollisionShape2D.new()
	collider.shape = shape
	collider.debug_color = Color(0.2, 0.7, 0.5, 0.32)
	_area.add_child(collider)
	add_child(_area)
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)

func _load_roster() -> void:
	var f: FileAccess = FileAccess.open(FISH_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Array:
		_roster = parsed as Array
	elif parsed is Dictionary and (parsed as Dictionary).has("fish"):
		_roster = (parsed as Dictionary)["fish"] as Array

func _skill() -> int:
	return clampi(int(GameData.fishing_skill), 1, 4)

func _current_season() -> String:
	var tm: Node = SignalBus.time_manager
	if tm != null and "current_season" in tm:
		return String(tm.current_season)
	return String(GameData.current_season)

## Eligible species: season matches + skill requirement met.
func eligible_fish() -> Array:
	var season: String = _current_season()
	var out: Array = []
	for f: Dictionary in _roster:
		var seasons: Array = f.get("seasons", []) as Array
		if not seasons.has(season):
			continue
		if int(f.get("skill_required", 1)) > _skill():
			continue
		out.append(f)
	return out

## TASK-359: net's eligible pool — same season + skill filtering as
## eligible_fish() above, but additionally restricts to common/uncommon
## rarities. Reuses the same per-species Dictionary shape so the existing
## rarity-weighted pick loop in _roll_catch() works unmodified (just with
## a smaller, lower-rarity pool).
func _eligible_fish_for_net() -> Array:
	var season: String = _current_season()
	var out: Array = []
	for f: Dictionary in _roster:
		var seasons: Array = f.get("seasons", []) as Array
		if not seasons.has(season):
			continue
		if int(f.get("skill_required", 1)) > _skill():
			continue
		# Net path excludes rare + legendary — see task spec: "common/uncommon
		# only — reuse the existing rarity-weighting logic among just those
		# two tiers." 4.0 / 2.5 weights come from _roll_catch() unchanged.
		var rarity: String = String(f.get("rarity", "common"))
		if rarity == "rare" or rarity == "legendary":
			continue
		out.append(f)
	return out

func _water_adjacent() -> bool:
	# TASK-352: prefer the SignalBus.world_render registry slot so this
	# works identically in the outdoor World scene AND in any future
	# interior (FarmHouse etc.) without depending on a hardcoded child
	# node path.
	var wr: Node = SignalBus.world_render
	if wr == null or not wr.has_method("ground_at"):
		return false
	var origin := Vector2i(int(global_position.x / 48.0), int(global_position.y / 48.0))
	for offset: Vector2i in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
		if String(wr.ground_at(origin + offset)) in _WATER:
			return true
	return false

## Roll size weighted by rarity: common favors small, rare favors big.
## TASK-359: accepts an optional pool override so the net path can pass
## its own restricted common/uncommon pool through the same weighted
## pick loop. Default (no arg) keeps the existing rod-path call sites
## fully backward-compatible.
func _roll_catch(pool_override: Array = []) -> Dictionary:
	var pool: Array = pool_override if not pool_override.is_empty() else eligible_fish()
	if pool.is_empty():
		return {}
	var total: float = 0.0
	var weights: Array = []
	for f: Dictionary in pool:
		var w: float = 4.0
		match String(f.get("rarity", "common")):
			"uncommon": w = 2.5
			"rare": w = 1.2
			"legendary": w = 0.4
		weights.append(w)
		total += w
	var roll: float = randf() * total
	var picked: Dictionary = pool[0]
	for i: int in pool.size():
		roll -= weights[i]
		if roll <= 0.0:
			picked = pool[i]
			break
	# Size roll skews by rarity (rare -> bigger expected size).
	# TASK-281 skill-4 payoff: master anglers get big-fish bias + silver tip.
	var big_bias: float = 0.15
	if _skill() >= 4:
		big_bias = 0.55
	elif String(picked.get("rarity", "common")) in ["rare", "legendary"]:
		big_bias = 0.4
	var size_roll: float = randf()
	var size: String = "small"
	if size_roll > 1.0 - big_bias:
		size = "big"
	elif size_roll > 0.55:
		size = "mid"
	var sizes: Dictionary = picked.get("sizes", {}) as Dictionary
	return {"species": picked, "size": size, "item": String(sizes.get(size, {}).get("item_id", "")),
		"harmony": int(sizes.get(size, {}).get("harmony_value", 1))}

func cast_line() -> bool:
	if not _water_adjacent():
		SignalBus.show_dialogue.emit(spot_name, "Stand closer to the water.")
		return false
	# TASK-359: read the active gear from Player._primed_gear_id (session-
	# only var set by Player.cycle_primed_gear() via the new
	# "cycle_fishing_gear" InputMap action). Default "fishing_rod" is
	# preserved for any player that doesn't own the gear-cycle path
	# (e.g. legacy test setups that never instantiated Player).
	var active_gear: String = _get_active_gear_id()
	if active_gear == "fishing_net":
		# Net requires its own owned check — even if the cycle landed on
		# net, the player may have dropped/sold it before casting. Mirrors
		# the rod gate below for symmetry.
		if not GameData.has_item("fishing_net", 1):
			SignalBus.show_dialogue.emit(spot_name, "A fishing net would help. The market boats carry them.")
			return false
		return _cast_net()
	# Rod path — unchanged from TASK-050 / TASK-281 / TASK-321 / TASK-331 /
	# TASK-358. The rod gate is the canonical "you need a fishing rod"
	# soft-fail every existing call site relies on.
	if not GameData.has_item("fishing_rod", 1):
		SignalBus.show_dialogue.emit(spot_name, "A fishing rod would help. The market boats carry them.")
		return false
	var catch_data: Dictionary = _roll_catch()
	if catch_data.is_empty():
		SignalBus.show_dialogue.emit(spot_name, "Nothing biting this season yet.")
		return false
	var item: String = String(catch_data["item"])
	if item.is_empty():
		return false
	GameData.add_item(item, 1)
	GameData.add_harmony(int(catch_data["harmony"]))
	# TASK-281: skill-4 mastery tip — silver for every catch.
	if _skill() >= 4:
		GameData.add_silver(5)
	fishing_rolls += 1
	# Skill growth: 1 level per 5 rolls, capped at 4 (top tier).
	var level: int = clampi(1 + fishing_rolls / 5, 1, 4)
	if level > _skill():
		GameData.fishing_skill = level
		SignalBus.show_dialogue.emit(spot_name, "Fishing skill up! Now level %d." % level)
		# TASK-331 master_angler milestone — first time fishing_skill hits cap.
		if level >= 4 and GameData.earn_milestone("master_angler"):
			SignalBus.show_dialogue.emit("System", "Milestone: Master Angler! (+10 harmony)")
	var species: Dictionary = catch_data["species"] as Dictionary
	var size: Dictionary = (species.get("sizes", {}) as Dictionary).get(catch_data["size"], {}) as Dictionary
	SignalBus.craft_completed.emit(item, 1) # reuse item-gained signal (no new orphan)
	SignalBus.show_dialogue.emit(spot_name, "Caught a %s %s! (+%d harmony)" % [
		String(catch_data["size"]), String(species.get("display_name", "fish")), int(size.get("harmony_value", 1))])
	# TASK-358 fish almanac — first time this exact (species, size) pair is
	# caught, fire one extra "first catch" dialogue and grant the +5 bonus.
	# record_catch() is idempotent on its own (mirrors earn_milestone's
	# shape), so a repeat of the same pair never re-grants or re-speaks.
	var species_id: String = String(species.get("id", ""))
	if species_id != "" and GameData.record_catch(species_id, String(catch_data["size"])):
		SignalBus.show_dialogue.emit("System",
			"Fish Almanac: first catch of a %s %s! (+5 harmony)" % [
				String(catch_data["size"]), String(species.get("display_name", "fish"))])
	# TASK-331 storm_catch milestone — monsoon + rain + catch in one cast.
	if String(GameData.current_season) == "monsoon" and String(GameData.current_weather) == "rain":
		if GameData.earn_milestone("storm_catch"):
			SignalBus.show_dialogue.emit("System", "Milestone: Storm Catch! (+10 harmony)")
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		cast_line()
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = false

## TASK-359: net cast path. Soft-fails (dialogue + return false, no item,
## no stamina change) on insufficient stamina — mirrors MiningSpot.gd's
## dig() stamina gate exactly. On success: deducts NET_STAMINA_COST, rolls
## NET_CATCH_MIN..NET_CATCH_MAX fish each independently from the common/
## uncommon-only pool, grants items + almanac first-catches + harmony +
## (skill-4) silver + skill growth (one tick per cast, same as rod).
func _cast_net() -> bool:
	# Stamina gate first, mirroring MiningSpot.gd's dig() shape: soft-fail
	# with dialogue, NO partial catch, NO stamina change. Matches the
	# task spec's "soft-fails exactly like MiningSpot.gd's stamina gate."
	if GameData.current_stamina < NET_STAMINA_COST:
		SignalBus.show_dialogue.emit(spot_name, "Too tired to cast a net. Rest a moment.")
		return false
	var pool: Array = _eligible_fish_for_net()
	if pool.is_empty():
		SignalBus.show_dialogue.emit(spot_name, "Nothing biting this season yet.")
		return false
	# Roll how many fish this cast lands, in the inclusive range.
	var count: int = randi_range(NET_CATCH_MIN, NET_CATCH_MAX)
	# Deduct stamina BEFORE the per-fish rolls so a partial-batch code
	# path (none exists today, but future-proofing) can never accidentally
	# grant items without the cost.
	GameData.current_stamina -= NET_STAMINA_COST
	var caught_items: Array = []
	var caught_species: Array = []
	for i: int in count:
		var catch_data: Dictionary = _roll_catch(pool)
		if catch_data.is_empty():
			continue
		var item: String = String(catch_data.get("item", ""))
		if item.is_empty():
			continue
		GameData.add_item(item, 1)
		caught_items.append(item)
		var species: Dictionary = catch_data.get("species", {}) as Dictionary
		var species_id: String = String(species.get("id", ""))
		var size_key: String = String(catch_data.get("size", "small"))
		var harmony: int = int(catch_data.get("harmony", 1))
		GameData.add_harmony(harmony)
		# TASK-358 fish almanac — same idempotent first-catch bonus per
		# (species, size) pair as the rod path. Net rolls can land the
		# same pair multiple times in one cast; the bonus still fires
		# only on the first occurrence (record_catch is idempotent).
		if species_id != "" and GameData.record_catch(species_id, size_key):
			SignalBus.show_dialogue.emit("System",
				"Fish Almanac: first catch of a %s %s! (+5 harmony)" % [
					size_key, String(species.get("display_name", "fish"))])
		# Track a sample species_id for the dialogue line below.
		if not caught_species.has(species_id) and species_id != "":
			caught_species.append(species_id)
		# TASK-281 skill-4 mastery tip — silver tip applies per-fish
		# (the rod path grants once-per-cast; the net catches multiple
		# fish so per-fish is the analogous "you got something nice"
		# payoff). Matches the spec's "same order of interaction"
		# framing for the rod path while preserving the magnitude
		# of the tip.
		if _skill() >= 4:
			GameData.add_silver(5)
	# Skill growth + milestones track per-cast (not per-fish) for both
	# rod and net — one fishing_rolls++ per cast keeps the existing
	# "5 rolls per skill level" cadence intact. Otherwise a net user
	# would max fishing_skill ~5x faster and break the existing curve.
	fishing_rolls += 1
	var level: int = clampi(1 + fishing_rolls / 5, 1, 4)
	if level > _skill():
		GameData.fishing_skill = level
		SignalBus.show_dialogue.emit(spot_name, "Fishing skill up! Now level %d." % level)
		if level >= 4 and GameData.earn_milestone("master_angler"):
			SignalBus.show_dialogue.emit("System", "Milestone: Master Angler! (+10 harmony)")
	# One combined dialogue line for the whole cast — keeps the HUD
	# from getting spammed when a net catches 4 fish at once.
	# storm_catch milestone fires once per cast on monsoon+rain, same
	# as the rod path (a single cast is the unit of "interaction,"
	# even if the catch volume is larger).
	if String(GameData.current_season) == "monsoon" and String(GameData.current_weather) == "rain":
		if GameData.earn_milestone("storm_catch"):
			SignalBus.show_dialogue.emit("System", "Milestone: Storm Catch! (+10 harmony)")
	if not caught_items.is_empty():
		SignalBus.craft_completed.emit(String(caught_items[0]), caught_items.size()) # reuse item-gained signal (no new orphan)
		var species_text: String = ", ".join(caught_species) if not caught_species.is_empty() else "various"
		SignalBus.show_dialogue.emit(spot_name,
			"Net swept in %d fish (%s)." % [
				caught_items.size(),
				species_text])
		return true
	# Pool was non-empty but every roll came back with empty item (shouldn't
	# happen with current data — sizes always define item_id — but keep a
	# deterministic soft-fail path for future roster changes).
	SignalBus.show_dialogue.emit(spot_name, "Nothing biting this season yet.")
	return false

## TASK-359: resolve the player's currently-primed gear id. Defaults to
## "fishing_rod" when no Player is in the tree (e.g. legacy tests that
## instantiate FishingSpot without a World scene), matching Player.gd's
## own default. Uses the same get_nodes_in_group("player") pattern as
## HUD.gd reads _primed_seed_id — see scenes/ui/HUD.gd:_update_seed_label.
func _get_active_gear_id() -> String:
	if not is_inside_tree():
		return "fishing_rod"
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return "fishing_rod"
	return String((players[0] as Node).get("_primed_gear_id"))
