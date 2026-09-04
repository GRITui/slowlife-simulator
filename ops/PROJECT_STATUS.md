# Project Status
_Auto-updated by scripts/ci/update_project_status_local.py (local, deterministic — no model call) — do not hand-edit, it will be overwritten._
Last updated: 2026-09-04

## Kanban

### Backlog
- TASK-361: Full furniture placement system (Stardew/Animal-Crossing style) -- worth building? (#228)
- TASK-367: Extend farmhouse decor anchor-slots to a second slot (bed) ((no issue))
- TASK-368: Map decoration pass on existing areas + prop-density guideline for future areas ((no issue))
- TASK-369: FestivalVisualDriver's FestivalLanterns/PondGlow also never instanced ((no issue))
- TASK-373: 17 fully-built NPCs (6 romance candidates + their 6 paired rivals + 5 villagers incl. Trader) never instanced anywhere in the game ((no issue))
- TASK-374: Furniture placement system, Phase 1: core data model + one placeable item, FarmHouse-only, no rotation ((no issue))
- TASK-375: Furniture placement system, Phase 2: rotation + additional furniture items + more rooms ((no issue))

### Doing
(none)

### Done
- TASK-005: Define 3/4 art rules in ART_STYLE_GUIDE (tile metrics, Y-sort, zoom 2.2 provisional) (#207)
- TASK-006: Generate tall art assets for 3/4 canon (16-color palette) (#208)
- TASK-007: World render: 20x16 tilemap matrix + Y-sort layers + bounds + edge dressing (#209)
- TASK-008: Camera center-lock in-engine + zoom tune (3/4 canon) (#210)
- TASK-009: Player walk 8-frame / idle 4-frame animation wiring (#211)
- TASK-010: HUD QA + seasonal tint + screenshot capture hook (#212)
- TASK-321: Mining/ore resource loop (MVP scope, redesigned from floor-gen concept) (#213)
- TASK-322: Farm/house building upgrades (carpenter-equivalent sink) (#214)
- TASK-323: Livestock depth: quality tiers (split A) + breeding (split B) — both done (#215)
- TASK-324: Life-progression events beyond current marriage ceiling — done, final backlog item (#216)
- TASK-325: Working pets/mounts (redesigned: companion bond + race tie-in) (#217)
- TASK-326: Shipping-milestone stamina progression (redesigned from: stamina upgrades + shipping-triggered seed unlocks) (#218)
- TASK-327: Seed purchasing + market shop UI (blocker found while scoping TASK-326) (#219)
- TASK-328: Weather-reactive NPC schedules (rain routes NPCs indoors) (#179)
- TASK-329: Weather/festival-aware dialogue priority tier (#180)
- TASK-330: Festival density expansion (2-4 more lightweight festivals) (#181)
- TASK-331: Milestone collectibles across varied activities (not just shipping) (#182)
- TASK-332: Repeatable side-quest noticeboard (#183)
- TASK-333: Affinity decay for ignored NPCs -> weekly interaction streak bonus (owner-directed alternative) (#184)
- TASK-334: Tool tier AoE/charge mechanic (multi-tile clear at max tier) (#185)
- TASK-335: Third romance candidate (Ploy) (#220)
- TASK-336: Real scored Fishing Competition (first competitive mini-game) (#221)
- TASK-337: Secondary unlockable area (Mountain Cave) (#222)
- TASK-338: Grow the named NPC roster (Nok) (#223)
- TASK-339: Songkran Cooking Contest (second scored mini-game) (#224)
- TASK-340: Rival win/loss save schema + RivalClock mechanism (Sprint 1 of 5) (#192)
- TASK-345: Early rival-awareness — fix a real fairness gap in the TASK-340/341/342 warning system (#194)
- TASK-346: 10-level system, phase 1: shared scale + romance dialogue retrofit (#195)
- TASK-341: 3 more romance candidates (Kiet, Malee, Kanya) — Sprint 2 of the 6+6+5 plan (#193)
- TASK-347: Schema v5 — rival progress meter + rival friendship/confession fields (#186)
- TASK-342: 6 rival NPCs, wired-up win/loss clock, friendship + confession dilemma (#187)
- TASK-350: Active-seed selection for planting — first real gap in the "no menu UI" philosophy (#196)
- TASK-351: HUD visual polish pass (#197)
- TASK-343: Unlockable areas 4-5: Deep Canal Bend, Sacred Grove (#188)
- TASK-344: Unlockable areas 6-7 (final 2 of 5): Lotus Maze Shore, Coastal Trading Post (#189)
- TASK-348: 10-level system, phase 2: buffalo, chicken, companion cat (#190)
- TASK-349: 10-level system, phase 3: villagers (combined with season) (#191)
- TASK-352: Building interiors + map transitions (foundation) (#198)
- TASK-353: Fix scene-transition spawn drift + prevent instant re-trigger loops (#199)
- TASK-357: Multi-scene world topology framework (screen-graph) (#203)
- TASK-355: Give the farmhouse interior real function (bed, weather source) (#201)
- TASK-354: Scene-transition fade + door SFX (transition juice) (#200)
- TASK-358: Fish Almanac — first-catch collection log for FishingSpot (#225)
- TASK-359: Fishing depth beyond a single-roll: cast-mechanic vs. fish-pond husbandry? (#226)
- TASK-360: Farmhouse decor anchor-slots -- swappable shrine/bed/rug/wall-hanging (#227)
- TASK-362: Silver ore material sink -- consume it in the carpenter kitchen upgrade (#229)
- TASK-363: Recipe discovery via villager friendship (gift-based unlocks) (#230)
- TASK-365: Fog weather visual effect (currently unused data) (#231)
- TASK-366: Wire up orphaned RainDriver/HeatHazeDriver + add leaf-particle ambiance ((no issue))

### Open GitHub issues not yet in backlog-inbox.md
- #206: TASK-372: Extend rain-day schedule routing beyond Elder/Child
- #205: TASK-371: Fog weather effect (currently unused data)
- #204: TASK-370: Animal weather-care system (feed cost, outside/inside state, sickness)
- #202: TASK-356: Indoor ambience + explicit indoor/outdoor time-pause decision
- #173: App Store icon set missing

## RACI (default rule — see scripts/ci/update_project_status_local.py's header comment for why this is a stated rule rather than a per-task table here)
Responsible = Cline (delegate) for source=AI-LOOP tasks, Claude for source=OWNER tasks needing design judgment. Accountable = Claude (Code Quality Review + merge), always. Consulted = blank unless noted in the GitHub issue body. Informed = ops/backlog-inbox.md + the GitHub issue, always.
