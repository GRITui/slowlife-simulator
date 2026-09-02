# TASK-328 / TASK-329 — Weather-reactive NPC schedules + dialogue

Sprint 1 of the "3 sprints, complete pending backlog" run (2026-09-02),
following the Gemini-loop gap analysis (`ops/ai-eng-log.md` run 16).

## TASK-328 — weather-reactive NPC schedules

`ScheduleDB.gd` already drives 7 NPCs' hour-based waypoints; `GameData.current_weather`
already varies via `TimeManager`, but nothing consumed it. Scoped to the two NPCs
whose schedule already labels one slot "home"/"home courtyard" (elder, child) —
reusing the existing position, not inventing new ones for NPCs without a clear
indoor slot (handler/niran/headman/vet/fah keep their normal schedule in rain;
a broader pass adding home positions for the rest is a natural follow-up, not
bundled here to avoid inventing map positions under time pressure).

- `ScheduleDB.waypoint_for(npc_id, hour, weather = "clear")` — new optional
  param, default keeps existing callers (`MonkNPC.gd`, `test_schedules.gd`)
  unaffected. `RAIN_HOME` dict overrides to the home position for the whole
  day when `weather == "rain"`.
- `VillagerNPC.gd` threads `_current_weather()` (reads `GameData.current_weather`)
  into both `waypoint_for()` call sites (`_ready()`, `_physics_process()`).

## TASK-329 — weather-aware dialogue branch

`DialogueDB.get_seasonal_line()` already has a priority-branch structure
(binthabat_done > binthabat_hint > season pool). Added a `weather` param
(default `"clear"`) and a `rain` branch between hint and season — a ~40%
flavor chance (`hint_roll % 5 < 2`) when actually raining and a `rain` pool
exists for that NPC, so season lines still show most of the time. Added
`rain` pools to elder/child/handler (2 lines each, matching existing voice);
headman/vet/trader/monk left without rain lines for this v1 (their NPC
scripts don't route through `get_seasonal_line` with weather anyway,
except monk which wasn't touched).

## Verification

- `tests/test_schedules.gd` extended 3→12 checks (rain override, clear
  unaffected, unaffected NPC, live physics-frame weather flip).
- New `tests/test_weather_dialogue.gd` (5/5) — priority ordering
  (binthabat_done > hint > rain > season), no-weather-arg backward compat,
  unknown-npc safety.
- Full gate green: `run_gate.sh all` (content 100/100, engine 50/50,
  save-compat 35/35, perf 6/6, touch 10/10).

## Not in scope (filed separately if wanted later)

- Rain waypoints for handler/niran/headman/vet/fah (no existing "home" slot).
- Rain dialogue for niran/fah (affinity-tiered `get_line()`, not
  `get_seasonal_line()` — different function, different data shape).
