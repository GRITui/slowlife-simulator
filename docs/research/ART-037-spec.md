# TASK-037 — Player action animations (hoe/plant, harvest, carrying-crop)

**Status:** `proposed` | **Priority:** high | **Category:** art | **Owner:** art-po
**Sprint:** 2 of 10 (Head-of-Art roadmap, 2026-09-01)

## Findings

`ART_STYLE_GUIDE.md`'s character spec calls for Hoe/plant (4f), Harvest (4f), and a carrying-crop variant. `Player.tscn` currently ships only `idle` + 4-directional `walk`. Unlike TASK-036, this frame art does **not** already exist — new sprite sheets need authoring.

## Plan

1. Author `player_hoe_01-04.png`, `player_harvest_01-04.png` (48x72 canon, matching existing `Player` frame dimensions and Ink Outline/Skin-Wood-Warm palette anchors from `ART_STYLE_GUIDE.md`).
2. Author a `carrying` idle/walk modulate variant (crop-in-hand overlay) — reuse existing walk frames with a small held-item sprite layered on, not a full new sheet, to keep texture budget down.
3. Wire into `Player.tscn`'s `SpriteFrames` as new animation tracks: `hoe`, `harvest`, `walk_carrying`.
4. Document trigger interface in this spec for `@po`: Player's interact/harvest action would need to call `AnimatedSprite2D.play("hoe"|"harvest")` at the right moment — that's a one-line GDScript hook in the existing interact handler, left to `@po`/gameplay to wire since it touches `Player.gd` (outside Strict Guardrails). Animation asset ships regardless; hookup is optional follow-up.

## Acceptance

- Three new animation tracks exist and preview correctly in the Godot editor.
- Frame count/size/palette consistent with `ART_STYLE_GUIDE.md`'s existing Player spec.
- No `Player.gd` logic edited by this task — only `.tscn`/`SpriteFrames`/new PNGs.

## Risk

Low — additive frames, existing animations untouched. Main cost is new-art authoring time, not integration risk.
