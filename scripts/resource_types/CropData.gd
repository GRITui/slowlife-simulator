extends Resource
class_name CropData

# CropData — Data-driven Thai crop definition (SCAMPER Substitute)
# Used by GridManager for Hybrid A/B (20x16 flat + 3x3 maze islet).

@export var id: String = "jasmine_rice"
@export var display_name: String = "Jasmine Rice" # ข้าวหอมมะลิ
@export var description: String = "Staple Isan crop. Monsoon bonus, Hot wilt if unwatered."
@export var icon: Texture2D
@export var stage_textures: Array[Texture2D] = [] # expect 4: rice_paddy_stage1..4

## Growth: minutes per stage (game minutes from TimeManager minute_ticked)
@export var growth_minutes_per_stage: Array[int] = [120, 180, 240, 0] # S4 harvest-ready dwell
@export var total_stages: int = 4

## Seasonal tuning
@export var season_yield_multiplier: Dictionary = {"hot": 0.8, "monsoon": 1.4, "cool": 1.0}
@export var season_growth_speed: Dictionary = {"hot": 0.85, "monsoon": 1.25, "cool": 1.0}
@export var allowed_seasons: Array[String] = ["hot", "monsoon", "cool"]
@export var requires_water: bool = true

## Economy / village loop
@export var yield_item_id: String = "rice_grain"
@export var yield_amount: int = 3
@export var harmony_value: int = 2
@export var stamina_cost_plant: float = 5.0
@export var stamina_cost_harvest: float = 3.0
@export var seed_item_id: String = "seed_rice"
@export var regrow_after_harvest: bool = false
@export var required_infrastructure: String = "" # e.g. "sluice_gate" for pandan

func get_growth_minutes(stage: int, season: String) -> int:
	if stage < 0 or stage >= growth_minutes_per_stage.size():
		return 0
	var base: int = growth_minutes_per_stage[stage]
	var speed: float = season_growth_speed.get(season, 1.0)
	if speed <= 0:
		return base
	return int(float(base) / speed)

func get_yield(season: String, weather: String) -> int:
	var m: float = season_yield_multiplier.get(season, 1.0)
	if weather == "rain" and season == "monsoon":
		m *= 1.1
	var y: int = int(round(float(yield_amount) * m))
	return max(1, y)

func is_plantable_in(season: String) -> bool:
	return season in allowed_seasons

func _to_string() -> String:
	return "<CropData %s stages=%d>" % [id, total_stages]
