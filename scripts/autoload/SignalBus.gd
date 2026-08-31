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
signal barter_completed(have_id: String, want_id: String)

# Reference registry (ENGINE-006) — set once by the owning system on _ready(),
# read directly instead of hard node paths / scene-tree walks. Not a signal
# because a fire-once "ready" signal races with the reader's own _ready()
# order; a plain field survives late readers.
var grid_manager: Node = null
var time_manager: Node = null

# --- Extended signals (backward-compat with existing codebase) ---
signal energy_changed(new_energy: int)
signal village_harmony_changed(new_harmony: int)
signal village_goodwill_changed(new_goodwill: int)
signal crop_harvested(crop_id: int)
signal crop_growth_progress(crop_id: int, progress: int, max_stage: int)
# TASK-034: reintroduced WITH a live consumer (DayNightTintDriver grade
# shader). TASK-033's removal note applies only while no listener exists.
signal day_night_cycle_changed(time_fraction: float)
signal festival_triggered(festival_name: String)

# TASK-027 accessibility — emitted by Settings UI, consumed by HUD + SaveManager.
signal settings_changed(font_scale: float, high_contrast: bool)
# TASK-042: emitted whenever SceneTree.paused flips (pause menu / resume).
signal game_paused_changed(paused: bool)
