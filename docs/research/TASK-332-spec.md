# TASK-332 — Repeatable side-quest noticeboard

Sprint 2 of the "3 sprints, complete pending backlog" run (2026-09-02).

## Scope note (read before implementing)

Confirmed via code audit: no repeatable/cycling quest source exists
anywhere — `QuestLog.gd`'s 22-objective chain is entirely one-shot. This
adds a SEPARATE, standalone repeatable-request system. **Do not touch
`QuestLog.gd`, `GameData.active_quests`, or any of the 22-objective
chain content** — this is deliberately independent, not integrated with
the main quest chain.

**V1 explicitly does NOT persist across save/load** (state resets on a
fresh session). Save-format changes are an always-escalate category in
this project's pipeline (never auto-merged, always human-reviewed) —
adding a new persisted field is out of scope for this task. Note this
limitation in a code comment; do not attempt to add it to
`SaveManager.gd`.

## Data

`data/noticeboard/notices.json` already created (6 request templates —
item_id/qty/reward_silver/reward_harmony/flavor_npc/line). Do not modify
its shape; read it as-is.

## New file: `scripts/interactables/Noticeboard.gd`

Follow `scripts/interactables/MiningSpot.gd`'s exact structural pattern
(read that file first) — `extends Node2D`, builds a real `Area2D` +
`CircleShape2D` proximity trigger programmatically in `_ready()` (radius
56.0, matching `SluiceGate`/`CarpenterUpgrade`/`MiningSpot`), tracks
`_player_in_range` via `_on_body_entered`/`_on_body_exited`, responds to
`interact` action in `_unhandled_input()`. This class owns both the
interactable AND the notice-rotation logic (self-contained, matching
how `FishingSpot`/`MiningSpot` each own their own roster).

Behavior:
- Load `data/noticeboard/notices.json` in `_ready()` (same
  `FileAccess.open` + `JSON.parse_string` pattern as `MiningSpot._load_roster()`
  / `FishingSpot._load_roster()`).
- `var _active_notice: Dictionary = {}` and `var _last_rotate_day: int = -1`.
- On `_ready()`, pick a random notice from the roster as the initial
  active one.
- Rotation: every 7 in-game days (check via `SignalBus.time_manager.day`
  if available, else a local day counter), pick a new random notice
  DIFFERENT from the current one if the roster has more than 1 entry.
  Wire this check into `_unhandled_input()` before showing the prompt
  (lazy rotation is fine — no need for a `minute_ticked` subscription).
- Interact behavior (`_try_fulfill()`):
  - If `_active_notice` is empty, soft-fail dialogue ("Nothing posted
    right now.").
  - If player lacks `GameData.has_item(item_id, qty)`, show the notice's
    `line` as a hint (do not fail silently — the point is discoverability).
  - If player has enough: `GameData.remove_item(item_id, qty)`,
    `GameData.add_silver(reward_silver)`, `GameData.add_harmony(reward_harmony)`,
    emit a confirmation dialogue line naming the flavor_npc and reward,
    THEN immediately rotate to a new random notice (different from the
    one just fulfilled, if possible) so the board is never empty.
  - Check-before-deduct: verify `has_item` BEFORE calling `remove_item`/
    `add_silver` — no speculative deduct+refund (see `CarpenterUpgrade.gd`'s
    header comment for why: it double-fires `SignalBus.silver_changed`
    on a soft fail).

## Wiring

Add `_ensure_noticeboard()` to `scenes/core/Main.gd`, following the
exact `_ensure_mining_spot()` pattern (`script.new()`, no `.tscn`,
`add_child`), called from `_ready()` alongside the other `_ensure_*`
calls. Placement: pick an unused position near the market/temple area
(check `WorldRender.gd` or existing NPC positions for what's already
occupied — do not overlap another interactable or NPC's position).

## Tests

New `tests/test_noticeboard.gd` (SceneTree pattern):
- `Noticeboard` node present under `Main` after boot.
- `_area` is a real `Area2D` (not null) — this project has twice shipped
  the `@onready $InteractArea` null-bug (`FishingSpot.gd`,
  `MiningSpot.gd`'s first draft); do not repeat it.
- Fulfilling with insufficient items: no inventory/silver/harmony
  mutation, hint dialogue shown.
- Fulfilling with sufficient items: item removed, silver/harmony
  granted exactly once, active notice changes to a different id
  afterward (when the roster has >1 entry).
- Proximity: entering/exiting the `InteractArea` sets/clears
  `_player_in_range` (mirror `tests/test_fishing.gd`'s proximity checks).

## Constraints

- No git/gh actions — stop after code + tests are written and the gate
  is green. Do not commit, push, open a PR, or merge.
- Run `bash scripts/ci/run_gate.sh all` before considering this done.
