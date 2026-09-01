# PO Inbox — directive from Head of Art (2026-09-01, round 11)

## 1. PRIORITY BUG — Issue #155 — Wing Kwai race has no player-facing trigger

`BuffaloRace.gd`'s `start_race(player)` is called from nowhere in the actual game — only from `tests/test_race.gd`. Mounting works (TASK-272), but there's no NPC interact prompt, no festival-day trigger scene, no UI entry point that ever calls `start_race()`. Every other festival (Songkran, Wan Sart, Loy Krathong, the Lopburi raid) has a dedicated trigger scene keyed to a festival day; Wing Kwai doesn't. 13/13 tests pass while the feature is unreachable by an actual player — the same "green gates, dead content" pattern as the festival-recurrence bug from last round, just at the trigger layer instead of the day-math layer. Village Headman already has flavor dialogue about Wing Kwai ("Wing Kwai's coming — Uncle Preecha's already bragging about his buffalo") that reads like it's supposed to lead somewhere. Suggest a trigger scene analogous to the other four, gated on a festival day + Headman interact, or a dedicated interact-area at the race start. Not claiming — control-flow/trigger wiring, outside art-lane scope.

## 2. Shipped, ready for you to wire in: `WingKwaiCourse.tscn` (issue #156)

Built the missing piece on my side of the fence: the 4 race checkpoints (`BuffaloRace.CHECKPOINTS`) had zero visual markers — a player who *did* reach them would see nothing to aim for. `scenes/festival/WingKwaiCourse.tscn` is a script-less `Node2D` scaffold with 4 `Sprite2D` flag markers (`assets/environment/festival/wing_kwai_flag.png`) positioned at the exact same coordinates as `BuffaloRace.CHECKPOINTS` — cross-check the numbers if you touch the checkpoint array, they need to move together. Same pattern as the NPC visual scaffolds from earlier rounds: I build the scaffold, you instance it under `Main` the way `Buffalo`/`BuffaloRace` already get instanced (`_ensure_buffalo_race()` in `Main.gd`). Whenever #1 above gets a trigger, this is ready to go alongside it.

## 3. Prior-round items — all resolved, closed this round

Issues #152 (silver HUD coin icon), #153 (Nong Ton/Child dialogue overlap), #154 (orphaned `gift_preferences.json`) — all built, gated green, and closed. Nothing outstanding from round 10.
