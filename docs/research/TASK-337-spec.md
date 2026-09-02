# TASK-337 — Secondary unlockable area (Mountain Cave)

Sprint 2 of the "broaden to compete with HM:BtN" plan (2026-09-02).

## Scope note — read this before touching anything

This is deliberately NOT a new map, new tileset, or grid expansion.
`GridManager.grid_size` is `Vector2i(20, 16)` and load-bearing for a lot
of other code (bounds colliders, bamboo ring math, the Y-sort perf
budget which is already near its cap at 50) — touching it is a much
bigger, riskier task than this one. This task adds ONE new interactable
in an already-existing, currently-empty corner of the current map,
gated behind a progression milestone the player already earns
naturally (`mining_skill` reaching its cap). The "world getting
bigger" feeling comes from the gate, not from new terrain.

**No new item, no new recipe, no save-schema change.** Reuses
`data/ore/ore.json`'s existing 3 ores verbatim — the difference is
purely in rarity weighting (biased toward the rare ore instead of the
common one), framed as "a richer vein, harder to reach."

## Why no new persisted field

Adding an `is_unlocked` boolean to `GameData.gd` would need a
`SaveManager.gd` schema bump — an always-escalate category in this
project's pipeline (never auto-merged, always human-reviewed). Avoid it
entirely: the unlock condition (`GameData.mining_skill >= 3`) is
**already persisted** (it's an existing `GameData` field, saved/loaded
today). Derive the unlock state live from it every time instead of
storing a redundant flag — this also means a save from before this
task ships unlocks correctly the moment it's loaded, with zero
migration needed.

## Implementation

### 1. New file: `scripts/interactables/MountainCaveSpot.gd`

Mirror `scripts/interactables/MiningSpot.gd` almost exactly (read that
file in full first) — same `_build_interact_area()` programmatic
`Area2D` pattern, same `_load_roster()` loading `data/ore/ore.json`,
same `_player_in_range`/`_unhandled_input` shape. Differences from
`MiningSpot.gd`:

- `spot_name: String = "Mountain Cave"`.
- `_roll_ore()`'s rarity weights are inverted from `MiningSpot.gd`'s
  (common 4.0 / uncommon 2.5 / rare 1.2): use common 1.2 / uncommon 2.5
  / rare 4.0 instead, so the same 3 ores are still possible but silver
  (rare) is now the MOST likely result here instead of the least
  likely. This is the entire "richer vein" mechanic — no new items.
- Does NOT re-implement the `deep_miner` milestone check (`MiningSpot.gd`
  already owns that trigger at `mining_skill` reaching cap — don't
  duplicate it here, this spot's ore find is independent of that
  milestone).
- Dialogue flavor should acknowledge this is a harder, further-flung
  spot ("the cave mouth past the ridge," or similar — your call on
  exact wording, keep it consistent with the game's established cozy
  Thai-countryside voice, see other interactables' dialogue for tone
  reference).

### 2. Wiring in `scenes/core/Main.gd`

Add a lazy unlock check. `Main.gd` currently has NO `minute_ticked`
subscription of its own (verified — every other system owns its own
subscription). Add one:

```gdscript
# in _ready(), alongside the other _ensure_* calls:
SignalBus.minute_ticked.connect(_on_minute_ticked_unlocks)

func _on_minute_ticked_unlocks(_day: int, _hour: int, _minute: int) -> void:
	_ensure_mountain_cave()

func _ensure_mountain_cave() -> void:
	if GameData.mining_skill < 3:
		return
	if get_node_or_null("MountainCaveSpot") != null:
		return
	var script: GDScript = load("res://scripts/interactables/MountainCaveSpot.gd")
	if script == null:
		return
	var spot: Node2D = script.new() as Node2D
	if spot == null:
		return
	spot.name = "MountainCaveSpot"
	spot.position = Vector2(19 * 48 + 24, 14 * 48 + 24) # SE corner, verified clear
	add_child(spot)
```

Also call `_ensure_mountain_cave()` once directly from `_ready()` itself
(not just from the tick handler) so a save loaded with `mining_skill`
already at 3+ gets the spot immediately on boot, without waiting for
the first `minute_ticked` tick.

Position `Vector2(19 * 48 + 24, 14 * 48 + 24)` was verified via a
headless `ground_at()` probe to be `ground_grass` (walkable) and clear
of every other node's position in `Main.tscn`/`Main.gd` — do not move
it without re-verifying against the current occupied-position list
(grep `position = Vector2\|pos.*Vector2` across `Main.gd`/`Main.tscn`
for the current list before picking anywhere else).

## Tests

New `tests/test_mountain_cave.gd` (SceneTree pattern, mirror
`tests/test_mining.gd`'s house style):
- With `GameData.mining_skill` at its default (1), `MountainCaveSpot`
  is NOT present under `Main` after boot.
- Setting `GameData.mining_skill = 3` and advancing one `minute_ticked`
  tick causes `MountainCaveSpot` to appear.
- A fresh boot with `GameData.mining_skill` already at 3 (simulating a
  loaded save) has `MountainCaveSpot` present immediately, without
  needing any tick.
- `MountainCaveSpot._area` is a real `Area2D` (not null) — this project
  has twice shipped the `@onready $InteractArea` null-bug; do not
  repeat it (build it programmatically like `MiningSpot.gd` does).
- Digging at the cave finds ore from the same 3-item roster as
  `MiningSpot` (same item_ids), confirming no new items were invented.
- Over many rolls (e.g. 200), the rare ore (silver) comes up
  meaningfully more often at the cave than at the regular `MiningSpot`
  — a statistical check with a generous threshold (e.g. silver rate at
  the cave > silver rate at MiningSpot, not an exact ratio) is fine;
  don't chase a brittle exact-percentage assertion against RNG.

## Constraints

- Do not touch `GridManager.gd`, `WorldRender.gd`, or `grid_size`.
- Do not add any new item to `data/ore/ore.json`, any new
  `GameData` field, or touch `SaveManager.gd`/`test_save_compat.gd`.
- Do not duplicate the `deep_miner` milestone logic from `MiningSpot.gd`.
- Run `bash scripts/ci/run_gate.sh all` before considering this done;
  must stay green (perf-budget's Y-sort check in particular — verify
  `MountainCaveSpot` needs the same no-sprite exclusion-list treatment
  as `MiningSpot`/`Noticeboard` if it has no visible sprite, or budget
  math if it does; check before assuming either way).
- No git/gh actions — stop after code + tests are written and the gate
  is green. Do not commit, push, open a PR, or merge.
