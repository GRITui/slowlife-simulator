# TASK-024 — WorldRender Performance Cache + Prop Pooling (Engine)

**Status:** `todo` | **Priority:** medium | **Category:** performance | **Owner:** spatial-architect
**Files:** `scenes/core/WorldRender.gd`, `scenes/core/Main.tscn`, `scripts/core/ProfilerOverlay.gd`

## Performance Risks (@qa-auditor)
- `WorldRender.gd:22` `build(main: Node2D)` reconstructs bamboo ring 76 walls + 15+ props + 4 bounds + Backdrop on every `Main._ready:14` `wr.build(self)` with no caching; on mobile 900px viewport re-entry (scene reload) causes GC churn.
- `WorldRender.ring_count() == 76` verified in `tests/run_tests.gd:100` but no reuse — each reload `add_child` without `queue_free` of prior ring if `Main` re-instanced.
- `ProfilerOverlay.gd:13` `_process` allocates `label.text` string every frame (`"FPS:%d MEM:%.1fMB" % [...]`) — minor but 60fps alloc.
- Draw calls: `TileMapLayer` ground `z=-20` + water overlay `z=-14` + bamboo `z=-5` + props under `Main y_sort` — Y-sort sorts all `Main` children (Player/MonkNPC/VillagerNPC/Buffalo) every frame (O(n log n) 20+ nodes).

## Refactoring Plan
- `WorldRender.gd`: add `var _cached_ring: Node2D` and `var _cached_bounds: Node`, reuse if `main.get_node_or_null("BambooRing")` exists; add `func clear()` for `Main` exit; use `call_deferred` for prop adds to avoid physics thrash.
- Prop pooling: pre-instance `bamboo_wall_tall.png` 76 sprites into `PackedScene` sub-scene, instance via `preload`, not `load` per tile.
- `ProfilerOverlay.gd`: cache string formatting, update label every 0.5s (`_accum += delta; if _accum > 0.5: update`) instead of per-frame.
- Y-sort: keep `Main y_sort_enabled true` but move static `WorldRender` ground layers to non-YSort parent (`WorldStatic` `y_sort_enabled false`) and only dynamic actors under YSort — reduces sort count from ~25 to ~8. Add `WorldRender.get_y_sort_count() -> int` for test.

## Acceptance
- No visual change, same `ground_at` matrix (`paddy`, `canal`, `deep_pond`, `temple`), same 76 walls, same Backdrop `#1565C0`.
- `godot --headless` import + tests still 54/54 + 50/50; `ProfilerOverlay` F3 toggle unchanged.
- `gdlint` clean; memory stable on scene reload (profiler mem delta <5MB).
