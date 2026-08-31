extends Node
# AudioManager — TASK-021 ambient audio, SignalBus hooks, no heavy assets
var bus_volumes: Dictionary = {"Master": 0.0, "Music": 0.0, "SFX": 0.0}
func play_music(id: String) -> void:
  if id.is_empty(): return
  # no-op if asset missing, headless-safe
  pass
func play_sfx(id: String) -> void:
  if id.is_empty(): return
  pass
func set_volume(bus: String, db: float) -> void:
  bus_volumes[bus] = db
