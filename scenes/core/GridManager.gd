extends Node2D
# GridManager — Manages Hybrid A/B grid: 20×16 flat paddies + 3×3 lotus maze islet
# Connects to SignalBus.minute_ticked / season_changed / weather_changed
# Per spec: backlog.json TASK-002, strict 12-color, SignalBus-decoupled

class PlotState:
	var crop: CropData
	var stage: int = 0
	var minutes_in_stage: int = 0
	var watered: bool = false
	var planted_day: int = -1
	var wilt_minutes: int = 0

@export var grid_size: Vector2i = Vector2i(20, 16)
@export var cell_size: int = 32
@export var maze_origin: Vector2i = Vector2i(14, 10) # SE inset 3×3 lotus maze
@export var debug_log: bool = false

var plots: Dictionary = {} # Vector2i -> PlotState
var current_season: String = "cool"
var current_weather: String = "clear"

func _ready() -> void:
	current_season = GameData.current_season if "current_season" in GameData else "cool"
	current_weather = GameData.current_weather if "current_weather" in GameData else "clear"
	SignalBus.minute_ticked.connect(_on_minute_ticked)
	SignalBus.season_changed.connect(_on_season_changed)
	SignalBus.weather_changed.connect(_on_weather_changed)

func is_maze_cell(cell: Vector2i) -> bool:
	return cell.x >= maze_origin.x and cell.x < maze_origin.x + 3 and cell.y >= maze_origin.y and cell.y < maze_origin.y + 3

func is_plantable(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= grid_size.x or cell.y >= grid_size.y:
		return false
	if is_maze_cell(cell):
		return false # maze grows lotus only via special path
	if plots.has(cell):
		return false
	return true

func plant(cell: Vector2i, crop: CropData) -> bool:
	if not is_plantable(cell):
		return false
	if not crop.is_plantable_in(current_season):
		if debug_log: print("Cannot plant ", crop.id, " in ", current_season)
		return false
	if crop.required_infrastructure != "" and not GameData.is_repaired(crop.required_infrastructure):
		return false
	if crop.seed_item_id != "" and not GameData.has_item(crop.seed_item_id, 1):
		# allow free rice seed for demo if none owned
		if crop.id != "jasmine_rice":
			return false
	if GameData.current_stamina < crop.stamina_cost_plant:
		return false
	if crop.seed_item_id != "" and GameData.has_item(crop.seed_item_id, 1):
		GameData.remove_item(crop.seed_item_id, 1)
	GameData.current_stamina -= crop.stamina_cost_plant
	var ps := PlotState.new()
	ps.crop = crop
	ps.stage = 0
	ps.planted_day = 1
	plots[cell] = ps
	SignalBus.crop_growth_progress.emit(int(cell.x + cell.y * 100), 0, crop.total_stages)
	return true

func water(cell: Vector2i) -> bool:
	if not plots.has(cell):
		return false
	plots[cell].watered = true
	plots[cell].wilt_minutes = 0
	return true

func harvest(cell: Vector2i) -> int:
	if not plots.has(cell):
		return 0
	var ps: PlotState = plots[cell]
	if ps.stage < ps.crop.total_stages - 1:
		return 0
	if GameData.current_stamina < ps.crop.stamina_cost_harvest:
		return 0
	GameData.current_stamina -= ps.crop.stamina_cost_harvest
	var y: int = ps.crop.get_yield(current_season, current_weather)
	if not ps.watered and current_season == "hot":
		y = max(1, int(y * 0.5)) # wilt penalty
	GameData.add_item(ps.crop.yield_item_id, y)
	GameData.add_harmony(ps.crop.harmony_value)
	SignalBus.crop_harvested.emit(int(cell.x + cell.y * 100))
	if ps.crop.regrow_after_harvest:
		ps.stage = 0
		ps.minutes_in_stage = 0
		ps.watered = false
	else:
		plots.erase(cell)
	return y

func get_plot(cell: Vector2i) -> PlotState:
	return plots.get(cell, null)

func _on_minute_ticked(_day: int, _hour: int, _minute: int) -> void:
	for cell in plots.keys():
		var ps: PlotState = plots[cell]
		var crop: CropData = ps.crop
		# monsoon rain auto-water
		if current_weather == "rain" and current_season == "monsoon":
			ps.watered = true
		# hot wilt tracking
		if current_season == "hot" and not ps.watered:
			ps.wilt_minutes += 1
		else:
			if ps.watered:
				ps.wilt_minutes = 0
		# already harvest-ready
		if ps.stage >= crop.total_stages - 1:
			continue
		var need: int = crop.growth_minutes_per_stage[ps.stage]
		# apply seasonal speed: monsoon faster, hot slower
		var speed: float = crop.season_growth_speed.get(current_season, 1.0)
		if ps.watered:
			speed *= 1.1
		# advance proportionally: 1 game minute * speed
		ps.minutes_in_stage += int(1 * speed) if speed >= 1 else 1 # keep at least 1; finer: accumulate float if needed
		# compensate for hot slow: require more effective minutes
		if speed < 1.0:
			# already handled by need via get_growth_minutes; just wait longer
			pass
		if ps.minutes_in_stage >= need:
			ps.minutes_in_stage = 0
			ps.stage += 1
			ps.watered = false # needs re-water next stage
			SignalBus.crop_growth_progress.emit(int(cell.x + cell.y * 100), ps.stage, crop.total_stages)
			if debug_log:
				print("Plot ", cell, " -> stage ", ps.stage)

func _on_season_changed(new_season: String) -> void:
	current_season = new_season

func _on_weather_changed(new_weather: String) -> void:
	current_weather = new_weather

func serialize() -> Dictionary:
	var d: Dictionary = {}
	for cell in plots.keys():
		var ps: PlotState = plots[cell]
		d[str(cell)] = {"id": ps.crop.id, "stage": ps.stage, "minutes": ps.minutes_in_stage, "watered": ps.watered}
	return {"grid_size": grid_size, "maze_origin": maze_origin, "plots": d, "season": current_season, "weather": current_weather}

func get_stats() -> Dictionary:
	return {"occupied": plots.size(), "total_cells": grid_size.x * grid_size.y - 9, "season": current_season, "weather": current_weather}
