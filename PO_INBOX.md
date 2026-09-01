# PO Inbox — directive from Head of Art (2026-09-01, round 10)

## 1. PRIORITY BUG — Issue #146 — all 4 festivals fire exactly once, ever

Found reasoning through the calendar length change, not caused by it. `FestivalManager.gd`, `SongkranTrigger.gd`, `WanSartTrigger.gd`, `LopburiRaid.gd` all check their trigger day against the absolute day counter (`minute_ticked`'s `day`, never resets), instead of the within-season day (`TimeManager.gd`'s private `_days_in_season`). Every festival — Loy Krathong, Songkran, Wan Sart, the Lopburi raid — fires once total across the entire game, then silently never again, no matter how many years pass. `_triggered_seasons`'s own dict-key naming implies per-season recurrence was always the intent; the day-comparison just never matched that intent. This is higher priority than anything else in this round — a festival calendar that only ever happens once undermines the whole point of a seasonal game.

## 2. Calendar length changed: `season_duration_days` 10 → 30 (90 days/year)

Owner-insisted, grounded in genre comparison (Stardew-class games run ~112 days/year; ours was 30). Reassessed the ripple effects before touching anything else: crop growth times and quest pacing don't need rebalancing — they were tuned in absolute days already, so the longer season actually *improves* their proportion rather than requiring rework. `PLAYER_JOURNEY.md` fully rewritten with the new 90-day-year math.

## 3. New content: monsoon disaster quest, "The Canal Breaks"

`data/quests/canal_breaks.tres` + `flood_ward_charm` item + Handler dialogue, all shipped. Built as a one-time scripted quest (matches the existing QuestData pattern) rather than a true randomized recurring event — the owner's ask mentioned both framings ("disaster quest/random event"); the scripted version is what's buildable within art-lane scope right now. If a genuinely randomized, repeatable monsoon weather-event system is wanted later, that's a separate, larger engine ask (RNG-gated triggering distinct from the deterministic festival-day pattern) — not requesting it yet, just naming the fork in case it comes up.

## 4. Still open from prior rounds, unaddressed

`VillagerNPC.gd`'s double signal-connect (noisy, not gate-breaking). `data/npc/gift_preferences.json` still orphaned next to `DialogueDB.gd`'s own live `GIFT_PREFERENCES`. The Nong Ton dialogue-line overlap between the generic Child NPC and the now-instanced `NongTonNPC` (issue #132) — still unresolved, Child still speaks the line that's now also "owned" by a dedicated character.
