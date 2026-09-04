extends CanvasLayer

## CompletionTracker — TASK-378 UI overlay for the unified completion percentage / checklist screen.
## Mirrors Settings.tscn and MarketShop.tscn full-screen overlay patterns.
## Shows total perfection percentage and a detailed checklist of all six completion categories.

@onready var _percentage_label: Label = $Panel/VBox/PercentageLabel
@onready var _checklist_grid: GridContainer = $Panel/VBox/ScrollContainer/ChecklistGrid
@onready var _close_button: Button = $Panel/VBox/CloseButton

## Statistics storage (computed on-demand via GameData.completion_percentage())
var _categories: Array[Dictionary] = [
	{"id": "milestones", "name": "Milestones earned", "description": "All 5 completionist milestones (deep_miner, master_angler, inseparable, herd_keeper, storm_catch)"},
	{"id": "fish_almanac", "name": "Fish Almanac", "description": "At least one fish catch recorded"},
	{"id": "recipe_unlocks", "name": "Recipe unlocks", "description": "At least one recipe unlocked via romance gifts"},
	{"id": "decor_choices", "name": "Decor choices", "description": "At least one farmhouse decor style selected"},
	{"id": "romance_spouse", "name": "Romance completed", "description": "Married to a romance candidate (spouse set)"},
	{"id": "romance_candidates", "name": "Romance candidates", "description": "At least one of the 6 romance candidates reached romantic level"},
]

func _ready() -> void:
	visible = false
	# Ensure HUD button wiring (see HUD.gd) will call open() when pressed.
	_close_button.pressed.connect(close)

func open() -> void:
	_refresh()
	visible = true

func close() -> void:
	visible = false

func _refresh() -> void:
	# GameData is the autoload singleton — called directly, same as every
	# other script in this codebase (GameData.has_item(), etc.). The
	# original draft looked GameData up via Engine.get_main_loop() and
	# cast it `as GameData`, which doesn't even parse (no `class_name
	# GameData` exists on that script) — that broke GameData.gd's own
	# compile, crashing the whole autoload on boot.
	var percentage: float = GameData.completion_percentage()
	_percentage_label.text = "%d%% Complete" % [int(percentage)]

	for child in _checklist_grid.get_children():
		child.queue_free()

	for cat: Dictionary in _categories:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var label := Label.new()
		label.text = String(cat["name"])
		label.custom_minimum_size = Vector2(180, 0)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		row.add_child(label)

		var status: String = _get_category_status(String(cat["id"]))
		var status_label := Label.new()
		status_label.text = status
		status_label.custom_minimum_size = Vector2(60, 0)
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if status == "✓" or status == "✓✓":
			status_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		else:
			status_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
		row.add_child(status_label)

		var detail := Label.new()
		detail.text = String(cat["description"])
		detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		detail.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		detail.add_theme_font_size_override("font_size", 10)
		row.add_child(detail)

		_checklist_grid.add_child(row)

func _get_category_status(cat_id: String) -> String:
	match cat_id:
		"milestones":
			var earned: int = 0
			for id in ["deep_miner", "master_angler", "inseparable", "herd_keeper", "storm_catch"]:
				if GameData.milestones_earned.get(id, false):
					earned += 1
			return "✓" if earned == 5 else "✗"
		"fish_almanac":
			return "✓" if not GameData.fish_almanac.is_empty() else "✗"
		"recipe_unlocks":
			return "✓" if not GameData.recipe_unlocks.is_empty() else "✗"
		"decor_choices":
			return "✓" if not GameData.decor_choices.is_empty() else "✗"
		"romance_spouse":
			return "✓" if GameData.spouse != "" else "✗"
		"romance_candidates":
			var romanced_count: int = 0
			for candidate_id in GameData.ROMANCE_CANDIDATE_IDS:
				if GameData.affinity.has(candidate_id) and GameData.level_for(int(GameData.affinity[candidate_id])) >= 5:
					romanced_count += 1
			return "✓✓" if romanced_count >= 1 else "✗"
		_:
			return "?"
