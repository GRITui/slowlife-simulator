extends CanvasLayer
# HUD — Dynamic scaling PC/Mobile with Harmony meter, stamina, season/time
# EN only per .decision.json language=EN. Hybrid A/B 16-color palette.
# Signals: SignalBus stamina_changed, village_harmony_changed, season_changed, minute_ticked, crop_growth_progress

@export var mobile_scale: float = 0.8 # ART_STYLE_GUIDE mobile 80%
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

var _max_stamina: float = 100.0
var _max_harmony: int = 100

func _ready() -> void:
	# auto-detect mobile by viewport
	var vp := get_viewport().get_visible_rect().size
	is_mobile = vp.x < 900 or OS.has_feature("mobile")
	_apply_scale()
	SignalBus.stamina_changed.connect(_on_stamina_changed)
	SignalBus.village_harmony_changed.connect(_on_harmony_changed)
	SignalBus.village_goodwill_changed.connect(_on_harmony_changed)
	SignalBus.season_changed.connect(_on_season_changed)
	SignalBus.minute_ticked.connect(_on_minute_ticked)
	SignalBus.crop_growth_progress.connect(_on_crop_progress)
	SignalBus.inventory_changed.connect(_on_inventory_changed)
	get_viewport().size_changed.connect(_on_viewport_resized)
	# init from GameData
	_on_stamina_changed(GameData.current_stamina, GameData.max_stamina)
	_on_harmony_changed(GameData.harmony)
	_on_season_changed(GameData.current_season)
	_on_inventory_changed(GameData.inventory)
	# prompt starts hidden polished
	if prompt_label:
		prompt_label.get_parent().visible = false
	SignalBus.show_dialogue.connect(_on_show_dialogue_for_prompt)

func _on_viewport_resized() -> void:
	var vp := get_viewport().get_visible_rect().size
	var now_mobile := vp.x < 900 or OS.has_feature("mobile")
	if now_mobile != is_mobile:
		is_mobile = now_mobile

func _apply_scale() -> void:
	var s: float = mobile_scale if is_mobile else pc_scale
	if has_node("Margin"):
		$Margin.scale = Vector2(s, s)
	if prompt_label:
		prompt_label.add_theme_font_size_override("font_size", 12 if is_mobile else 13)

func _on_stamina_changed(cur: float, max_v: float) -> void:
	_max_stamina = max_v
	if stamina_bar:
		stamina_bar.max_value = max_v
		stamina_bar.value = cur
		# TextureProgressBar tint_progress drives fill color; keep modulate for fallback
		var t: float = cur / max(max_v, 1.0)
		if t > 0.5:
			stamina_bar.tint_progress = Color(0.68, 0.83, 0.5) # Pandan-ish
		elif t > 0.25:
			stamina_bar.tint_progress = Color(0.99, 0.84, 0.2) # Jasmine
		else:
			stamina_bar.tint_progress = Color(0.95, 0.56, 0.69) # Lotus

func _on_harmony_changed(v: int) -> void:
	if harmony_bar:
		harmony_bar.max_value = _max_harmony
		harmony_bar.value = v
	if harmony_bar:
		harmony_bar.tint_progress = Color(0.95, 0.56, 0.69) # Lotus Pink harmony

func _on_season_changed(s: String) -> void:
	if season_label:
		season_label.text = s.capitalize()
		match s:
			"hot": season_label.modulate = Color(1.0, 0.6, 0.0) # Hot Orange
			"monsoon": season_label.modulate = Color(0.13, 0.59, 0.95) # Monsoon Blue
			"cool": season_label.modulate = Color(0.0, 0.59, 0.53) # Cool Teal
			_: season_label.modulate = Color(1,1,1)

func _on_minute_ticked(day: int, hour: int, minute: int) -> void:
	if time_label:
		time_label.text = "%02d:%02d  Day %d" % [hour, minute, day]

func _on_crop_progress(_crop_id: int, progress: int, max_stage: int) -> void:
	if crop_label:
		crop_label.text = "Crop %d/%d" % [progress + 1, max_stage]

var _prompt_tween: Tween
var _inv_slots: Array = []
var _inv_labels: Array = []

func _on_inventory_changed(inv: Dictionary) -> void:
	# Lazy cache slots
	if _inv_slots.is_empty():
		var row := get_node_or_null("Margin/Root/InventoryRow")
		if row:
			for c in row.get_children():
				if c is TextureRect:
					_inv_slots.append(c)
					# add quantity label as child if missing
					var lbl := c.get_node_or_null("Qty")
					if lbl == null:
						lbl = Label.new()
						lbl.name = "Qty"
						lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
						lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
						lbl.add_theme_font_size_override("font_size", 10)
						lbl.add_theme_color_override("font_color", Color(1,1,1))
						lbl.add_theme_color_override("font_outline_color", Color(0,0,0,0.8))
						lbl.add_theme_constant_override("outline_size", 3)
						c.add_child(lbl)
						lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
						lbl.offset_left = -18
						lbl.offset_top = -14
						lbl.offset_right = -2
						lbl.offset_bottom = -2
					_inv_labels.append(lbl)
	if _inv_slots.is_empty():
		return
	# clear
	for i in _inv_slots.size():
		var tex_rect: TextureRect = _inv_slots[i] as TextureRect
		var lbl: Label = _inv_labels[i] as Label
		tex_rect.texture = load("res://assets/ui/inventory_slot.png") as Texture2D
		lbl.text = ""
		lbl.visible = false
	# fill in order of inventory keys
	var idx := 0
	for item_id in inv.keys():
		if idx >= _inv_slots.size():
			break
		var qty: int = int(inv[item_id])
		if qty <= 0:
			continue
		var icon_path := "res://assets/items/%s.png" % item_id
		# fallback: map seed/crop ids to icon names
		var map_dict := {
			"seed_rice": "seed_rice", "seed_pandan": "seed_pandan", "seed_basil": "seed_basil",
			"seed_lotus": "seed_lotus", "seed_mango": "seed_mango",
			"rice_grain": "rice_grain", "pandan_leaf": "pandan_leaf", "thai_basil": "thai_basil",
			"lotus_root": "lotus_root", "mango": "mango"
		}
		var mapped: String = map_dict.get(item_id, item_id) as String
		icon_path = "res://assets/items/%s.png" % mapped
		if not ResourceLoader.exists(icon_path):
			# try raw id
			icon_path = "res://assets/items/%s.png" % item_id
			if not ResourceLoader.exists(icon_path):
				idx += 1
				continue
		var tex: Texture2D = load(icon_path) as Texture2D
		if tex:
			(_inv_slots[idx] as TextureRect).texture = tex
			(_inv_labels[idx] as Label).text = "x%d" % qty if qty > 1 else ""
			(_inv_labels[idx] as Label).visible = qty > 1
		idx += 1

func _on_show_dialogue_for_prompt(speaker: String, text: String) -> void:
	if not prompt_label or text.length() == 0:
		return
	var root: Control = prompt_label.get_parent() as Control
	if root == null:
		return
	# show prompt for short messages
	if text.length() < 80:
		prompt_label.text = text
	root.visible = true
	if _prompt_tween:
		_prompt_tween.kill()
	_prompt_tween = create_tween()
	root.modulate.a = 1.0
	_prompt_tween.tween_interval(2.2)
	_prompt_tween.tween_property(root, "modulate:a", 0.0, 0.5)
	_prompt_tween.tween_callback(func(): root.visible = false)

# For manual testing
func set_mobile(v: bool) -> void:
	is_mobile = v
