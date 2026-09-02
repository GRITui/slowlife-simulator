# TASK-341 — 3 new romance candidates (Kiet, Malee, Kanya)

**Depends on TASK-346 landing first** (the 10-level dialogue system —
these 3 candidates are authored directly in that format, not the old
4-tier shape). Brings the romance-candidate count from 3 to 6. Also
folds in **TASK-345's fix** (the early-warning fairness gap) for all 3
new candidates from the start, so it isn't a second pass later.

## Characters (unchanged from the original draft)

- **Kiet** — apprentice woodcarver under Somchai (ties into existing
  Phi Ta Khon mask-carving lore). Meticulous, quiet pride in craft,
  understated. Position `Vector2(8 * 48 + 24, 2 * 48)` — verified
  `ground_grass`, clear of every existing node position (re-verify
  against the current list, which has grown since).
- **Malee** — festival performer/drummer, bold and expressive,
  contrasts the quieter cast. Position `Vector2(3 * 48 + 24, 9 * 48)`.
- **Kanya** — herbalist, gentle, nature-connected. Position
  `Vector2(17 * 48 + 24, 7 * 48)`.

## Per-candidate content (verified obtainable/sellable)

| | Loved (gift) | Liked (gift) | Specialty-sell |
|---|---|---|---|
| Kiet | `thai_basil_stirfry`, `som_tam` | `rice_grain`, `egg` | `wood`, `banana_leaf_stem` |
| Malee | `mango_sticky_rice`, `pandan_sticky_rice` | `banana`, `egg` | `wan_sart_basket`, `durian_sticky_rice` |
| Kanya | `thai_basil`, `lotus_root` | `pandan_leaf`, `banana_leaf` | `thai_basil_stirfry`, `lotus_soup` |

All loved/liked items confirmed in `GameData.FOOD_ITEMS` (the auto-gift
picker's ONLY source — verify before writing, this exact mistake has
shipped twice already this session). Specialty-sell items confirmed in
`GameData.SELL_PRICES`.

## What to build

1. **`scripts/narrative/DialogueDB.gd`**: a `"kiet"`/`"malee"`/`"kanya"`
   entry each in `DIALOGUE`, using TASK-346's 10-level shape directly
   (keys `"1"`-`"10"` plus `"rival"`, 2 lines per level, 20+2 lines per
   candidate) — NOT the old stranger/friendly/close/romantic shape. A
   `GIFT_PREFERENCES` entry each per the table above.
2. **TASK-345's fix, applied here for all 3**: each candidate's level
   `"1"` pool gets one additional line (beyond the normal 2) that
   surfaces the rival's existence once `GameData.rival_warning_shown.get(npc_id, 0) >= 1`
   — i.e., `get_line()`'s caller needs a small addition: when at level 1
   AND a warning has fired, prefer this specific line over the normal
   level-1 pool. Simplest implementation: add a `"1_warned"` pool key
   per candidate (1-2 lines, e.g. Kiet: "Someone's been asking whether
   I've... noticed you. I said I hadn't decided what I noticed yet."),
   and in `RomanceNPC._talk()`, check
   `if level == 1 and int(GameData.rival_warning_shown.get(npc_id, 0)) >= 1: pool_key = "1_warned"`
   BEFORE the existing rival-flavor-override check (order doesn't
   collide — that override only applies at levels 6-8). Apply the same
   `"1_warned"` pattern to Niran/Fah/Ploy too while this file is open
   (small addition, same session as TASK-346's retrofit or here,
   whichever lands second — check which one actually ends up owning
   this edit and don't duplicate it).
3. **TASK-345's other half, applied here**: each of the 6 rivals'
   (TASK-342, not built yet) tier-0 dialogue should reveal the
   competing interest immediately rather than staying "casual" — note
   this requirement is actually TASK-342's to implement, not this
   task's; it's listed here only so whoever builds this task knows the
   `"1_warned"` line above is one half of a two-part fix, the other
   half lands with the rivals themselves.
4. **`scenes/entities/RomanceNPC.gd`**: 3 new `elif npc_id == "..."`
   branches in `_try_specialty_sell()`, per the table above.
5. **3 placeholder portraits**: `kiet_idle_01.png`, `malee_idle_01.png`,
   `kanya_idle_01.png` — hue-shift technique, 3 distinct rotations from
   3 different source sprites.
6. **3 new `.tscn` files** mirroring `NiranNPC.tscn`/`PloyNPC.tscn`.
7. **`scenes/core/Main.gd`**: add all 3 to `_ensure_peer_npcs()`'s
   `spots` dictionary.

## Tests

Extend `tests/test_peer_npcs.gd`: instanced, group tag, npc_id/
display_name, loved-gift-flow (+20 affinity), specialty-sell flow, for
each of the 3. Plus one check per candidate that `"1_warned"` fires
correctly when `rival_warning_shown >= 1` at level 1, and does NOT fire
at level 1 with no warning yet.

## Constraints

- Do not touch Niran/Fah/Ploy's dialogue content directly (TASK-346
  owns their retrofit) — but DO check whether TASK-346 already added
  the `"1_warned"` pattern to them before duplicating that plumbing.
- Do not add any rival NPC or touch `RivalClock.gd`/`PAIRS` — TASK-342.
- Run `bash scripts/ci/run_gate.sh all` — Y-sort budget will need
  another bump (3 new sprited candidates).
- No git/gh actions — stop after code + tests are written and the gate
  is green. Do not commit, push, open a PR, or merge.
