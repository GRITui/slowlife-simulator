extends CanvasLayer

## CompletionTracker — TASK-378 UI overlay for the unified completion percentage / checklist screen.
## Mirrors Settings.tscn and MarketShop.tscn full-screen overlay patterns.
## Shows total perfection percentage and a detailed checklist of all six completion categories.

@onready var _percentage_label: Label = $VBox/PercentageLabel
@onready var _checklist_grid: GridContainer = $VBox/ScrollContainer/ChecklistGrid
@onready var _close_button: Button = $VBox/CloseButton

## Statistics storage (computed on-demand via GameData.completion_percentage())
var _categories = [
    {"id": "milestones", "name": "Milestones earned", "required": 5, "description": "All 5 completionist milestones (deep_miner, master_angler, inseparable, herd_keeper, storm_catch)"},
    {"id": "fish_almanac", "name": "Fish Almanac", "required": 1, "description": "At least one fish catch recorded"},
    {"id": "recipe_unlocks", "name": "Recipe unlocks", "required": 1, "description": "At least one recipe unlocked via romance gifts"},
    {"id": "decor_choices", "name": "Decor choices", "required": 1, "description": "At least one farmhouse decor style selected"},
    {"id": "romance_spouse", "name": "Romance completed", "required": 1, "description": "Married to a romance candidate (spouse set)"},
    {"id": "romance_candidates", "name": "Romance candidates", "required": 1, "description": "At least one of the 6 romance candidates reached romantic level (affinity >= 90)"}
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
    # Get data from GameData singleton (main loop)
    var main: Node = Engine.get_main_loop().root.get_node("GameData") as GameData
    if not main:
        return

    # Compute percentage using the new GameData.completion_percentage() static method
    var percentage: float = GameData.completion_percentage()
    _percentage_label.text = "%d%% Complete" % [int(percentage)]

    # Clear existing checklist rows
    for child in _checklist_grid.get_children():
        child.queue_free()

    # Add rows for each category
    for i in range(_categories.size()):
        var cat = _categories[i]
        var row = HBoxContainer.new()
        row.add_theme_constant_override("separation", 12)
        row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

        # Category label
        var label = Label.new()
        label.text = cat["name"]
        label.custom_minimum_size = Vector2(180, 0)
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
        row.add_child(label)

        # Status indicator (green check for completed, red X for not)
        var status: String = _get_category_status(main, cat["id"])
        var status_label = Label.new()
        status_label.text = status
        status_label.custom_minimum_size = Vector2(60, 0)
        status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        if status == "✓" or status == "✓✓":
            status_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))  # green
        else:
            status_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))  # red
        row.add_child(status_label)

        # Detail label (hover hint)
        var detail = Label.new()
        detail.text = cat["description"]
        detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        detail.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
        detail.add_theme_font_sizes_override("font_size", 10)
        row.add_child(detail)

        _checklist_grid.add_child(row)

func _get_category_status(main: GameData, cat_id: String) -> String:
    match cat_id:
        "milestones":
            var earned: int = 0
            for id in ["deep_miner", "master_angler", "inseparable", "herd_keeper", "storm_catch"]:
                if main.milestones_earned.get(id, false):
                    earned += 1
            return "✓" if earned == 5 else "✗"
        "fish_almanac":
            return "✓" if main.fish_almanac.size() > 0 else "✗"
        "recipe_unlocks":
            return "✓" if main.recipe_unlocks.size() > 0 else "✗"
        "decor_choices":
            return "✓" if main.decor_choices.size() > 0 else "✗"
        "romance_spouse":
            return "✓" if main.spouse != "" else "✗"
        "romance_candidates":
            var romance_candidates: Array[String] = ["ek", "fah", "ploy", "klong", "chang", "yaa"]
            var romanced_count: int = 0
            for candidate in romance_candidates:
                if main.affinity.has(candidate) and GameData.level_for(int(main.affinity[candidate])) >= 5:
                    romanced_count += 1
            return "✓✓" if romanced_count >= 1 else "✗"
        _:
            return "?"
