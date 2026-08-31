extends CharacterBody2D
# Player — Farmer (Hybrid A/B, 16-color, Mo Hom + Pha Khao Ma)
# Moves via move_left/right/up/down (project.godot:19), interacts via E/Space.
# Stamina drain uses TimeManager stamina multiplier, syncs to SignalBus + GameData.

@export var move_speed: float = 110.0
@export var stamina_drain_per_sec: float = 0.6

var _season_mult: float = 1.0

func _ready() -> void:
	add_to_group("player")
	SignalBus.season_changed.connect(_on_season_changed)
	# init stamina display
	SignalBus.stamina_changed.emit(GameData.current_stamina, GameData.max_stamina)
	# cache season mult
	var tm := _find_tm()
	if tm:
		_season_mult = tm.get_stamina_multiplier() if tm.has_method("get_stamina_multiplier") else 1.0

func _physics_process(delta: float) -> void:
	# stamina drain
	var drain := stamina_drain_per_sec * _season_mult * delta
	if drain > 0 and GameData.current_stamina > 0:
		GameData.current_stamina = max(0.0, GameData.current_stamina - drain)
	# movement (WASD + arrows via project.godot move_*)
	var dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if dir.length() > 1.0:
		dir = dir.normalized()
	velocity = dir * move_speed
	move_and_slide()
	# clamp to Hybrid grid bounds (20*32 approx, keep in view)
	global_position.x = clamp(global_position.x, 16, 20 * 32 - 16)
	global_position.y = clamp(global_position.y, 16, 16 * 32 - 16)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_grid_interact()

func _try_grid_interact() -> void:
	# Find GridManager in scene and attempt plant/water/harvest at nearest cell
	var gm := _find_gm()
	if gm == null:
		return
	var cell: Vector2i = Vector2i(floor(global_position.x / 32), floor(global_position.y / 32))
	var plot = gm.get_plot(cell) if gm.has_method("get_plot") else null
	if plot == null:
		# try plant jasmine_rice if plantable
		if gm.is_plantable(cell):
			var crop: Resource = load("res://data/crops/jasmine_rice.tres")
			if crop and gm.plant(cell, crop):
				SignalBus.show_dialogue.emit("Farmer", "Planted jasmine rice.")
			else:
				SignalBus.show_dialogue.emit("Farmer", "Cannot plant here.")
		else:
			# maybe near monk? monk handles its own interact
			pass
	else:
		# has plot: if harvest-ready -> harvest, else water
		if plot.stage >= plot.crop.total_stages - 1:
			var y: int = gm.harvest(cell)
			if y > 0:
				SignalBus.show_dialogue.emit("Farmer", "Harvested +%d %s." % [y, plot.crop.yield_item_id])
			else:
				SignalBus.show_dialogue.emit("Farmer", "Not ready or too tired.")
		else:
			if gm.water(cell):
				SignalBus.show_dialogue.emit("Farmer", "Watered plot.")
			else:
				SignalBus.show_dialogue.emit("Farmer", "Already watered.")

func _on_season_changed(s: String) -> void:
	var tm := _find_tm()
	if tm and tm.has_method("get_stamina_multiplier"):
		_season_mult = tm.get_stamina_multiplier()
	else:
		match s:
			"hot": _season_mult = 1.3
			"monsoon": _season_mult = 0.8
			_: _season_mult = 1.0

func _find_tm() -> Node:
	if has_node("/root/TimeManager"):
		return get_node("/root/TimeManager")
	var r := get_tree().current_scene if get_tree() else null
	if r:
		var f := r.find_child("TimeManager", true, false)
		if f: return f
	return null

func _find_gm() -> Node:
	var r := get_tree().current_scene if get_tree() else null
	if r:
		var f := r.find_child("GridManager", true, false)
		if f: return f
	for c in get_tree().root.get_children():
		if c.has_method("plant"):
			return c
	return null
