extends SceneTree
# TASK-359 fishing gear gate — Rod (existing, unchanged) vs. Net (new
# alternative: 3-4 fish/cast, common/uncommon only, 8.0 stamina/cast).
#
# Code Quality Review note: the delegate's own first attempt at this
# file was a byte-identical copy of the unrelated
# tests/test_fishing_competition_scoring.gd (a Cline tool-formatting
# confusion, not a real test) -- deleted and rewritten from scratch here
# against the real shipped FishingSpot.gd/Player.gd/MarketManager.gd
# diff, which was itself reviewed and found correct.
#
# Follows the established _check(cond, label) convention (see
# tests/test_mining.gd for the stamina-gate assertion shape this test
# mirrors, and tests/test_fish_almanac.gd for the World.tscn/FishingSpot
# instancing shape).

const FISH_PATH: String = "res://data/fish/fish.json"

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  fishing-gear :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  fishing-gear :: %s" % label)

## item_id -> rarity, built from data/fish/fish.json's real roster so the
## rare/legendary-exclusion check (#2) verifies against real data, not a
## hardcoded guess.
func _build_rarity_map() -> Dictionary:
	var out: Dictionary = {}
	var f: FileAccess = FileAccess.open(FISH_PATH, FileAccess.READ)
	if f == null:
		return out
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	var roster: Array = []
	if parsed is Array:
		roster = parsed as Array
	elif parsed is Dictionary and (parsed as Dictionary).has("fish"):
		roster = (parsed as Dictionary)["fish"] as Array
	for species: Dictionary in roster:
		var rarity: String = String(species.get("rarity", "common"))
		var sizes: Dictionary = species.get("sizes", {}) as Dictionary
		for size_key in sizes.keys():
			var item_id: String = String((sizes[size_key] as Dictionary).get("item_id", ""))
			if item_id != "":
				out[item_id] = rarity
	return out

