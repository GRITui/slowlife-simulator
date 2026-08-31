extends CanvasLayer
## Settings — TASK-027 accessibility panel (font scale + high contrast).
## Emits SignalBus.settings_changed; HUD and SaveManager react. Hidden by
## default, toggled with F10. No direct HUD references — fully bus-decoupled.

@onready var _slider: HSlider = $Panel/VBox/FontScaleRow/FontScaleSlider if has_node("Panel/VBox/FontScaleRow/FontScaleSlider") else null
@onready var _hc_check: CheckBox = $Panel/VBox/HighContrastCheck if has_node("Panel/VBox/HighContrastCheck") else null

func _ready() -> void:
	visible = false
	if _slider:
		_slider.min_value = 0.8
		_slider.max_value = 1.4
		_slider.step = 0.05
		_slider.value_changed.connect(_on_slider_changed)
	if _hc_check:
		_hc_check.toggled.connect(_on_hc_toggled)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F10:
		visible = not visible
		get_viewport().set_input_as_handled()

func _on_slider_changed(value: float) -> void:
	SignalBus.settings_changed.emit(value, _hc_check.toggled if _hc_check else false)

func _on_hc_toggled(pressed: bool) -> void:
	SignalBus.settings_changed.emit(_slider.value if _slider else 1.0, pressed)
