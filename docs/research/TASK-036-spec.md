# TASK-036 - Real virtual joystick + tap-to-interact (ENGINE-012 completion)

**Status:** `proposed` | **Priority:** high | **Category:** input/mobile | **Owner:** @engine-inspector
**Renderer:** `gl_compatibility` (Godot 4.7, iOS A14+, `OS.has_feature("mobile")` gate)
**Files:** `scenes/ui/HUD.tscn` (append nodes), `scenes/ui/HUD.gd` (replace _input stub), `scripts/ui/VirtualJoystick.gd` (new), `tests/ui/test_touch_targets.gd` (extend gate)
**Constraints:** strict-typed, SignalBus-decoupled, zero-combat, **Player.gd unchanged** (action-fed).

## Current state (audit, HUD.gd L201-226)
Single-finger full-screen drag fires all four `move_*` simultaneously when `|delta| > 10px` — no joystick, no deadzone, no off-screen gate. `interact` action exists (`project.godot` L80, E/Space) but unreachable on mobile. HUD already has `is_mobile` + `apply_safe_area()` (TASK-028) — reuse.

## Spec

Append to `HUD.tscn` (visible only when `is_mobile`): `JoystickZone` Control bottom-left 220×220; `JoystickBase` TextureRect 220×220 30% alpha at center; `JoystickKnob` TextureRect 96×96 at center; `InteractButton` BaseButton bottom-right 88×88 (≥44pt).

`scripts/ui/VirtualJoystick.gd` (strict-typed, single-finger, action-fed — `_gui_input` handles `InputEventScreenTouch`/`Drag`):
```gdscript
class_name VirtualJoystick extends Control
@export var radius: float = 80.0
@export var deadzone: float = 12.0
@export var action_x_pos: StringName = &"move_right"   # x_neg/y_pos/y_neg mirror
var _touch_index: int = -1
var _origin: Vector2 = Vector2.ZERO
func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and _touch_index == -1:
            _touch_index = event.index; _origin = event.position
        elif not event.pressed and event.index == _touch_index: _release()
    elif event is InputEventScreenDrag and event.index == _touch_index:
        var d: Vector2 = (event.position - _origin).limit_length(radius)
        var s: float = clampf((d.length() - deadzone) / (radius - deadzone), 0.0, 1.0)
        for pair in [[&"move_right", d.x], [&"move_left", -d.x], [&"move_down", d.y], [&"move_up", -d.y]]:
            var v: float = maxf(0.0, pair[1] / radius) * s
            if v > 0.0: Input.action_press(pair[0], v)
            else: Input.action_release(pair[0])
func _release() -> void:
    _touch_index = -1
    for a in [&"move_right", &"move_left", &"move_down", &"move_up"]: Input.action_release(a)
```

Tap-to-interact: `InteractButton.pressed` → `Input.action_press("interact", 1.0)` then release next frame. Distinguish from joystick drag via `InputEventScreenTouch.pressed == false` AND duration < 250ms AND drag distance < 16px.

HUD.gd: delete L201-226; instantiate `VirtualJoystick` in `_ready()` only when `is_mobile`; honor `apply_safe_area()` margins so knob clears the home indicator.

## Gate test strategy (structural, headless-safe)

Extend `tests/ui/test_touch_targets.gd`:
1. **Presence** — load `HUD.tscn`; assert `JoystickZone` + `InteractButton` exist with `custom_minimum_size.x/y >= 44`.
2. **Action-feed** — instantiate `VirtualJoystick`; `_gui_input(InputEventScreenDrag)` with `position = _origin + Vector2(80, 0)` → `Input.get_action_strength("move_right") >= 0.5` and `move_left == 0.0`.
3. **Tap-to-interact** — emit `pressed` on `InteractButton` → `Input.is_action_just_pressed("interact") == true` within one frame; `get_action_strength("interact") == 0.0` after release.
4. **Deadzone** — drag 8px from origin → all four `move_*` strengths == 0.0.
5. **Single-touch isolation** — second finger on `InteractButton` while joystick active does not steal `_touch_index`.

## Acceptance
- `git diff scenes/entities/Player.gd` empty in CI. Headless gate green: 5/5 cases. Manual iPhone 12 smoke: joystick moves player; InteractButton tap yields `show_dialogue` from `Player._try_grid_interact`. New textures <50KB → no TASK-031 regression.