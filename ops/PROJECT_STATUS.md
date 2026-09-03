# Project Status
_Auto-updated by scripts/ci/update_project_status.sh — do not hand-edit, it will be overwritten._
Last updated: 2026-09-03

## Kanban

### Backlog
- TASK-345: Early rival-awareness fairness gap (#194) — (status unclear)

### Doing
- TASK-357: Multi-scene world topology framework (screen-graph) (#203)

### Done
- TASK-353: Fix scene-transition spawn drift + door-facing on entry (#199)
- TASK-351: HUD visual polish pass (#197)
- TASK-350: Active-seed selection for planting (#196)
- TASK-349: 10-level system, phase 3 (villagers, combined with season) (#191)
- TASK-348: 10-level system, phase 2 (buffalo, chicken, companion cat) (#190)
- TASK-347: Schema v5 — rival progress meter + rival friendship/confession fields (#186)
- TASK-346: 10-level system, phase 1 (shared scale + romance dialogue retrofit) (#195)
- TASK-344: Unlockable areas 6-7 (Lotus Maze Shore, Coastal Trading Post) (#189)
- TASK-343: Unlockable areas 4-5 (Deep Canal Bend, Sacred Grove) (#188)
- TASK-342: 6 rival NPCs, wired-up win/loss clock, friendship + confession dilemma (#187)
- TASK-341: 3 more romance candidates (Chang/Klong/Yaa cast, formerly Kiet/Malee/Kanya) (#193)
- TASK-340: Rival win/loss save schema + RivalClock mechanism (#192)
- TASK-339: Songkran Cooking Contest (second scored mini-game)
- TASK-338: Grow the named NPC roster (Nok)
- TASK-337: Secondary unlockable area (Mountain Cave)
- TASK-336: Real scored Fishing Competition (first competitive mini-game)
- TASK-335: Third romance candidate (Ploy)
- TASK-334: Tool tier AoE/charge mechanic (multi-tile clear at max tier) (#185)
- TASK-333: Affinity decay for ignored NPCs -> weekly interaction streak bonus (#184)
- TASK-332: Repeatable side-quest noticeboard (#183)
- TASK-331: Milestone collectibles across varied activities (#182)
- TASK-330: Festival density expansion (2-4 more lightweight festivals) (#181)
- TASK-329: Weather/festival-aware dialogue priority tier (#180)
- TASK-328: Weather-reactive NPC schedules (rain routes NPCs indoors) (#179)
- TASK-327: Seed purchasing + market shop UI
- TASK-326: Shipping-milestone stamina progression
- TASK-325: Working pets/mounts (companion bond + race tie-in)
- TASK-324: Life-progression events beyond current marriage ceiling
- TASK-323: Livestock depth (quality tiers + breeding)
- TASK-322: Farm/house building upgrades
- TASK-321: Mining/ore resource loop (MVP scope)
- TASK-352: Building interiors + map transitions (foundation) (#198)
- TASK-010: HUD QA + seasonal tint + screenshot capture hook
- TASK-009: Player walk 8-frame / idle 4-frame animation wiring
- TASK-008: Camera center-lock in-engine + zoom tune (3/4 canon)
- TASK-007: World render (20x16 tilemap matrix + Y-sort + bounds + edge dressing)
- TASK-006: Generate tall art assets for 3/4 canon (16-color palette)
- TASK-005: Define 3/4 art rules in ART_STYLE_GUIDE

### Open GitHub issues not yet in backlog-inbox.md
- #202: TASK-356: Indoor ambience + explicit indoor/outdoor time-pause decision
- #201: TASK-355: Give the farmhouse interior real function (bed, weather source)
- #200: TASK-354: Scene-transition fade + door SFX (transition juice)
- #173: App Store icon set missing

## Milestones

### Scene-transition track (current focus) — partially Doing
Sprint order per TASK-357: #199 → #203 → #201 → #200 → #202.
- TASK-353 (#199): Fix scene-transition spawn drift — **Done**
- TASK-357 (#203): Multi-scene world topology framework (screen-graph) — **Doing**
- TASK-355 (#201): Give the farmhouse interior real function — **Backlog** (issue only)
- TASK-354 (#200): Scene-transition fade + door SFX — **Backlog** (issue only)
- TASK-356 (#202): Indoor ambience + indoor/outdoor time-pause — **Backlog** (issue only)

### Building interiors foundation — fully Done
- TASK-352 (#198): Building interiors + map transitions (foundation) — **Done**

### 10-level system (3 phases) — fully Done
- TASK-346 (#195): Phase 1 (shared scale + romance dialogue retrofit) — **Done**
- TASK-348 (#190): Phase 2 (buffalo, chicken, companion cat) — **Done**
- TASK-349 (#191): Phase 3 (villagers, combined with season) — **Done**

### 6 romance + 6 rivals + 5 unlockable areas — fully Done
- TASK-340 (#192): Sprint 1 — rival win/loss save schema + RivalClock — **Done**
- TASK-341 (#193): Sprint 2 — 3 more romance candidates — **Done**
- TASK-342 (#187): Sprint 3 — 6 rival NPCs wired-up — **Done**
- TASK-343 (#188): Sprint 4 — unlockable areas 4-5 — **Done**
- TASK-344 (#189): Sprint 5 — unlockable areas 6-7 — **Done**
- TASK-347 (#186): Schema v5 (rival progress + friendship/confession fields) — **Done**
- TASK-345 (#194): Early rival-awareness fairness gap — **Backlog** (status unclear; appears resolved)

### Broaden to compete with HM:BtN (3 sprints) — fully Done
- Sprint 1 — TASK-335 (Ploy) + TASK-336 (Fishing Competition): **Done**
- Sprint 2 — TASK-337 (Mountain Cave) + TASK-338 (Nok NPC): **Done**
- Sprint 3 — TASK-339 (Songkran Cooking Contest): **Done**

### AI-LOOP Phase 2 (Gemini gap follow-up) — fully Done
- TASK-328/329/330/331/332/333/334: **Done**

### AI-LOOP Phase 1 (6 approved backlog items) — fully Done
- TASK-321 (mining), TASK-322 (upgrades), TASK-323 (livestock depth), TASK-324 (life-progression), TASK-325 (companion bond), TASK-326 (stamina/shipping milestone), TASK-327 (seed shop): **Done**

### Foundation sprint — fully Done
- TASK-005/006/007/008/009/010: **Done**

## RACI (current sprint's tasks only — scene-transition track)
| Task | Responsible | Accountable | Consulted | Informed |
|---|---|---|---|---|
| TASK-353 — Fix scene-transition spawn drift + prevent instant re-trigger loops (#199) | Cline (delegate) | Claude (Code Quality Review + merge) |  | ops/backlog-inbox.md + GitHub #199 |
| TASK-357 — Multi-scene world topology framework (screen-graph) (#203) | Cline (delegate) | Claude (Code Quality Review + merge) |  | ops/backlog-inbox.md + GitHub #203 |