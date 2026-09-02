extends Control
## TASK-350 — tap-to-cycle-seed widget (mobile). Mirrors InteractTap.gd
## exactly: converts a tap into the existing "cycle_seed" action event via
## Input.parse_input_event() so anything already listening for the action
## keeps working identically regardless of input source. The label this
## control owns is updated by HUD.gd; this script only owns the touch-to-
## action indirection.

func _ready() -> void:
	custom_minimum_size = Vector2(88, 88)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_emit_cycle_seed()
		accept_event()

func _emit_cycle_seed() -> void:
	var press: InputEventAction = InputEventAction.new()
	press.action = "cycle_seed"
	press.pressed = true
	Input.parse_input_event(press)