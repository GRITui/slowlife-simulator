# TASK-349 — 10-level system, phase 3: villagers (combined with season)

Depends on TASK-346/348. Applies the 10-level system to general
villagers (Elder, Child, Handler, Headman, Vet, Nok — the ones using
`DialogueDB.get_seasonal_line()`, season-keyed dialogue, no existing
tier system at all) per the owner's explicit "combine both" choice:
**season stays primary, level is a secondary modifier layered on top**
— NOT a full season × level × rain combinatorial rewrite (that would
be 400+ new lines; this is a bounded addition instead).

## The actual scope, precisely (read this before writing anything)

Do NOT give villagers 10 fully distinct dialogue pools per level. Add
exactly ONE new priority branch — a "high affiliation" bonus pool —
mirroring the EXACT structure `get_seasonal_line()` already uses for
the `rain` branch (TASK-329) and the `binthabat_hint` branch: a
probabilistic override sampled ahead of the season fallback, not a
replacement of it.

```gdscript
## TASK-349: level defaults to 0 so existing callers (MonkNPC.gd, any
## test without a level arg) are unaffected. Priority stays
## binthabat_done > binthabat_hint > rain > high_affiliation > season —
## inserted last/lowest-priority since it's the newest, most optional
## flavor layer; season content should still be the common case even
## at high affiliation, not overridden most of the time.
static func get_seasonal_line(npc_id: String, season: String, binthabat_done: bool, hint_roll: int, weather: String = "clear", level: int = 0) -> String:
	var npc: Dictionary = DIALOGUE.get(npc_id, {})
	if npc.is_empty():
		return "..."
	# ... existing binthabat_done / binthabat_hint / rain branches, UNCHANGED ...
	if level >= 6:
		var high_pool: Array = npc.get("high_affiliation", [])
		if not high_pool.is_empty() and hint_roll % 5 < 2: # same ~40% chance as the rain branch
			return String(high_pool[hint_roll % high_pool.size()])
	var pool: Array = npc.get(season, [])
	if pool.is_empty():
		pool = npc.get("cool", [])
	return String(pool[hint_roll % pool.size()])
```

One new `"high_affiliation"` pool per villager (Elder, Child, Handler,
Headman, Vet, Nok — 6 villagers), 2 lines each = 12 new lines total,
season-agnostic (fires regardless of current season, since it's about
the RELATIONSHIP level, not the weather/season). Written warmer/more
familiar than their normal seasonal lines — a sign the player's
effort with them specifically is being noticed, distinct from generic
seasonal flavor. Headman/Vet currently have minimal existing dialogue
(check what exists before assuming a rich baseline to contrast against
— read `DialogueDB.gd`'s `"headman"`/`"vet"` entries in full first).

## `scenes/entities/VillagerNPC.gd` — thread the level through

`talk()` currently calls:
```gdscript
var line: String = DialogueDBScript.get_seasonal_line(npc_id, season, binthabat_done, _talk_count, _current_weather())
```
Change to:
```gdscript
var level: int = GameData.level_for(int(GameData.affinity.get(npc_id, 0)))
var line: String = DialogueDBScript.get_seasonal_line(npc_id, season, binthabat_done, _talk_count, _current_weather(), level)
```
`GameData.affinity` already holds villager affinity generically (the
same dict romance candidates use — gift-giving to villagers was
extended to use it back in the Gemini-loop pass, TASK-335/338's
predecessor work) — no new field needed, just read it.

## Tests

Extend `tests/test_weather_dialogue.gd` (the existing file covering
`get_seasonal_line()`'s priority branches) with:
- `level < 6`: `high_affiliation` never fires regardless of `hint_roll`.
- `level >= 6` with a favorable `hint_roll` (matching the rain branch's
  existing test pattern for the ~40% chance): returns a
  `high_affiliation` line, distinct from the season pool.
- `binthabat_done`/`binthabat_hint`/`rain` still outrank
  `high_affiliation` even at level 10 (priority order unchanged, just
  extended — mirror the existing priority tests for the other
  branches, one more assertion in the same style).
- A villager with no `"high_affiliation"` pool defined (shouldn't
  happen once this ships for all 6, but test the graceful-fallback
  path anyway — reuse whatever "npc not in dict" safety pattern
  already exists elsewhere in this file).
- `VillagerNPC.talk()` end-to-end: pushing a villager's affinity to 60+
  (level 6) and calling `talk()` enough times to hit the ~40% roll at
  least once shows a `high_affiliation` line (extend
  `tests/test_gift_prefs.gd` or wherever villager talk-flow is already
  covered).

## Constraints

- Do not touch `MonkNPC.gd`'s call to `get_seasonal_line()` — it
  doesn't pass a `level` arg, which defaults to 0, so it's unaffected;
  leave it that way (Monk doesn't have a `high_affiliation` pool and
  doesn't need one for this task).
- Do not change the existing `binthabat_done`/`binthabat_hint`/`rain`
  branch logic or priority order relative to each other — only insert
  the new branch at the bottom, right before the season fallback.
- Do not touch romance candidates (Ek/Fah/Ploy/Chang/Klong/Yaa) —
  they use a completely different dialogue function
  (`get_line()`/TASK-346's 10-level pools), not `get_seasonal_line()`
  at all.
- Run `bash scripts/ci/run_gate.sh all` — regression-check
  `tests/test_schedules.gd` and `tests/test_weather_dialogue.gd`
  specifically (both exercise `get_seasonal_line()` heavily).
- No git/gh actions — stop after code + tests are written and the gate
  is green. Do not commit, push, open a PR, or merge.
