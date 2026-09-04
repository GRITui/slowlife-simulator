extends CharacterBody2D
# Player — Farmer (Hybrid A/B, 16-color, Mo Hom + Pha Khao Ma)
# Moves via move_left/right/up/down (project.godot:19), interacts via E/Space.
# Stamina drain uses TimeManager stamina multiplier, syncs to SignalBus + GameData.

@export var move_speed: float = 110.0
## Movement clamp bounds -- default matches the outdoor World's own size
## (20x16 tiles @ 48px, minus a 24px margin so the player's collision
## shape never clips a boundary wall). InteriorBase._apply_camera_bounds()
## overrides these to each interior's own (smaller) GRID/TILE size on
## spawn, so a small room like FarmHouse/CoastalArea doesn't let the
## player walk into space beyond the actual floor tiles -- found live
## during a manual playthrough: the player sprite rendered partly below
## the visible floor in CoastalArea because this clamp was still using
## the outdoor World's bounds regardless of which scene was active
## (the same root cause the earlier Camera2D bounds fix addressed, but
## for movement rather than the camera).
@export var bounds_min: Vector2 = Vector2(24, 24)
@export var bounds_max: Vector2 = Vector2(20 * 48 - 24, 16 * 48 - 24)
## TASK-272 Wing Kwai: mounted buffalo riding (mount near buffalo, 1.6x speed,
## mounted interact auto-plants the held seed in a 3x3 patch).
var mounted: bool = false
var mount_speed_mult: float = 1.6
var _buffalo_ref: Node = null
@export var stamina_drain_per_sec: float = 0.6

var _season_mult: float = 1.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("player")
	SignalBus.season_changed.connect(_on_season_changed)
	# init stamina display
	SignalBus.stamina_changed.emit(GameData.current_stamina, GameData.max_stamina)
	# cache season mult (SignalBus.time_manager registry, not a node path — ENGINE-006)
	if SignalBus.time_manager:
		_season_mult = SignalBus.time_manager.get_stamina_multiplier()

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
	velocity = dir * (move_speed * (mount_speed_mult if mounted else 1.0))
	move_and_slide()
	if mounted and _buffalo_ref != null and is_instance_valid(_buffalo_ref):
		(_buffalo_ref as Node2D).global_position = global_position + Vector2(0, 24)
	_update_animation(dir)
	# clamp to this scene's bounds (outdoor World by default; InteriorBase
	# overrides bounds_min/bounds_max per-interior on spawn -- see the
	# @export declarations above for why).
	global_position.x = clamp(global_position.x, bounds_min.x, bounds_max.x)
	global_position.y = clamp(global_position.y, bounds_min.y, bounds_max.y)

