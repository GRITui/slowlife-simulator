# TASK-321 — Mining/ore resource loop (MVP scope)

**Status:** `todo` | **Priority:** high | **Category:** gameplay/economy | **Owner:** OpenCode (entire task — no new `.tscn` needed, see Design)
**Files:** `scripts/interactables/MiningSpot.gd` (new), `data/ore/ore.json` (new), `scripts/autoload/GameData.gd` (mining_skill + upgrade_tool ore requirement), `scenes/core/Main.gd` (dynamic instancing), `tests/test_mining.gd` (new), `tests/test_tool_tiers.gd` (fix — see Acceptance Criteria)

## Scope note — deliberately smaller than Gemini's original suggestion
The original gap analysis (Run 1) described mining as "multi-floor mines
requiring ladder digging... seasonal access." That's a genuinely different
scale of feature (procedural floor generation, a new traversal system) —
building it would be the single largest new subsystem in this repo and
carries real scope-creep risk (this is exactly the category flagged
highest-risk in the original sequencing note).

Redesign, made under the project's Designer tier: **mirror
`FishingSpot.gd`'s existing pattern exactly** — a single interactable,
rarity-weighted roll against a JSON roster, skill gating that grows with
use, stamina-gated instead of tool-gated (fishing needs a rod; mining is
always accessible once found, cozier and simpler). This delivers the
actual gap ("a resource + tool-upgrade-material loop") without floor
generation. Floor/multi-area mining stays a possible future task, not
blocking this one.

## Design
- `data/ore/ore.json`: roster of ore entries, simpler than `fish.json` (no
  nested size sub-roll — ore doesn't need it for MVP): `id`,
  `display_name`, `rarity` (`common`/`uncommon`/`rare`), `item_id`,
  `harmony_value`, `skill_required` (1-3, gates rarer ore behind
  `mining_skill`). Three entries: `copper_ore` (common, skill 1),
  `iron_ore` (uncommon, skill 2), `silver_ore` (rare, skill 3).
- `GameData.gd`: add `var mining_skill: int = 1` mirroring `fishing_skill`
  exactly (same growth pattern will live in `MiningSpot.gd`, mirroring
  `FishingSpot.gd`'s `fishing_rolls`/level-up block). Also extend
  `upgrade_tool()` (search for `func upgrade_tool`) to require ore in
  addition to the existing rice_grain cost — this is the actual
  "tool-upgrade-material sink" the gap called for: tier 1→2 additionally
  requires 2x `copper_ore`, tier 2→3 additionally requires 2x `iron_ore`.
  Keep the existing rice_grain cost unchanged, ore is additive.
- `MiningSpot.gd`: mirrors `FishingSpot.gd`'s structure and contract
  closely (proximity, roster loading, weighted roll by rarity using the
  same weight scheme: common 4.0/uncommon 2.5/rare 1.2), but:
  - No tool requirement (fishing needs a rod; mining doesn't need
    anything held — always accessible once you find the spot).
  - Gated by stamina instead: `dig_cost_stamina: float = 8.0` per attempt,
    soft-fail dialogue if insufficient (no hard fail state).
  - Skill gating and growth mirrors `fishing_skill` exactly: eligible ore
    filtered by `skill_required <= mining_skill`, `mining_skill` grows by
    1 every 5 successful digs, capped at tier 3 (matches the 3-entry
    roster, not fishing's 4).
  - Success: `GameData.add_item(item_id, 1)`, `GameData.add_harmony(...)`,
    `GameData.current_stamina -= dig_cost_stamina`, dialogue announcing
    the find. Reuse `SignalBus.craft_completed.emit(item, 1)` for the
    item-gained signal exactly as `FishingSpot.gd` does (no new signal).
- **No new `.tscn`.** `FishingSpot` has none either — it's built entirely
  in code and instanced dynamically via `Main.gd::_ensure_fishing_spot()`
  (search for that function to see the exact pattern: `script.new()`,
  set `.name`/`.position`, `add_child()`). Mirror this with
  `_ensure_mining_spot()`, called alongside the other `_ensure_*` calls
  in `Main.gd`. Position: pick an open spot not already used by another
  entity (check existing `position =` values across `Main.tscn` and the
  other `_ensure_*` functions first) — no visual sprite needed for MVP,
  matching `FishingSpot`'s own precedent (an invisible interact zone, not
  a placed sprite).
  - **Fix a latent gap while mirroring this**, don't copy it forward:
    `FishingSpot.gd` references `$InteractArea` via
    `@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null`,
    but nothing ever adds an `InteractArea` child (no `.tscn`, and
    `_ensure_fishing_spot()` doesn't add one either) — so `_area` is
    always `null` and proximity-based interaction never actually works
    in real play for fishing today (its test only calls `cast_line()`
    directly, bypassing this entirely). For `MiningSpot.gd`, build a real
    `Area2D` + `CollisionShape2D` (a `CircleShape2D`, radius ~56 to match
    this repo's other interact zones like `SluiceGate`/`CarpenterUpgrade`)
    programmatically in `_ready()` so proximity detection actually works.
    Do not touch `FishingSpot.gd` itself — that's a separate, pre-existing
    issue, out of scope for this task.

## Acceptance Criteria
- `MiningSpot` node present as a runtime child of `Main` after `_ready()`
  (dynamically added, mirroring `FishingSpot` — not authored in `Main.tscn`
  itself).
- Digging without enough stamina soft-fails, no item granted, no stamina
  change.
- Digging with enough stamina grants an eligible ore item, deducts
  `current_stamina` by exactly `dig_cost_stamina`, and adds harmony.
- `mining_skill` starts at 1, grows by 1 every 5 successful digs, caps at 3.
- Ore with `skill_required` above current `mining_skill` never appears in
  the roll pool.
- `GameData.upgrade_tool()` now also requires the correct ore type/amount
  per tier in addition to the existing rice_grain cost; without enough
  ore, upgrade fails even with enough rice_grain (and vice versa).
- `run_tests.gd` / `run_engine_tests.gd` stay green — in particular
  `tests/test_tool_tiers.gd`, which already exercises `upgrade_tool()`
  and will need its ore prerequisites accounted for.
