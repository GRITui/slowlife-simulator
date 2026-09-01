# TASK-036 — Wire existing NPC/animal walk-cycle art into live scenes

**Status:** `proposed` | **Priority:** high | **Category:** art | **Owner:** art-po
**Sprint:** 1 of 10 (Head-of-Art roadmap, 2026-09-01)

## Findings

Full walk-cycle frame sets already exist under `assets/characters/` (elder, child, handler, priest NPCs; buffalo) — 4-frame walk + idle each, from the Claude Design redesign pass. None are wired: `MonkNPC.tscn` and `Buffalo.tscn` each use a single static `Sprite2D`, no `AnimatedSprite2D`/`SpriteFrames`. No engine dependency — this is pure `.tscn` art-layer work.

## Plan

1. Replace the static `Sprite2D` in `MonkNPC.tscn` with `AnimatedSprite2D` + a `SpriteFrames` resource: `idle` (single frame) and `walk` (4-frame, `npc_priest_walk_01-04.png`), 8fps.
2. Check `scenes/entities/` for the villager/elder/child/handler NPC scene(s) consuming `npc_elder_*`, `npc_child_*`, `npc_handler_*` frame sets and apply the same pattern (verify actual scene filenames before editing — may be a shared `VillagerNPC.tscn` template).
3. `Buffalo.tscn`: same pattern using `animal_buffalo_01-04.png` (grazing cycle) + `animal_buffalo_idle.png`. Scene stays uninstantiated in `Main.tscn` per current dead-scene status (see `PO_INBOX.md` #1) — this task only prepares the art, doesn't wire the scene into `Main`.
4. Drive `idle`/`walk` state from each NPC's existing movement logic if a bool/velocity check is already exposed (read-only check, no new GDScript signals needed); otherwise default to `walk` looping (acceptable placeholder, no logic edit required).

## Acceptance

- All four NPC types + buffalo animate through their existing frame sets in-editor.
- No new textures needed — 100% reuse of already-shipped assets.
- `godot --headless` gates stay green; no `.gd` logic files touched beyond reading existing exported state.

## Risk

Very low — pure `.tscn` changes, assets already exist and are already imported.
