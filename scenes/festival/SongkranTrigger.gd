extends Node
## SongkranTrigger — TASK-046 Thai New Year water festival (hot season, day 3).
## FestivalManager pattern (TASK-040): subscribes to minute_ticked via the
## time_manager registry, fires once per hot-season festival day, spawns the
## authored splash particle burst at the lotus pond, dialogue via DialogueDB.
## Zero-combat, pure celebration.

@export var festival_day: int = 3
var _triggered_keys: Dictionary = {}
var _splash: GPUParticles2D = null

func _ready() -> void:
	add_to_group("festival_manager")
	SignalBus.minute_ticked.connect(_on_minute_ticked)

func _exit_tree() -> void:
	if SignalBus.minute_ticked.is_connected(_on_minute_ticked):
		SignalBus.minute_ticked.disconnect(_on_minute_ticked)

func _on_minute_ticked(day: int, hour: int, _minute: int) -> void:
	var season: String = "hot"
	var tm: Node = SignalBus.time_manager
	var dos: int = festival_day
	if tm != null and "current_season" in tm:
		season = String(tm.current_season)
		if tm.has_method("day_of_season"):
			dos = int(tm.day_of_season())
	elif "current_season" in GameData:
		season = String(GameData.current_season)
	if season != "hot" or dos != festival_day:
		return
	# Songkran water play peaks midday — gate on 12:00-18:00 window.
	if hour < 12 or hour >= 18:
		return
	var tm_local: Node = SignalBus.time_manager
	var year: int = tm_local.year() if tm_local != null and tm_local.has_method("year") else 1
	var key: String = "%d-%s" % [year, season]
	if _triggered_keys.has(key):
		return
	_triggered_keys[key] = true
	_spawn_splash()
	SignalBus.festival_triggered.emit("songkran")
	SignalBus.show_dialogue.emit("Child", "Songkran! Happy New Year — you're soaked!")

func _spawn_splash() -> void:
	if _splash != null:
		return
	var mat: Material = load("res://assets/particles/songkran_splash.tres")
	if mat == null:
		return
	var main: Node = get_parent()
	if main == null or not (main is Node2D):
		return
	_splash = GPUParticles2D.new()
	_splash.name = "SongkranSplash"
	_splash.position = Vector2(2 * 48 + 24, 2 * 48) # lotus pond
	_splash.amount = 64
	_splash.lifetime = 1.6
	_splash.one_shot = true
	_splash.explosiveness = 0.9
	_splash.emitting = true
	(_splash as GPUParticles2D).process_material = mat
	main.add_child(_splash)