func _update_animation(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		if _sprite.animation != &"idle" or not _sprite.is_playing():
			_sprite.play(&"idle")
		return
	var next: StringName
	if absf(dir.x) >= absf(dir.y):
		next = &"walk_right" if dir.x > 0.0 else &"walk_left"
	else:
		next = &"walk_down" if dir.y > 0.0 else &"walk_up"
	if _sprite.animation != next or not _sprite.is_playing():
		_sprite.play(next)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_grid_interact()
	# TASK-350: cycle which held seed is "primed" for planting (Q key).
	if event.is_action_pressed("cycle_seed"):
		cycle_primed_seed()
	# TASK-272: R mounts/dismounts the buffalo (dedicated key avoids the
	# buffalo-milk interact conflict).
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		toggle_mount()

## TASK-350: cycle which held seed_* item is "primed" for planting.
## Wraps around; falls back to "" (no seed) if the player holds none.
func cycle_primed_seed() -> void:
	var held: Array[String] = []
	for item_id: String in GameData.inventory.keys():
		if String(item_id).begins_with("seed_") and int(GameData.inventory[item_id]) > 0:
			held.append(String(item_id))
	if held.is_empty():
		_primed_seed_id = ""
		SignalBus.show_dialogue.emit("Farmer", "No seeds to select.")
		return
	held.sort() # deterministic order, not Dictionary iteration order
	var idx: int = held.find(_primed_seed_id)
	_primed_seed_id = held[(idx + 1) % held.size()]
	# Ensure lookup is primed so we can name the selected crop.
	if _seed_lookup.is_empty():
		var dir: DirAccess = DirAccess.open("res://data/crops")
		if dir != null:
			dir.list_dir_begin()
			var fname: String = dir.get_next()
			while fname != "":
				if fname.ends_with(".tres"):
					var res: Resource = load("res://data/crops/" + fname)
					if res != null and "seed_item_id" in res:
						var sid: String = String(res.seed_item_id)
						if sid != "":
							_seed_lookup[sid] = res
				fname = dir.get_next()
	var crop: Resource = _seed_lookup.get(_primed_seed_id)
	var crop_name: String = String(crop.get("display_name")) if crop != null and "display_name" in crop else _primed_seed_id
	SignalBus.show_dialogue.emit("Farmer", "Seed selected: %s." % crop_name)

## TASK-272: mount/dismount. Buffalo repositions under the rider each frame
## while mounted (visual rider illusion without a ride node).
func toggle_mount() -> bool:
	if mounted:
		mounted = false
		SignalBus.show_dialogue.emit("Farmer", "Dismounted. The buffalo grazes.")
		return false
	var buffalos: Array = get_tree().get_nodes_in_group("buffalo")
	if buffalos.is_empty():
		SignalBus.show_dialogue.emit("Farmer", "No buffalo nearby to ride.")
		return false
	_buffalo_ref = buffalos[0]
	if _buffalo_ref != null and global_position.distance_to((_buffalo_ref as Node2D).global_position) > 96.0:
		SignalBus.show_dialogue.emit("Farmer", "Get closer to the buffalo to mount.")
		return false
	mounted = true
	SignalBus.show_dialogue.emit("Farmer", "Mounted — Wing Kwai style. Interact to auto-plant 3x3.")
	return true

## TASK-334: mounted interact — plant/water/harvest a 3x3 patch around the
## facing cell. Per-cell branch mirrors the single-cell logic in
## _try_grid_interact()'s unmounted path: null plot -> plant (held seed or
## jasmine fallback), harvest-ready -> harvest, else -> water. One summary
## dialogue line at the end omits any zero-count category.
func _mounted_interact_3x3(gm: Node, center: Vector2i) -> void:
	var crop: Resource = _find_crop_for_held_seed()
	if crop == null:
		crop = load("res://data/crops/jasmine_rice.tres")
	var planted: int = 0
	var watered: int = 0
	var harvested: int = 0
	for dx: int in [-1, 0, 1]:
		for dy: int in [-1, 0, 1]:
			var cell: Vector2i = center + Vector2i(dx, dy)
			var plot = gm.get_plot(cell) if gm.has_method("get_plot") else null
			if plot == null:
				if crop != null and gm.plant(cell, crop):
					planted += 1
			elif plot.stage >= plot.crop.total_stages - 1:
				if gm.harvest(cell) > 0:
					harvested += 1
			else:
				if gm.water(cell):
					watered += 1
	var parts: Array[String] = []
	if planted > 0:
		parts.append("%d planted" % planted)
	if harvested > 0:
		parts.append("%d harvested" % harvested)
	if watered > 0:
		parts.append("%d watered" % watered)
	var summary: String = ", ".join(parts) if not parts.is_empty() else "nothing to do"
	SignalBus.show_dialogue.emit("Farmer", "Buffalo plow: %s." % summary)

func _try_grid_interact() -> void:
	# Attempt plant/water/harvest at nearest cell via SignalBus.grid_manager registry
	var gm := SignalBus.grid_manager
	if gm == null:
		return
	var cell: Vector2i = Vector2i(floor(global_position.x / 48), floor(global_position.y / 48))
	if mounted:
		_mounted_interact_3x3(gm, cell)
		return
	var plot = gm.get_plot(cell) if gm.has_method("get_plot") else null
	if plot == null:
		# TASK-043: seed-driven planting — first owned seed_* item maps to its
		# CropData; falls back to jasmine_rice when no seeds are held (demo).
		# TASK-350: _find_crop_for_held_seed() now prefers _primed_seed_id
		# (Q-cycled selection) before falling back to "first held seed_*".
		var crop: Resource = _find_crop_for_held_seed()
		var used_fallback: bool = crop == null
		if used_fallback:
			# TASK-350: distinguish the no-seeds-held case (signal a
			# substitution) from the held-but-unprimed case (silent fall
			# through to "first held seed_*" via _find_crop_for_held_seed()
			# above, which still produces a normal "Planted %s." line).
			crop = load("res://data/crops/jasmine_rice.tres")
		if crop != null and gm.plant(cell, crop):
			if used_fallback:
				# Truly no seeds held (primed or otherwise). The substitution
				# line makes the no-fail-state guarantee explicit instead of
				# silently planting rice with the misleading "Planted Jasmine
				# Rice." line.
				SignalBus.show_dialogue.emit("Farmer", "No seed selected — planted rice instead.")
			else:
				var crop_name: String = String(crop.get("display_name")) if "display_name" in crop else "crop"
				SignalBus.show_dialogue.emit("Farmer", "Planted %s." % crop_name)
		else:
			SignalBus.show_dialogue.emit("Farmer", "Cannot plant here.")
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

func _find_crop_for_held_seed() -> Resource:
	# TASK-043: index data/crops/*.tres by seed_item_id once (static cache,
	# survives respawns). TASK-350: prefer the primed seed (set by
	# cycle_primed_seed()) over the legacy "first held seed_*" pick, so a
	# player who uses the new cycle feature actually plants what they
	# chose. The legacy first-held fallback below is kept for players who
	# never press Q (regression-safe default behavior).
	if _seed_lookup.is_empty():
		var dir: DirAccess = DirAccess.open("res://data/crops")
		if dir == null:
			return null
		dir.list_dir_begin()
		var fname: String = dir.get_next()
		while fname != "":
			if fname.ends_with(".tres"):
				var res: Resource = load("res://data/crops/" + fname)
				if res != null and "seed_item_id" in res:
					var sid: String = String(res.seed_item_id)
					if sid != "":
						_seed_lookup[sid] = res
			fname = dir.get_next()
	# TASK-350: primed seed wins when it's set AND still held (count > 0).
	if _primed_seed_id != "" and int(GameData.inventory.get(_primed_seed_id, 0)) > 0 \
			and _seed_lookup.has(_primed_seed_id):
		return _seed_lookup[_primed_seed_id] as Resource
	for item_id: String in GameData.inventory.keys():
		if String(item_id).begins_with("seed_") and _seed_lookup.has(String(item_id)):
			return _seed_lookup[String(item_id)] as Resource
	return null

static var _seed_lookup: Dictionary = {}

## TASK-350 — session-only, not persisted. The "primed" seed_* item that
## planting will use next. Lives on Player (not GameData) so it's not
## accidentally serialized by SaveManager later.
var _primed_seed_id: String = ""

func _on_season_changed(s: String) -> void:
	if SignalBus.time_manager:
		_season_mult = SignalBus.time_manager.get_stamina_multiplier()
	else:
		match s:
			"hot": _season_mult = 1.3
			"monsoon": _season_mult = 0.8
			_: _season_mult = 1.0
