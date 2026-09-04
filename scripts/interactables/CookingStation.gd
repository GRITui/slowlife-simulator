extends StaticBody2D
## CookingStation — TASK-029 crafting wiring: clay stove consumes
## data/recipes/recipes.json via RecipeData. Mirror of the SluiceGate
## interaction contract (Area2D proximity + `interact`). Zero combat, soft
## failures only. Emits SignalBus.craft_completed; no direct UI coupling.

const RECIPES_PATH: String = "res://data/recipes/recipes.json"

@export var station_name: String = "Clay Stove"
@export var stamina_cost_mult: float = 1.0

var _player_in_range: bool = false
var _recipes: Array = []

@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null

func _ready() -> void:
	add_to_group("cooking_station")
	if _area != null:
		_area.body_entered.connect(_on_body_entered)
		_area.body_exited.connect(_on_body_exited)
	_load_recipes()

func _load_recipes() -> void:
	var f: FileAccess = FileAccess.open(RECIPES_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary and (parsed as Dictionary).has("recipes"):
		_recipes = (parsed as Dictionary)["recipes"] as Array

## TASK-055: every recipe craftable right now (first-match callers use
## get_craftable; ordering follows recipes.json content curation).
## TASK-363: one extra filter — if a recipe is listed in any NPC's
## RECIPE_UNLOCKS_BY_NPC entry (a "gated" recipe) but isn't yet in
## GameData.recipe_unlocks, skip it. Recipes that don't appear in
## RECIPE_UNLOCKS_BY_NPC at all are completely unaffected.
func get_all_craftable() -> Array:
	var out: Array = []
	var season: String = String(GameData.current_season)
	for r: Dictionary in _recipes:
		if String(r.get("season", "")) != "" and String(r.get("season")) != season:
			continue
		if String(r.get("requires_infrastructure", "")) != "" and not GameData.is_repaired(String(r["requires_infrastructure"])):
			continue
		# TASK-363: gate by villager-friendship unlock. Gated recipes
		# are listed in GameData.RECIPE_UNLOCKS_BY_NPC under some
		# npc_id; non-gated recipes (e.g. rice_flour, khai_jiao,
		# khao_soi, etc.) are always-craftable regardless of
		# relationship, matching the spec's "early cooking isn't
		# gated behind relationships" requirement.
		var rid: String = String(r.get("id", ""))
		if rid != "" and GameData.is_recipe_gated(rid) and not GameData.recipe_unlocks.get(rid, false):
			continue
		var ok: bool = true
		var inputs: Dictionary = r.get("inputs", {}) as Dictionary
		for item_id: String in inputs.keys():
			if not GameData.has_item(item_id, int(inputs[item_id])):
				ok = false
				break
		if ok:
			out.append(r)
	return out

## First recipe craftable right now (season + infrastructure + inventory).
## TASK-363: same gating filter as get_all_craftable() — see above.
func get_craftable() -> Dictionary:
	var season: String = String(GameData.current_season)
	for r: Dictionary in _recipes:
		if String(r.get("season", "")) != "" and String(r.get("season")) != season:
			continue
		if String(r.get("requires_infrastructure", "")) != "" and not GameData.is_repaired(String(r["requires_infrastructure"])):
			continue
		var rid: String = String(r.get("id", ""))
		if rid != "" and GameData.is_recipe_gated(rid) and not GameData.recipe_unlocks.get(rid, false):
			continue
		var ok: bool = true
		var inputs: Dictionary = r.get("inputs", {}) as Dictionary
		for item_id: String in inputs.keys():
			if not GameData.has_item(item_id, int(inputs[item_id])):
				ok = false
				break
		if ok:
			return r
	return {}

func try_craft() -> bool:
	var r: Dictionary = get_craftable()
	if r.is_empty():
		SignalBus.show_dialogue.emit(station_name, "Nothing to cook with today's harvest.")
		return false
	var recipe: RecipeData = RecipeData.new()
	recipe.id = String(r.get("id", ""))
	recipe.inputs = r.get("inputs", {}) as Dictionary
	recipe.stamina_cost = float(r.get("stamina_cost", 5.0))
	recipe.harmony_reward = int(r.get("harmony_reward", 5))
	# Consume inputs via RecipeData.craft against GameData.inventory directly,
	# then route outputs through GameData so signals/limits stay centralized.
	if not recipe.craft(GameData.inventory):
		SignalBus.show_dialogue.emit(station_name, "Not enough to cook that.")
		return false
	var cost: float = recipe.stamina_cost * stamina_cost_mult
	GameData.current_stamina = maxf(0.0, GameData.current_stamina - cost)
	GameData.add_item(recipe.id, 1)
	GameData.add_harmony(recipe.harmony_reward)
	SignalBus.craft_completed.emit(recipe.id, 1)
	SignalBus.show_dialogue.emit(station_name, "%s ready — the kitchen smells like home." % String(r.get("display_name", recipe.id)))
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		try_craft()
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = false
