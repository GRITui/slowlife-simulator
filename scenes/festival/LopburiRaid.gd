extends Node
## LopburiRaid — ISSUE-134. Monkey pest event during the Lopburi banquet
## window (hot season day 9, midday): monkeys raid up to 2 planted plots
## (clearing them) UNLESS the player holds a banana — offering it grants
## the Crop Truce (plots immune for the day, +3 harmony, zero harm to the
## monkeys — they get the banana, everyone wins).

@export var festival_day: int = 9
var _triggered_keys: Dictionary = {}
var _truce_day: int = -1

func _ready() -> void:
	add_to_group("festival_manager")
	SignalBus.minute_ticked.connect(_on_minute_ticked)

func _exit_tree() -> void:
	if SignalBus.minute_ticked.is_connected(_on_minute_ticked):
		SignalBus.minute_ticked.disconnect(_on_minute_ticked)

func _on_minute_ticked(day: int, hour: int, _minute: int) -> void:
	var tm: Node = SignalBus.time_manager
	var season: String = "hot"
	var dos: int = festival_day
	if tm != null and "current_season" in tm:
		season = String(tm.current_season)
		if tm.has_method("day_of_season"):
			dos = int(tm.day_of_season())
	elif "current_season" in GameData:
		season = String(GameData.current_season)
	if season != "hot" or dos != festival_day or hour < 12:
		return
	var tm_local: Node = SignalBus.time_manager
	var year: int = tm_local.year() if tm_local != null and tm_local.has_method("year") else 1
	var key: String = "%d-%s" % [year, season]
	if _triggered_keys.has(key):
		return
	_triggered_keys[key] = true
	raid()

func _raidable_plots() -> Array:
	var gm: Node = SignalBus.grid_manager
	var out: Array = []
	if gm != null and "plots" in gm:
		for cell: Vector2i in (gm.plots as Dictionary).keys():
			out.append(cell)
	return out

func raid() -> void:
	# Crop Truce active: monkeys eat the offered banana, plots safe.
	if _truce_day == 9 and GameData.has_item("banana", 1):
		GameData.remove_item("banana", 1)
		GameData.add_harmony(3)
		SignalBus.show_dialogue.emit("Lopburi Monkey Raid", "The monkeys take your banana — Crop Truce! The fields are safe. (+3 harmony)")
		return
	var gm: Node = SignalBus.grid_manager
	var plots: Array = _raidable_plots()
	if plots.is_empty():
		SignalBus.show_dialogue.emit("Lopburi Monkey Raid", "Monkeys scout the fields... nothing planted to raid.")
		return
	if GameData.has_item("banana", 1):
		_truce_day = 9
		GameData.remove_item("banana", 1)
		GameData.add_harmony(3)
		SignalBus.show_dialogue.emit("Lopburi Monkey Raid", "Monkeys raid! You offer a banana — Crop Truce declared. (+3 harmony)")
		return
	# Raid: clear up to 2 plots (soft loss — stage resets, not permanent harm).
	plots.shuffle()
	var raided: int = 0
	for cell: Vector2i in plots:
		if raided >= 2:
			break
		if gm.has_method("harvest"):
			# Raid = crop lost (harvest path without yield isn't exposed);
			# reset stage to 0 via plots dict directly, guarded.
			var ps: Variant = gm.plots.get(cell)
			if ps != null:
				ps.stage = 0
				ps.minutes_in_stage = 0
				raided += 1
	SignalBus.show_dialogue.emit("Lopburi Monkey Raid", "Monkeys raided %d plots! (Offer a banana tomorrow for a truce.)" % raided)
