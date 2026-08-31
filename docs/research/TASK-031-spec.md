# TASK-031 — Mobile performance budget: draw-call audit + GPUParticles2D caps

**Status:** `proposed` | **Priority:** high | **Category:** perf | **Owner:** tech-art-lead
**Renderer:** `gl_compatibility` (Godot 4.7, iOS target, A14+ floor)
**Files audited:** `scenes/core/WorldRender.gd`, `project.godot`, `ART_STYLE_GUIDE.md`
**Cozy/zero-combat guardrail:** caps must not strip ambient pillars (Monsoon rain, cooking smoke, lotus pollen).

## Draw-call baseline (audit of `WorldRender.gd`)

| Node | Count | Draws | Notes |
|------|-------|-------|-------|
| `Backdrop` (Polygon2D) | 1 | 1 | z=-30, one big quad |
| `GroundLayer` (TileMapLayer) | 1 | 1 (batched) | 320 cells, internal batching |
| `WaterOverlay` (TileMapLayer) | 1 | 1 (batched) | 9 maze + 1 dock cells |
| `BambooRing` (76 × Sprite2D) | 76 | **76** | dominant offender — not batched |
| `FLAT_DECOR` (Sprite2D) | 2 | 2 | bamboo thicket accents |
| `PROPS` (Sprite2D, y-sorted) | 23 | 23 | walls/caps/trees/stove |
| Player + MonkNPC | 2 | 2 | |
| **Total idle** | | **~106** | target ≤ 120 |

## Measurable budget (60 fps on A14+, 16.67 ms frame)

- **Draw calls / frame:** ≤ 120 idle, ≤ 200 peak (festival lanterns + rain).
- **Particles / system:** ≤ 200 on `GPUParticles2D` (compatibility renderer).
- **Active systems on-screen:** ≤ 3 (`rain`, `cooking_smoke`, `lotus_pollen` / `lanterns`).
- **Texture memory:** env ≤ 12 MB · UI ≤ 4 MB · font ≤ 2 MB · particles ≤ 1 MB · **total ≤ 20 MB** (ASTC 6×6, power-of-two).
- **Frame time:** P95 ≤ 12 ms on iPhone 12; ≤ 8 ms on iPhone 13+.
- **No per-pixel `for` loops** in any new shader (canvas_item only).
- **Y-sort cost:** keep y-sorted children ≤ 32 (current 25 incl. crops).
- **Texture filter:** POINT (already set in `project.godot`).

## Plan — minimal changes to hit budget

1. **Bake `BambooRing` to one sprite (76 → 1 draw).** In `_build_bamboo_ring()`, render 76 sub-sprites into a single `ImageTexture` once, then create one `Sprite2D`. Keeps art identical, drops 75 draws. Strict-typed builder:
   ```gdscript
   func _build_bamboo_ring(main: Node) -> void:
       var src: Texture2D = load("res://assets/environment/bamboo_wall_tall.png")
       var ring := Sprite2D.new()
       ring.name = "BambooRing"
       ring.z_index = -5
       ring.texture = _bake_bamboo_ring(src)
       main.add_child(ring)
   ```
   Re-bake on `texture_size_changed`; expose `ring_count()` returning `76` for test parity.
2. **Atlas-pack `PROPS`** (23 → 1) via a `MultiMeshInstance2D`-free atlas `Sprite2D` per kind OR keep as-is (within budget). Pick: keep individual sprites; flag revisit only if peak > 180.
3. **GPUParticles2D caps** — define `res://assets/particles/` materials with hard `amount` ceilings; gate in `ParticleCaps.gd` autoload.
4. **Disable `texture_filter` LINEAR** on any new sprite import (POINT only).
5. **Probe + log** draw call + frame time in `Main._ready` debug overlay (gated `OS.is_debug_build()`).

## Acceptance

- `WorldRender.ring_count() == 76` (test parity), but `RenderingServer.get_rendering_info(RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME) <= 120` after `build()`.
- Perf gate `tests/perf/test_mobile_budget.gd` runs headless iPhone-12 preset and asserts: draws ≤ 120, P95 frame ≤ 12 ms, particle textures ≤ 1 MB.
- All existing TASK-007 / TASK-030 gates stay green (no behavior change).

## Risk

Low — bake step is build-time; visuals identical pixel-for-pixel. MultiMesh avoided (`gl_compatibility` 2D has limited per-instance uniforms); atlas-bake sidesteps it.
