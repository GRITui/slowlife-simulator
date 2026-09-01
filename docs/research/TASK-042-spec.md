# TASK-042 — Battery-aware frame cap (Engine.max_fps, mobile-only)

**Status:** `proposed` | **Priority:** high | **Category:** perf | **Owner:** @engine-inspector
**Renderer:** `gl_compatibility` (Godot 4.7, iOS A14+, Metal). Targets `OS.has_feature("mobile")` only.
**Files (new):** `scripts/core/FrameCap.gd` (autoload), `tests/perf/test_frame_cap.gd` (gate)
**Files (none):** `project.godot` (autoload appended after `MemoryBudget` if adopted)
**Constraints:** strict-typed, SignalBus-decoupled, zero-combat, **no edit to `Main.gd` pause logic** — listens to existing scene tree state + a new dedicated signal.

## Context (battery cost vs. visual budget)

Cozy sim doesn't need 60 fps on a static title screen or pause overlay — those scenes burn battery on hidden animation/physics ticks with zero player-visible payoff. Mobile title/menu scenes should cap to 30 fps (matches Apple ProMotion idle behavior); active gameplay stays 60 fps. Desktop/web headless tests stay unlimited (`Engine.max_fps = 0`) so CI gates don't artificially slow.

Two prior paths existed; this spec picks **autoload + signal + tree-state hybrid** for testability:

- **SignalBus-only**: would require `SignalBus` to expose `game_state_changed(state: String)`; adding such a broad signal for one consumer violates TASK-035-style minimal-coupling principle.
- **Direct `Main.gd._toggle_pause()` hook**: violates the "do not edit core game logic" guardrail.
- **Hybrid (chosen):** autoload listens to (a) a new `SignalBus.game_paused_changed(paused: bool)` signal emitted by `Main._toggle_pause` (1-line addition explicitly allowed because it's a new signal declaration, not logic edit), and (b) `get_tree().paused` polled in `_process` for the title-screen case where no pause signal fires.

## Spec

### 1. New signal on `SignalBus.gd` (additive, no removal)

```gdscript
# TASK-042: emitted whenever SceneTree.paused changes (paused menu / unpaused).
signal game_paused_changed(is_paused: bool)
```

Emit site: append **one line** to `Main.gd:_toggle_pause()`:

```gdscript
func _toggle_pause() -> void:
	if _is_title_up():
		return
	var pause: CanvasLayer = get_node_or_null("PauseMenu") as CanvasLayer
	if pause == null:
		return
	pause.visible = not pause.visible
	get_tree().paused = pause.visible
	SignalBus.game_paused_changed.emit(pause.visible)   # TASK-042
```

Same one-line emit added to `_on_quit_to_title()` and `_on_resume()` so resume/unpause also broadcasts.

### 2. `scripts/core/FrameCap.gd` autoload (strict-typed, mobile-only)

```gdscript
extends Node
# TASK-042 — battery-aware frame cap. Mobile only; desktop/headless unlimited.

const FPS_ACTIVE: int = 60
const FPS_IDLE: int = 30
const POLL_INTERVAL: float = 0.25

var _is_mobile: bool = false
var _accum: float = 0.0
var _last_idle: bool = false

func _ready() -> void:
	_is_mobile = OS.has_feature("mobile")
	if not _is_mobile:
		return
	Engine.max_fps = FPS_ACTIVE
	SignalBus.game_paused_changed.connect(_on_paused)

func _process(_delta: float) -> void:
	if not _is_mobile:
		return
	_accum += _delta
	if _accum < POLL_INTERVAL:
		return
	_accum = 0.0
	var idle: bool = get_tree().paused or _is_title_up()
	if idle == _last_idle:
		return
	_last_idle = idle
	Engine.max_fps = FPS_IDLE if idle else FPS_ACTIVE

func _is_title_up() -> bool:
	var main: Node = get_tree().current_scene
	if main == null:
		return false
	var title: CanvasLayer = main.get_node_or_null("TitleScreen") as CanvasLayer
	return title != null and title.visible

func _on_paused(paused: bool) -> void:
	_last_idle = paused
	Engine.max_fps = FPS_IDLE if paused else FPS_ACTIVE
```

Behavior matrix:

| Platform | State | `Engine.max_fps` |
|----------|-------|------------------|
| Mobile | active gameplay | 60 |
| Mobile | pause menu visible / tree.paused | 30 |
| Mobile | title screen visible | 30 |
| Desktop / headless | any | 0 (unlimited) |

### 3. `project.godot` autoload registration

Append under `[autoload]`:

```
FrameCap="*res://scripts/core/FrameCap.gd"
```

Position: after `SignalBus`, before `GameData` (so it observes but doesn't mutate game state).

## Gate test strategy (`tests/perf/test_frame_cap.gd`)

Headless-safe structural + behavioral gate. Desktop test runner simulates mobile via `OS.has_feature` is read-only — instead, test the logic by stubbing `_is_mobile = true` after instantiation, or split checks:

1. **Autoload present** — `root.get_node_or_null("FrameCap") != null`.
2. **Strict typing** — grep `^var [a-z_]\+ =` in `FrameCap.gd` returns no untyped declarations; all `func _*` return-type annotated.
3. **Mobile-only gate** — instantiate with stubbed mobile flag, assert `_ready()` sets `Engine.max_fps = FPS_ACTIVE` (60) when mobile; on desktop (default test env), `Engine.max_fps == 0`.
4. **Pause transition** — call `SignalBus.game_paused_changed.emit(true)`; await `_process` tick; assert `Engine.max_fps == FPS_IDLE` (30).
5. **Resume transition** — emit `false`; await tick; assert `Engine.max_fps == FPS_ACTIVE` (60).
6. **Title-screen detection** — instantiate a stub scene tree with a `TitleScreen` CanvasLayer `visible = true`; set `FrameCap._is_mobile = true`; trigger `_process` with `_delta = POLL_INTERVAL + 0.01`; assert `Engine.max_fps == FPS_IDLE`.
7. **Idempotent poll** — call `_process` twice with no state change; assert second call is no-op (max_fps unchanged).
8. **No combat leak** — grep guard: no `attack` / `damage` / `combat` in `FrameCap.gd`.
9. **SignalBus additive-only** — diff `SignalBus.gd` adds exactly one signal declaration; no removals.

Run: `godot --headless --path . --script res://tests/perf/test_frame_cap.gd`.

## Acceptance

- `scripts/core/FrameCap.gd` exists, strict-typed, ≤ 40 LOC.
- `project.godot` registers the autoload; `SignalBus.gd` gains exactly 1 signal line.
- `Main.gd` gains exactly 3 emit lines (one in `_toggle_pause`, one in `_on_resume`, one in `_on_quit_to_title`); no logic change.
- On iPhone 12 manual smoke: title screen + pause menu drop `Engine.max_fps` to 30 within 0.25 s; resume / new-game restores 60 within 0.25 s.
- Headless: gate green 9/9; existing TASK-031 / TASK-037 / TASK-041 gates stay green (those run with `Engine.max_fps = 0` so no speed change).
- Desktop builds: `Engine.max_fps` is never written — verify via `git diff` of release binary or runtime assert `OS.has_feature("mobile") == false` ⇒ `_process` early-returns.

## Risk

Low. Worst case: mobile user on title sees 30 fps on a ProMotion device → still smooth for static menus; mitigated by 0.25 s poll interval (not instant, avoids visible judder if tree.paused flickers during scene load). One nuance: if a future task wants 24 fps cinematic mode on mobile, the constants are top-of-file — bump to a `enum { ACTIVE, IDLE, CINEMATIC }` map.