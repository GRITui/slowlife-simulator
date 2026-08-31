extends Node

# SignalBus — Central communication system (legacy path: src/scripts/signalbus.gd)
# Canonical implementation lives at res://scripts/autoload/SignalBus.gd
# This file mirrors it for backward-compat with existing scenes importing src/.

signal minute_ticked(day: int, hour: int, minute: int)
signal season_changed(new_season: String)
signal weather_changed(new_weather: String)
signal stamina_changed(current_stamina: float, max_stamina: float)
signal binthabat_offered(item_id: String, harmony_yield: int)
signal infrastructure_repaired(structure_id: String)
signal show_dialogue(speaker_name: String, text: String)

# Extended / legacy signals
signal energy_changed(new_energy: int)
signal village_harmony_changed(new_harmony: int)
signal village_goodwill_changed(new_goodwill: int)
signal crop_harvested(crop_id: int)
signal crop_growth_progress(crop_id: int, progress: int, max_stage: int)
signal day_night_cycle_changed(time_fraction: float)
signal ui_update_energy(energy: int)
signal ui_update_goodwill(goodwill: int)
signal ui_update_season(season: String)
signal ui_update_crop_progress(crop_id: int, progress: int)
signal buffalo_fed(buffalo_id: int)
signal temple_offering_made(offering_type: int)
signal festival_triggered(festival_name: String)
