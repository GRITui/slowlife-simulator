extends CanvasLayer
# HUD — Dynamic scaling PC/Mobile with Harmony meter, stamina, season/time, inventory, action prompt
# ART SPRINT: TASK-014 mobile 80% + polish, TASK-018 inventory display, TASK-017 pause integration

@export var mobile_scale: float = 0.8
@export var pc_scale: float = 1.0
@export var is_mobile: bool = false:
	set(v):
		is_mobile = v
		_apply_scale()

@onready var stamina_bar: TextureProgressBar = $Margin/Root/HBox/StaminaBox/StaminaBar if has_node("Margin/Root/HBox/StaminaBox/StaminaBar") else null
@onready var harmony_bar: TextureProgressBar = $Margin/Root/HBox/HarmonyBox/HarmonyBar if has_node("Margin/Root/HBox/HarmonyBox/HarmonyBar") else null
@onready var season_label: Label = $Margin/Root/HBox/SeasonBox/SeasonVBox/SeasonLabel if has_node("Margin/Root/HBox/SeasonBox/SeasonVBox/SeasonLabel") else null
@onready var time_label: Label = $Margin/Root/HBox/TimeBox/TimeLabel if has_node("Margin/Root/HBox/TimeBox/TimeLabel") else null
@onready var crop_label: Label = $Margin/Root/CropProgress/CropLabel if has_node("Margin/Root/CropProgress/CropLabel") else null
@onready var prompt_label: Label = $Margin/Root/ActionPrompt/PromptLabel if has_node("Margin/Root/ActionPrompt/PromptLabel") else null
@onready var prompt_bg: TextureRect = $Margin/Root/ActionPrompt/PromptBg if has_node("Margin/Root/ActionPrompt/PromptBg") else null
@onready var inventory_row: HBoxContainer = $Margin/Root/InventoryRow if has_node("Margin/Root/InventoryRow") else null

var _max_stamina: float = 100.0
var _max_harmony: int = 100
var _prompt_tween: Tween
var _inventory_icons: Dictionary = {
	"rice_grain": "res://assets/items/rice_grain.png",
	"seed_rice": "res://assets/items/seed_basil.png",
	"seed_basil": "res://assets/items/seed_basil.png",
	"seed_lotus": "res://assets/items/seed_lotus.png",
	"seed_mango": "res://assets/items/seed_mango.png",
	"lotus_root": "res://assets/items/lotus_root.png",
	"mango": "res://assets/items/mango.png",
	"pandan_leaf": "res://assets/items/pandan_leaf.png",
	"sticky_rice": "res://assets/items/rice_grain.png",
}

func _ready() -> void:
	_detect_mobile()
	_apply_scale()
	_setup_inventory_slots()
	SignalBus.stamina_changed.connect(_on_stamina_changed)
	SignalBus.village_harmony_changed.connect(_on_harmony_changed)
	SignalBus.village_goodwill_changed.connect(_on_harmony_changed)
	SignalBus.season_changed.connect(_on_season_changed)
	SignalBus.minute_ticked.connect(_on_minute_ticked)
	SignalBus.crop_growth_progress.connect(_on_crop_progress)
	SignalBus.inventory_changed.connect(_on_inventory_changed)
	SignalBus.action_prompt_changed.connect(_on_action_prompt_changed)
	SignalBus.pause_toggled.connect(_on_pause_toggled)
	# init from GameData
	_on_stamina_changed(GameData.current_stamina, GameData.max_stamina)
	_on_harmony_changed(GameData.harmony)
	_on_season_changed(GameData.current_season)
	_on_inventory_changed(GameData.inventory)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_detect_mobile()
		_apply_scale()

func _detect_mobile() -> void:
	var vp := get_viewport().get_visible_rect().size if get_viewport() else Vector2(1600, 900)
	is_mobile = vp.x < 900 or vp.y < 600 or OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()

func _apply_scale() -> void:
	var s: float = mobile_scale if is_mobile else pc_scale
	if has_node("Margin"):
		$Margin.scale = Vector2(s, s)
		# Also adjust margin to keep HUD visible on small screens
		if is_mobile:
			$Margin.offset_left = 8
			$Margin.offset_top = 6
		else:
			$Margin.offset_left = 12
			$Margin.offset_top = 10

