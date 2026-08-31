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
	# auto-detect mobile by viewport + OS feature
	var vp := get_viewport().get_visible_rect().size
	is_mobile = vp.x < 900 or OS.has_feature("mobile")
	_apply_scale()
	SignalBus.stamina_changed.connect(_on_stamina_changed)
	SignalBus.village_harmony_changed.connect(_on_harmony_changed)
	SignalBus.village_goodwill_changed.connect(_on_harmony_changed)
	SignalBus.season_changed.connect(_on_season_changed)
	SignalBus.minute_ticked.connect(_on_minute_ticked)
	SignalBus.crop_growth_progress.connect(_on_crop_progress)
	SignalBus.show_dialogue.connect(_on_show_dialogue_for_prompt)
	# viewport resize -> re-evaluate mobile scale (TASK-014 80% polish)
	get_viewport().size_changed.connect(_on_viewport_resized)
	# init from GameData
	_on_stamina_changed(GameData.current_stamina, GameData.max_stamina)
	_on_harmony_changed(GameData.harmony)
	_on_season_changed(GameData.current_season)
	# action prompt starts hidden, polished fade
	if prompt_label:
		prompt_label.get_parent().visible = false
		prompt_label.get_parent().modulate.a = 0.0

func _on_viewport_resized() -> void:
	var vp := get_viewport().get_visible_rect().size
	var now_mobile := vp.x < 900 or OS.has_feature("mobile")
	if now_mobile != is_mobile:
		is_mobile = now_mobile

func _apply_scale() -> void:
	var s: float = mobile_scale if is_mobile else pc_scale
	if has_node("Margin"):
		$Margin.scale = Vector2(s, s)
	# prompt scales with HUD but keeps readable at 80%: bump font slightly on mobile
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

func _on_show_dialogue_for_prompt(speaker: String, text: String) -> void:
	# Polish: show action prompt briefly for system messages, then fade
	if not prompt_label:
		return
	var prompt_root: Control = prompt_label.get_parent() as Control
	if prompt_root == null:
		return
	# Map dialogue to prompt for interactable hints; keep short
	if text.length() > 0 and text.length() < 80:
		prompt_label.text = text
	prompt_root.visible = true
	if _prompt_tween:
		_prompt_tween.kill()
	_prompt_tween = create_tween()
	prompt_root.modulate.a = 1.0
	_prompt_tween.tween_interval(2.2)
	_prompt_tween.tween_property(prompt_root, "modulate:a", 0.0, 0.5)
	_prompt_tween.tween_callback(func(): prompt_root.visible = false)

func show_action_prompt(text: String) -> void:
	_on_show_dialogue_for_prompt("Prompt", text)

func hide_action_prompt() -> void:
	if prompt_label:
		var r: Control = prompt_label.get_parent() as Control
		if r:
			r.visible = false

# For manual testing
func set_mobile(v: bool) -> void:
	is_mobile = v
