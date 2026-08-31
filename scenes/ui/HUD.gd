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

# TASK-027 accessibility — font scaling (0.8-1.4) + high-contrast mode.
const _BASE_FONT_SIZES: Dictionary = {
	"StaminaLabel": 12, "HarmonyLabel": 12, "SeasonLabelLabel": 10,
	"SeasonLabel": 13, "TimeLabelHeader": 12, "TimeLabel": 13,
	"CropLabel": 12, "PromptLabel": 13,
}
@export var font_scale: float = 1.0
@export var high_contrast: bool = false

func set_font_scale(s: float) -> void:
	font_scale = clampf(s, 0.8, 1.4)
	for node_name: String in _BASE_FONT_SIZES.keys():
		var label: Label = find_child(node_name, true, false) as Label
		if label:
			label.add_theme_font_size_override("font_size",
				int(_BASE_FONT_SIZES[node_name] * font_scale))

func set_high_contrast(v: bool) -> void:
	high_contrast = v
	if high_contrast:
		# WCAG-AA: white fill on dark under, brightened season chip.
		if stamina_bar:
			stamina_bar.tint_under = Color(0.05, 0.05, 0.05)
			stamina_bar.tint_progress = Color(1, 1, 1)
		if harmony_bar:
			harmony_bar.tint_under = Color(0.05, 0.05, 0.05)
			harmony_bar.tint_progress = Color(1, 1, 1)
		var bg: TextureRect = find_child("SeasonBg", true, false) as TextureRect
		if bg:
			bg.modulate = Color(1.5, 1.5, 1.5)
	else:
		if stamina_bar:
			stamina_bar.tint_under = Color(1, 1, 1)
		if harmony_bar:
			harmony_bar.tint_under = Color(1, 1, 1)
		var bg2: TextureRect = find_child("SeasonBg", true, false) as TextureRect
		if bg2:
			bg2.modulate = Color(1, 1, 1)
		# Restore seasonal tints on the bars.
		_on_stamina_changed(GameData.current_stamina, GameData.max_stamina)
		_on_harmony_changed(GameData.harmony)

func _on_settings_changed(s: float, hc: bool) -> void:
	set_font_scale(s)
	set_high_contrast(hc)

# TASK-028 iOS safe area — insets the HUD MarginContainer by the notch /
# Dynamic Island / home-indicator gaps reported by the OS. Desktop and
# headless report an empty safe rect, so the call no-ops there (gate-safe).
func apply_safe_area() -> void:
	if not is_mobile:
		return
	var safe := DisplayServer.get_display_safe_area()
	var win := DisplayServer.window_get_size()
	if safe.size == Vector2i.ZERO or win == Vector2i.ZERO:
		return
	var margin := $Margin if has_node("Margin") else null
	if margin == null:
		return
	# Safe rect is in window coordinates on iOS fullscreen (window origin
	# 0,0); maxi guards against exotic geometries on tablet.
	var left: int = maxi(0, safe.position.x)
	var top: int = maxi(0, safe.position.y)
	var right: int = maxi(0, win.x - (safe.position.x + safe.size.x))
	var bottom: int = maxi(0, win.y - (safe.position.y + safe.size.y))
	if left > 0:
		margin.offset_left += left
	if top > 0:
		margin.offset_top += top
	if right > 0:
		margin.offset_right -= right
	if bottom > 0:
		margin.offset_bottom -= bottom

func _ready() -> void:
	# auto-detect mobile by viewport
	var vp := get_viewport().get_visible_rect().size
	is_mobile = vp.x < 900 or OS.has_feature("mobile")
	_apply_scale()
	# TASK-028 iOS safe area — notch / Dynamic Island / home indicator insets.
	apply_safe_area()
	SignalBus.stamina_changed.connect(_on_stamina_changed)
	SignalBus.village_harmony_changed.connect(_on_harmony_changed)
	SignalBus.village_goodwill_changed.connect(_on_harmony_changed)
	SignalBus.season_changed.connect(_on_season_changed)
	SignalBus.minute_ticked.connect(_on_minute_ticked)
	SignalBus.crop_growth_progress.connect(_on_crop_progress)
	SignalBus.settings_changed.connect(_on_settings_changed)
	# TASK-027: restore persisted a11y prefs (defaults keep legacy behavior).
	set_font_scale(GameData.font_scale)
	set_high_contrast(GameData.high_contrast)
	# init from GameData
	_on_stamina_changed(GameData.current_stamina, GameData.max_stamina)
	_on_harmony_changed(GameData.harmony)
	_on_season_changed(GameData.current_season)

func _apply_scale() -> void:
	var s: float = mobile_scale if is_mobile else pc_scale
	if has_node("Margin"):
		$Margin.scale = Vector2(s, s)

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

# --- Action prompt polish (TASK-014) ---
# Context-sensitive prompt, mobile-aware sizing, fade on mobile 80% scale stays readable.

func show_prompt(text: String) -> void:
	if prompt_label:
		prompt_label.text = text
		var parent: Control = prompt_label.get_parent() as Control
		if parent:
			parent.visible = true
			parent.modulate.a = 1.0

func hide_prompt() -> void:
	if prompt_label:
		var parent: Control = prompt_label.get_parent() as Control
		if parent:
			parent.visible = false

func update_prompt_for_proximity(has_target: bool, action: String = "Press [E] to interact") -> void:
	if has_target:
		show_prompt(action)
	else:
		hide_prompt()

# For manual testing
func set_mobile(v: bool) -> void:
	is_mobile = v

# TASK-018 Inventory UI — display GameData.inventory
func refresh_inventory() -> void:
	var slots: Array = [$Margin/Root/InventoryRow/Slot1, $Margin/Root/InventoryRow/Slot2, $Margin/Root/InventoryRow/Slot3, $Margin/Root/InventoryRow/Slot4] if has_node("Margin/Root/InventoryRow/Slot1") else []
	var idx: int = 0
	for item_id in GameData.inventory.keys():
		if idx >= slots.size():
			break
		var qty: int = int(GameData.inventory[item_id])
		# Show quantity via tooltip; icon wiring via TASK-019 assets/items
		var tex: Texture2D = slots[idx].texture
		slots[idx].tooltip_text = "%s x%d" % [item_id, qty]
		idx += 1
# ENGINE-012 Mobile touch — virtual joystick stub, feeds move_* actions
var _touch_origin: Vector2 = Vector2.ZERO
var _touch_active: bool = false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_touch_active = event.pressed
		_touch_origin = event.position
	elif event is InputEventScreenDrag and _touch_active:
		var delta: Vector2 = event.position - _touch_origin
		if delta.x > 10:
			Input.action_press("move_right")
		else:
			Input.action_release("move_right")
		if delta.x < -10:
			Input.action_press("move_left")
		else:
			Input.action_release("move_left")
		if delta.y > 10:
			Input.action_press("move_down")
		else:
			Input.action_release("move_down")
		if delta.y < -10:
			Input.action_press("move_up")
		else:
			Input.action_release("move_up")
