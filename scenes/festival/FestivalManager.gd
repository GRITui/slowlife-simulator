extends Node
# FestivalManager — TASK-022 Loy Krathong, cozy no-fail, SignalBus
@export var festival_day: int = 7
var _triggered_seasons: Dictionary = {}
func try_trigger_festival(day: int, season: String) -> bool:
  if season != "cool": return false
  if day != festival_day: return false
  var key: String = "%d-%s" % [day, season]
  if _triggered_seasons.has(key): return false
  _triggered_seasons[key] = true
  SignalBus.festival_triggered.emit("loy_krathong") if SignalBus.has_signal("festival_triggered") else SignalBus.show_dialogue.emit("System", "Loy Krathong tonight — pond glows")
  SignalBus.show_dialogue.emit("Elder", "Krathongs drift on the lotus pond tonight.")
  return true
func craft_krathong() -> bool:
  if not GameData.has_item("lotus_root", 1): return false
  if not GameData.remove_item("lotus_root", 1): return false
  GameData.add_item("krathong", 1)
  SignalBus.show_dialogue.emit("System", "Crafted a krathong (lotus).")
  return true
func release_krathong() -> void:
  if not GameData.has_item("krathong", 1):
    SignalBus.show_dialogue.emit("System", "Need a krathong to release.")
    return
  GameData.remove_item("krathong", 1)
  GameData.add_harmony(5)
  SignalBus.show_dialogue.emit("System", "Krathong released — harmony +5, merit drifts.")
