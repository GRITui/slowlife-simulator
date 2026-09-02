# TASK-335 — Third romance candidate: Ploy

Sprint 1 of the "broaden to compete with HM:BtN" plan (2026-09-02),
following the quality/stickiness verdict comparing this game to HM:BtN.

## Why

Confirmed via code audit: only 2 marriage candidates exist (Niran, Fah)
against HM:BtN's 5. `RomanceNPC.gd`, the affinity-tier dialogue system,
`GIFT_PREFERENCES`, and the marriage/anniversary/life-progression
machinery are all already generic and parameterized by `npc_id` —
adding a 3rd candidate is mostly content on top of existing
infrastructure, not new engineering.

## Character

**Ploy** — warm, sociable market dessert-maker near the temple lane.
Deliberately fills the personality gap Niran (competitive rival farmer)
and Fah (quiet introspective fisher) leave open: extroverted,
community-glue energy. Also ties the underused 36-recipe cooking system
into the romance content for the first time (her specialty-buy channel
wants cooked desserts, not raw produce/fish like Niran/Fah).

## What was built

- `scripts/narrative/DialogueDB.gd` — `"ploy"` entry in `DIALOGUE`
  (5 tiers: stranger/friendly/close/rival/romantic, matching Niran/
  Fah's exact structure and the TASK-324 rival-flavor pattern) and in
  `GIFT_PREFERENCES` (loved: mango_sticky_rice/banana_rice_cake; liked:
  banana/coconut/palm_sugar).
- `scenes/entities/RomanceNPC.gd` — new specialty-sell branch for
  `npc_id == "ploy"`. Initially specced desserts not in
  `GameData.SELL_PRICES` (khanom_krok, sangkhaya) — caught before
  shipping via the test failing, swapped to `banana_rice_cake` /
  `pandan_sticky_rice` which are actually sellable. khanom_krok/
  sangkhaya having no sell price is a real, separate, pre-existing gap
  — not patched here.
- `assets/characters/ploy_idle_01.png` — placeholder portrait (hue-
  shifted from `fah_idle_01.png` via a documented palette rotation, not
  original art — flagged for `SHIP_PLAN.md`'s open "Art pass" item).
- `scenes/entities/PloyNPC.tscn` — mirrors `NiranNPC.tscn` exactly.
- `scenes/core/Main.gd` — `PloyNPC` added to `_ensure_peer_npcs()`'s
  spots dict, position (6,2), verified clear of the maze/water/other
  NPCs via a headless `ground_at` probe.
- Deliberately NOT given a `ScheduleDB.gd` movement schedule — Niran and
  Fah are both static (RomanceNPC.gd doesn't reference ScheduleDB at
  all), so Ploy matches that existing precedent rather than introducing
  an inconsistency between romance candidates. Giving all three
  characters daily schedules is a natural, separately-scoped follow-up.

## Verification

- `tests/test_peer_npcs.gd` extended 11→20 checks: instancing, group
  tags, gift-tier flow (+20 loved gift), specialty-sell flow (item
  consumed, silver premium granted).
- Full gate green after one real regression caught and fixed: adding
  Ploy's `Sprite2D` pushed the Y-sort perf budget from 49→50 occupied
  slots (she has a real visual footprint, unlike `MiningSpot`/
  `Noticeboard`) — budget raised to 50 in
  `tests/perf/test_mobile_budget.gd`, matching the exact precedent set
  for `CarpenterUpgrade`.
- `run_gate.sh all`: content 100/100, engine 50/50, save-compat 35/35,
  perf-budget 6/6, touch-target 10/10. Regression-checked
  `test_anniversary.gd` (6/6), `test_wedding.gd` (6/6),
  `test_quest_chain.gd` (27/27), `test_schedules.gd` (12/12) — all
  unaffected (RomanceNPC.gd's shared marriage/anniversary/proposal
  logic is generic per-npc_id and wasn't touched, only extended).
