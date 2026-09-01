# TASK-041 — Debug-build perf probe: live draw-call + frame-time overlay

**Status:** `proposed` | **Priority:** high | **Category:** perf | **Owner:** @engine-inspector
**Renderer:** `gl_compatibility` (Godot 4.7, iOS A14+, Metal). Budget source: TASK-031 (draws ≤ 120 idle, ≤ 200 peak; texture mem ≤ 20 MB).
**Files (edit):** `scripts/core/ProfilerOverlay.gd` (extend), `scenes/core/Main.gd` (programmatic attach)
**Files (new):** `tests/perf/test_profiler_overlay.gd` (gate)
**Constraints:** strict-typed, debug-only runtime, headless-safe, zero-combat, ≤ 60 LOC cap on the script.

## Context (TASK-031 item 5, currently unimplemented)

`ProfilerOverlay.gd` ships 22 lines and only renders `FPS:%d MEM:%.1fMB` from `OS.get_static_memory_usage()` (heap, not VRAM — wrong source for TASK-031's 20 MB texture budget). The script already handles `--profiler` cmdline + F3 toggle + 0.5 s label throttle; this task adds the **draw-call** + **texture-VRAM** lines that the perf budget actually tracks, wires the overlay into `Main.tscn` programmatically, and locks behavior with a headless gate.

## Spec

### 1. `scripts/core/ProfilerOverlay.gd` (rewrite, strict-typed, ≤ 60 LOC)

```gdscript
extends CanvasLayer
# TASK-041 — debug-only live perf probe (draw calls / texture mem / FPS).
# Activated by --profiler cmdline OR F3 toggle; no-op in release builds.

const REFRESH_INTERVAL: float = 0.5
const ENABLED_BY_DEFAULT: bool = false

var enabled: bool = ENABLED_BY_DEFAULT
var _accum: float = 0.0
@onready var _label: Label = $Label if has_node("Label") else null

func _ready() -> void:
	if not OS.is_debug_build():
		visible = false
		set_process(false)
		return
	enabled = ENABLED_BY_DEFAULT or "--profiler" in OS.get_cmdline_user_args()
	visible = enabled

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		enabled = not enabled
		visible = enabled

func _process(_delta: float) -> void:
	if not enabled or _label == null:
		return
	_accum += _delta
	if _accum < REFRESH_INTERVAL:
		return
	_accum = 0.0
	var draws: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var tex_mb: float = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED) / 1048576.0
	_label.text = "FPS:%d DRAW:%d TEX:%.1fMB" % [Engine.get_frames_per_second(), draws, tex_mb]
```

Notes: `set_process(false)` keeps release builds truly zero-cost (the previous version still ran `_process` each frame and returned at line 21). `RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED` is the canonical VRAM source — already used by `scripts/core/MemoryBudget.gd:L11`. Draw-call source matches `tests/perf/test_mobile_budget.gd:L46`.

### 2. Programmatic attach in `Main.gd`

Append one line to `_ready()` after the existing `_ensure_*()` calls:

```gdscript
# TASK-041: debug perf probe (no-op in release via OS.is_debug_build() guard).
_ensure_profiler_overlay()
```

```gdscript
func _ensure_profiler_overlay() -> void:
	if get_node_or_null("ProfilerOverlay") != null:
		return
	var overlay: CanvasLayer = load("res://scripts/core/ProfilerOverlay.gd").new()
	overlay.name = "ProfilerOverlay"
	add_child(overlay)
```

**Why programmatic:** avoids editing `Main.tscn` (art lane owns it during TASK-101/102/103 sprints — same pattern as `Main._ensure_buffalo()` / `_ensure_game_flow()` / `_ensure_festival()`). Release builds self-disable inside `_ready()`.

### 3. `Main.gd` helper (final)

```gdscript
func _ensure_profiler_overlay() -> void:
	if get_node_or_null("ProfilerOverlay") != null:
		return
	var overlay: CanvasLayer = load("res://scripts/core/ProfilerOverlay.gd").new()
	overlay.name = "ProfilerOverlay"
	overlay.layer = 100  # above DialogueLayer(10) / TintLayer(5)
	var label: Label = Label.new()
	label.name = "Label"
	label.position = Vector2(8, 8)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	overlay.add_child(label)
	add_child(overlay)
```

`Main.tscn` is **not** modified — same conflict-free pattern as `Main._ensure_buffalo()` / `_ensure_game_flow()` / `_ensure_festival()` (TASK-038/039/040).

## Gate test strategy (`tests/perf/test_profiler_overlay.gd`)

Headless-safe; mirrors `test_mobile_budget.gd` pattern:

1. **Release no-op** — instantiate the script with `OS.is_debug_build()` mocked false (or skip: gate runs in editor/debug). Assert `visible == false` and `set_process(false)` after `_ready()`. *If the runner is always debug, instead assert `_process()` early-returns when `enabled = false`.*
2. **Cmdline activation** — `OS.set_cmdline_user_args(["--profiler"])`, instantiate, await one frame, assert `enabled == true` and `visible == true`.
3. **F3 toggle** — synthesize `InputEventKey` with `keycode = KEY_F3, pressed = true`, dispatch via `Input.parse_input_event()`, await one frame, assert `enabled` flipped.
4. **Label format** — manually set `enabled = true` + `visible = true`, force `_accum = REFRESH_INTERVAL`, await one `_process` tick; assert `_label.text.begins_with("FPS:")` AND `contains("DRAW:")` AND `contains("TEX:")` AND ends with `"MB"`.
5. **Refresh throttle** — assert `_process` called twice in < `REFRESH_INTERVAL` does not mutate `_label.text` (label keeps prior value).
6. **Render-source parity** — `_label.text` contains a draw-call integer matching `RenderingServer.get_rendering_info(RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)` at the same frame.
7. **No combat leak** — grep guard: no method named `attack` / `damage` / `combat` in the file.
8. **LOC cap** — `wc -l scripts/core/ProfilerOverlay.gd` ≤ 60 (add to `run_sprint.sh` lint or inline).

Run: `godot --headless --path . --script res://tests/perf/test_profiler_overlay.gd`.

## Acceptance

- `ProfilerOverlay.gd` ≤ 60 LOC, all `var` / `func` typed.
- Release build (`OS.is_debug_build() == false`): `visible == false`, `set_process(false)` → zero per-frame cost.
- Debug build: `--profiler` flag OR F3 toggles overlay; label shows `FPS:%d DRAW:%d TEX:%.1fMB` updated at 2 Hz.
- `Main.tscn` untouched; `Main.gd` gains 1 call + 1 small helper (≤ 15 LOC).
- Gate green 8/8 headless; existing TASK-031 + TASK-037 gates stay green.
- Manual iPhone 12 smoke: overlay visible during festival lanterns + monsoon rain, draw count climbs (≤ 200 peak per TASK-031), texture mem stays ≤ 20 MB.

## Risk

Low — additive overlay, release-guarded, programmatic attach avoids `.tscn` churn. One subtle: `RenderingServer.get_rendering_info` returns 0 under the dummy renderer (headless) — gate is structural, on-device values are real.