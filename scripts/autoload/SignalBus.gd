extends Node

# SignalBus — Decoupled event bus for slowlife-simulator
# Autoload singleton. All UI, time, and game state communication flows here.
# Spec: res://scripts/autoload/SignalBus.gd

signal minute_ticked(day: int, hour: int, minute: int)
signal season_changed(new_season: String)
signal weather_changed(new_weather: String)
signal stamina_changed(current_stamina: float, max_stamina: float)
signal binthabat_offered(item_id: String, harmony_yield: int)
signal infrastructure_repaired(structure_id: String)
signal show_dialogue(speaker_name: String, text: String)
signal inventory_changed(inventory: Dictionary)
signal pause_toggled(is_paused: bool)
signal action_prompt_changed(text: String, visible: bool)

# --- Extended signals (backward-compat with existing codebase) ---
signal energy_changed(new_energy: int)
signal village_harmony_changed(new_harmony: int)
signal village_goodwill_changed(new_goodwill: int)
signal crop_harvested(crop_id: int)
signal crop_growth_progress(crop_id: int, progress: int, max_stage: int)
signal day_night_cycle_changed(time_fraction: float)
