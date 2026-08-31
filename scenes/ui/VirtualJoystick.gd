extends Control
## TASK-036 — on-screen virtual joystick (mobile). Feeds the existing
## move_* input actions with analog strength so Player.gd needs no changes.
## 44pt+ hit area; all actions released on exit (event-cleanup rule).

@export var radius: float = 56.0
@export var deadzone: float = 10.0

var _active: bool = false
var _origin: Vector2 = Vector2.ZERO
var _vector: Vector2 = Vector2.ZERO

func _ready() -> void:
	custom_minimum_size = Vector2(132, 132)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _draw() -> void:
	var center: Vector2 = size / 2.0
	draw_circle(center, radius, Color(1, 1, 1, 0.15))
	draw_circle(center + _vector * 0.5, 24.0, Color(1, 1, 1, 0.4))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_active = true
			_origin = event.position
		else:
			_release()
		queue_redraw()
		accept_event()
	elif event is InputEventScreenDrag and _active:
		_apply(event.position - _origin)
		accept_event()

func _apply(delta: Vector2) -> void:
	_vector = delta.limit_length(radius)
	if _vector.length() < deadzone:
		_vector = Vector2.ZERO
	var norm: Vector2 = _vector / radius
	_feed("move_right", norm.x)
	_feed("move_left", -norm.x)
	_feed("move_down", norm.y)
	_feed("move_up", -norm.y)
	queue_redraw()

func _feed(action: String, value: float) -> void:
	if value > 0.4:
		Input.action_press(action, clampf(value, 0.0, 1.0))
	else:
		Input.action_release(action)

func _release() -> void:
	_active = false
	_vector = Vector2.ZERO
	for action_name in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action_name)

func _exit_tree() -> void:
	_release()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
