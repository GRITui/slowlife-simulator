extends Control
## TASK-036 — tap-to-interact zone (mobile). Converts a tap into the
## existing "interact" action event so MonkNPC/VillagerNPC/SluiceGate/
## MarketStall contracts work untouched.

func _ready() -> void:
	custom_minimum_size = Vector2(88, 88)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_emit_interact()
		accept_event()

func _emit_interact() -> void:
	var press: InputEventAction = InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	Input.parse_input_event(press)
