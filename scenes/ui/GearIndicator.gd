extends Control
## TASK-359 — tap-to-cycle-fishing-gear widget (mobile). Mirrors SeedIndicator.gd
## exactly: converts a tap into the existing "cycle_fishing_gear" action event via
## Input.parse_input_event() so anything already listening for the action
## keeps working identically regardless of input source. The label this
## control owns is updated by HUD.gd; this script only owns the touch-to-
## action indirection — same structural precedent as SeedIndicator.gd, so
## any future controller work finds one pattern, not a parallel one.

func _ready() -> void:
	custom_minimum_size = Vector2(88, 88)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_emit_cycle_gear()
		accept_event()

func _emit_cycle_gear() -> void:
	var press: InputEventAction = InputEventAction.new()
	press.action = "cycle_fishing_gear"
	press.pressed = true
	Input.parse_input_event(press)