func _initialize() -> void:
	await _run_all()
	print("\n=== FISHING-GEAR TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("FISHING-GEAR GATE FAILED")
	quit(1 if _failed > 0 else 0)

func _run_all() -> void:
	var gd: Node = root.get_node_or_null("GameData")
	var sb: Node = root.get_node_or_null("SignalBus")
	_check(gd != null, "GameData autoload present")
	_check(sb != null, "SignalBus autoload present")
	if gd == null or sb == null:
		return

	var rarity_map: Dictionary = _build_rarity_map()
	_check(not rarity_map.is_empty(), "rarity map built from data/fish/fish.json")

	var world: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	var fishing: Node = world.get_node_or_null("FishingSpot")
	_check(fishing != null, "FishingSpot instanced from World")
	var player: Node = world.get_node_or_null("Player")
	_check(player != null, "Player instanced from World")
	if fishing == null or player == null:
		world.queue_free()
		return

	gd.inventory.clear()
	gd.fishing_skill = 4 # widen the eligible pool so casts reliably land regardless of season/skill gating
	gd.current_stamina = gd.max_stamina

	# --- A. Gear cycling ---
	gd.add_item("fishing_rod", 1)
	player.call("cycle_primed_gear")
	_check(String(player.get("_primed_gear_id")) == "fishing_rod",
		"cycle_primed_gear() is a no-op when only the rod is owned (stays 'fishing_rod')")

	gd.add_item("fishing_net", 1)
	player.call("cycle_primed_gear")
	var after_first_cycle: String = String(player.get("_primed_gear_id"))
	player.call("cycle_primed_gear")
	var after_second_cycle: String = String(player.get("_primed_gear_id"))
	_check(after_first_cycle != after_second_cycle,
		"cycle_primed_gear() toggles between rod and net when both are owned ('%s' -> '%s')" % [after_first_cycle, after_second_cycle])
	_check((after_first_cycle == "fishing_rod" or after_first_cycle == "fishing_net")
		and (after_second_cycle == "fishing_rod" or after_second_cycle == "fishing_net"),
		"cycle_primed_gear() only ever selects a real gear id")

	# --- B. Rod path is completely unchanged (0 stamina cost) ---
	player.set("_primed_gear_id", "fishing_rod")
	var rod_stamina_before: float = gd.current_stamina
	var rod_casts: int = 0
	for i in range(10):
		if fishing.call("cast_line"):
			rod_casts += 1
	_check(rod_casts >= 1, "at least one rod cast succeeded across 10 attempts")
	_check(is_equal_approx(gd.current_stamina, rod_stamina_before),
		"rod casts deduct 0 stamina (unchanged from before TASK-359, got %.1f -> %.1f)" % [rod_stamina_before, gd.current_stamina])

	# --- C. Net cast yields 3-4 fish, deducts exactly 8.0 stamina, never rare/legendary ---
	player.set("_primed_gear_id", "fishing_net")
	gd.current_stamina = gd.max_stamina
	var any_rare_or_legendary: bool = false
	var saw_3: bool = false
	var saw_4: bool = false
	var net_casts_done: int = 0
	for i in range(30):
		gd.current_stamina = gd.max_stamina # reset each cast so the count/stamina checks are independent
		gd.inventory.clear()
		gd.add_item("fishing_net", 1)
		var stamina_before: float = gd.current_stamina
		var ok: bool = fishing.call("cast_line")
		if not ok:
			continue
		net_casts_done += 1
		_check(is_equal_approx(gd.current_stamina, stamina_before - 8.0),
			"net cast deducts exactly 8.0 stamina (cast %d: %.1f -> %.1f)" % [i, stamina_before, gd.current_stamina])
		var caught_count: int = 0
		for item_id in gd.inventory.keys():
			if item_id == "fishing_net":
				continue
			caught_count += int(gd.inventory[item_id])
			var rarity: String = String(rarity_map.get(item_id, "common"))
			if rarity == "rare" or rarity == "legendary":
				any_rare_or_legendary = true
		if caught_count == 3:
			saw_3 = true
		elif caught_count == 4:
			saw_4 = true
		_check(caught_count == 3 or caught_count == 4,
			"net cast %d caught 3 or 4 fish (got %d)" % [i, caught_count])
	_check(net_casts_done >= 5, "at least 5 net casts succeeded across 30 attempts (got %d)" % net_casts_done)
	_check(saw_3 or saw_4, "at least one net cast landed a valid count")
	_check(not any_rare_or_legendary,
		"no net-caught fish across %d casts was rare or legendary" % net_casts_done)

	# --- D. Net soft-fails below 8.0 stamina: no item, no stamina change ---
	gd.inventory.clear()
	gd.add_item("fishing_net", 1)
	gd.current_stamina = 4.0
	var low_stamina_before: float = gd.current_stamina
	var net_fail: bool = fishing.call("cast_line")
	_check(net_fail == false, "net cast with insufficient stamina returns false (soft-fail)")
	_check(is_equal_approx(gd.current_stamina, low_stamina_before),
		"stamina unchanged on net soft-fail (%.1f)" % gd.current_stamina)
	_check(int(gd.inventory.get("fishing_net", 0)) == 1,
		"fishing_net itself is not consumed by a soft-failed cast")
	var only_net_owned: bool = true
	for item_id in gd.inventory.keys():
		if item_id != "fishing_net" and int(gd.inventory[item_id]) > 0:
			only_net_owned = false
	_check(only_net_owned, "no fish granted on a soft-failed net cast")

	# --- E. _primed_gear_id is session-only (not persisted) ---
	var sm_script: GDScript = load("res://scripts/persistence/SaveManager.gd")
	var sm: Node = sm_script.new()
	player.set("_primed_gear_id", "fishing_net")
	var saved: bool = sm.save_game()
	_check(saved, "SaveManager.save_game() succeeds with a non-default primed gear")
	var f: FileAccess = FileAccess.open("user://savegame.json", FileAccess.READ)
	var raw: String = f.get_as_text() if f else ""
	_check(not raw.contains("_primed_gear_id") and not raw.contains("primed_gear"),
		"saved JSON does not contain the primed gear at all (session-only, matches _primed_seed_id precedent)")
	sm.queue_free()

	# --- F. fishing_net is a real, purchasable market item ---
	var mm_script: GDScript = load("res://scripts/market/MarketManager.gd")
	var found_net_offer: bool = false
	var net_price: int = -1
	for season in mm_script.BUY_OFFERS.keys():
		for offer: Dictionary in (mm_script.BUY_OFFERS[season] as Array):
			if String(offer.get("item", "")) == "fishing_net":
				found_net_offer = true
				net_price = int(offer.get("price", -1))
	_check(found_net_offer, "fishing_net is a real MarketManager.BUY_OFFERS entry")
	_check(net_price > 0, "fishing_net has a positive price (got %d)" % net_price)

	world.queue_free()
	gd.inventory.clear()
	gd.fishing_skill = 1