func _setup_inventory_slots() -> void:
	if inventory_row == null:
		return
	# Ensure 4 slots have count labels
	for i in range(inventory_row.get_child_count()):
		var slot: TextureRect = inventory_row.get_child(i) as TextureRect
		if slot == null:
			continue
		if slot.get_node_or_null("CountLabel") == null:
			var lbl := Label.new()
			lbl.name = "CountLabel"
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			lbl.add_theme_font_size_override("font_size", 10)
			lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
			lbl.add_theme_constant_override("shadow_offset_x", 1)
			lbl.add_theme_constant_override("shadow_offset_y", 1)
			lbl.anchors_preset = 15
			lbl.anchor_right = 1.0
			lbl.anchor_bottom = 1.0
			lbl.offset_left = -4
			lbl.offset_top = -4
			slot.add_child(lbl)

func _on_stamina_changed(cur: float, max_v: float) -> void:
	_max_stamina = max_v
	if stamina_bar:
		stamina_bar.max_value = max_v
		stamina_bar.value = cur
		var t: float = cur / max(max_v, 1.0)
		if t > 0.5:
			stamina_bar.tint_progress = Color(0.68, 0.83, 0.5)
		elif t > 0.25:
			stamina_bar.tint_progress = Color(0.99, 0.84, 0.2)
		else:
			stamina_bar.tint_progress = Color(0.95, 0.56, 0.69)

func _on_harmony_changed(v: int) -> void:
	if harmony_bar:
		harmony_bar.max_value = _max_harmony
		harmony_bar.value = v
		harmony_bar.tint_progress = Color(0.95, 0.56, 0.69)

func _on_season_changed(s: String) -> void:
	if season_label:
		season_label.text = s.capitalize()
		match s:
			"hot": season_label.modulate = Color(1.0, 0.6, 0.0)
			"monsoon": season_label.modulate = Color(0.13, 0.59, 0.95)
			"cool": season_label.modulate = Color(0.0, 0.59, 0.53)
			_: season_label.modulate = Color(1, 1, 1)

func _on_minute_ticked(day: int, hour: int, minute: int) -> void:
	if time_label:
		time_label.text = "%02d:%02d  Day %d" % [hour, minute, day]

func _on_crop_progress(_crop_id: int, progress: int, max_stage: int) -> void:
	if crop_label:
		crop_label.text = "Crop %d/%d" % [progress + 1, max_stage]

func _on_inventory_changed(inv: Dictionary) -> void:
	if inventory_row == null:
		return
	var keys: Array = inv.keys()
	keys.sort()
	for i in range(inventory_row.get_child_count()):
		var slot: TextureRect = inventory_row.get_child(i) as TextureRect
		var count_lbl: Label = slot.get_node_or_null("CountLabel") as Label if slot else null
		if i < keys.size():
			var item_id: String = str(keys[i])
			var count: int = int(inv[item_id])
			var icon_path: String = _inventory_icons.get(item_id, "res://assets/ui/inventory_slot.png")
			if ResourceLoader.exists(icon_path):
				slot.texture = load(icon_path) as Texture2D
			if count_lbl:
				count_lbl.text = str(count) if count > 1 else ""
				count_lbl.visible = count > 1
			slot.modulate = Color(1, 1, 1, 1)
		else:
			slot.texture = load("res://assets/ui/inventory_slot.png") as Texture2D
			if count_lbl:
				count_lbl.text = ""
			slot.modulate = Color(1, 1, 1, 0.6)

func _on_action_prompt_changed(text: String, visible: bool) -> void:
	if prompt_label == null:
		return
	prompt_label.text = text
	var prompt_ctrl: Control = prompt_label.get_parent() as Control if prompt_label else null
	if prompt_ctrl:
		prompt_ctrl.visible = visible and not text.is_empty()
	if visible and not text.is_empty():
		_animate_prompt()
	else:
		if _prompt_tween:
			_prompt_tween.kill()
			_prompt_tween = null

func _animate_prompt() -> void:
	if prompt_label == null:
		return
	if _prompt_tween:
		_prompt_tween.kill()
	_prompt_tween = create_tween()
	_prompt_tween.set_loops()
	_prompt_tween.tween_property(prompt_label, "modulate:a", 0.6, 0.8)
	_prompt_tween.tween_property(prompt_label, "modulate:a", 1.0, 0.8)

func _on_pause_toggled(is_paused: bool) -> void:
	# Dim HUD when paused
	if has_node("Margin"):
		$Margin.modulate = Color(1, 1, 1, 0.5) if is_paused else Color(1, 1, 1, 1)

func set_mobile(v: bool) -> void:
	is_mobile = v
