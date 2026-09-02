# TASK-346 — 10-level system core + romance retrofit

**Execute this BEFORE TASK-341** (despite the lower task number — 341
was numbered when the plan still used 4 tiers; building the level
system first means the 3 new candidates in 341 get authored directly
in the final 10-level format instead of being written once and
rewritten later).

## Core: a shared `level()` function, no schema change

Affinity/bond values stay stored exactly as they are today — plain
0-100 ints in `GameData.affinity`/`buffalo_affinity`/`chicken_affinity`/
`companion_bond`. No new persisted field, no `SaveManager.gd` change.
Add one new pure function to `GameData.gd`:

```gdscript
## TASK-346: uniform 10-level scale used across every affinity-like value
## in the game (romance, buffalo, chicken, companion, and — TASK-349 —
## villagers). Replaces the previous inconsistent granularities
## (buffalo/chicken/companion used /25.0 = 0-4 "hearts"; romance used
## hard 25/60/90 thresholds = ~4 tiers) with one shared 0-10 scale.
static func level_for(value: int) -> int:
	return clampi(value / 10, 0, 10)
```

## Romance dialogue: retrofit `DIALOGUE`'s shape for Niran/Fah/Ploy

Current shape per candidate (read `scripts/narrative/DialogueDB.gd`'s
`"niran"`/`"fah"`/`"ploy"` entries in full first):
```gdscript
"niran": {
	"stranger": [...], "friendly": [...], "close": [...],
	"rival": [...], "romantic": [...],
},
```
New shape — string-keyed `"1"` through `"10"` (keep keys as strings,
not ints, so `get_line()`'s existing `String season` parameter doesn't
need retyping), plus the existing `"rival"` key unchanged in kind:
```gdscript
"niran": {
	"1": [...], "2": [...], "3": [...], "4": [...], "5": [...],
	"6": [...], "7": [...], "8": [...], "9": [...], "10": [...],
	"rival": [...], # unchanged — still the every-5th-talk flavor override
},
```
2 lines per level minimum (20 lines total per candidate for the base
structure), same voice-per-character established already. **Do not
discard the existing 8 lines (2 per old tier)** — redistribute them as
the anchor lines for their nearest new level and write new lines to
fill the gaps, preserving narrative continuity for players with
existing affinity progress:
- old `"stranger"` (affinity 0-24) → levels 1-2
- old `"friendly"` (25-59) → levels 3-5
- old `"close"` (60-89) → levels 6-8
- old `"romantic"` (90-100) → levels 9-10

Each level's 2 lines should read as a small, natural step up from the
previous level, not a repeat — the whole point of 10 levels is more
granular emotional progression, not just more lines.

## `scenes/entities/RomanceNPC.gd` — dialogue selection

Read the current `_talk()` in full. Replace:
```gdscript
var tier: String = DialogueDBScript.get_affinity_tier(GameData.get_affinity(npc_id))
if tier == "close" and not (GameData.married and GameData.spouse == npc_id) and _talk_count % 5 == 4:
	tier = "rival"
var line: String = DialogueDBScript.get_line(npc_id, tier, _talk_count)
```
with:
```gdscript
var level: int = GameData.level_for(GameData.get_affinity(npc_id))
var pool_key: String = str(level)
# TASK-324/346: rival flavor override — same trigger condition as before
# (the "close"-equivalent band, levels 6-8, matches the old 60-89 range
# exactly under floor(affinity/10)), just re-expressed in levels.
if level >= 6 and level <= 8 and not (GameData.married and GameData.spouse == npc_id) and _talk_count % 5 == 4:
	pool_key = "rival"
var line: String = DialogueDBScript.get_line(npc_id, pool_key, _talk_count)
```
`_check_proposal()`'s `affinity < 90` gate is UNCHANGED — proposal
eligibility is a raw-affinity check, not level-based, and 90 affinity
already equals level 9, so behavior is identical, just keep the
existing line as-is, don't touch it.

`DialogueDB.get_affinity_tier()` becomes dead code once this lands —
confirm nothing else calls it (grep the whole repo) before removing it;
if something else does, leave it and just stop calling it from
`RomanceNPC.gd`.

## Tests

Extend `tests/test_peer_npcs.gd` (or a new `tests/test_level_system.gd`
if cleaner):
- `GameData.level_for(x)` unit checks: 0→0, 9→0, 10→1, 55→5, 89→8, 90→9,
  100→10, and clamping (negative/over-100 inputs, if any caller could
  produce them — check, don't assume).
- For Niran/Fah/Ploy: affinity 5 → level 0 → dialogue pool `"0"`... wait,
  re-check the boundary: affinity 0-9 → level 0, but the DIALOGUE dict
  only defines `"1"` through `"10"` per this spec — decide whether level
  0 needs its own pool or falls back to `"1"`'s pool (recommend: fall
  back to `"1"`, matching `get_line()`'s existing "pool empty → fall
  back" behavior, since a level-0 case is only reached in the first ~9
  affinity points of a brand new relationship — document whichever
  choice is made in a comment).
- Existing tier-boundary tests in `test_peer_npcs.gd` (if any check
  specific dialogue tier strings) need updating to check level numbers
  instead — read the current file for what exists before changing it.

## Constraints

- No `SaveManager.gd`/schema changes in this task — level is fully
  derived from data that's already persisted.
- Do not change `_check_proposal()`'s affinity>=90 threshold.
- Do not touch Kiet/Malee/Kanya — they don't exist yet (TASK-341, next).
- Run `bash scripts/ci/run_gate.sh all` — regression-check
  `test_anniversary.gd`/`test_wedding.gd` specifically (marriage flow
  reads affinity directly, not through the tier/level system, so should
  be unaffected, but verify rather than assume).
- No git/gh actions — stop after code + tests are written and the gate
  is green. Do not commit, push, open a PR, or merge.
