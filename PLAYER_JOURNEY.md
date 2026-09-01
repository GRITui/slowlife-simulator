# PLAYER JOURNEY — Three Years in Ban Suan Chai

**Revised 2026-09-01** after the calendar change (`season_duration_days` 10 → 30). A skeleton timeline of what a player experiences, grounded in the real calendar (`TimeManager.gd`: 30 days/season × 3 seasons = **90 days/year**, hot → monsoon → cool, repeating). Not a script — a shape. Festival day-numbers are real (`FestivalManager.gd`/`SongkranTrigger.gd`/`WanSartTrigger.gd`/`LopburiRaid.gd`); everything else is paced by feel.

---

## Why the calendar changed

The original 10-day season (30-day year) compressed everything into roughly a third of genre-standard pacing (Stardew-class games run ~28 days/season, ~112/year). At 30 days/season, "3 years" is now **270 days**, not 90 — three times the room for the same content to breathe.

**Reassessed the ripple effects before touching anything else — most of it turned out fine:**
- **Crop growth times unchanged, and don't need to be.** They were already tuned in absolute days (quick tier 3 days, up to durian's 6), which was ~30-60% of the old 10-day season — cramped. At 30 days/season, the same absolute times are now ~10-20% of a season, which is *closer* to genre norms, not further. The season length was the problem, not the crop timings.
- **Quest pacing unaffected or improved** — nothing in `QuestData` is day-gated; Monk's "3 non-consecutive Binthabat days" gets easier to pace naturally, not harder.
- **Fishing skill and affinity progression** — no day-gating either, just event-driven. Unaffected.

**One real bug found while checking this, not caused by the calendar change:** all four festival triggers (`FestivalManager.gd` day 7, `SongkranTrigger.gd` day 3, `WanSartTrigger.gd` day 5, `LopburiRaid.gd` day 9) check against the **absolute day counter** (`minute_ticked`'s `day`, the one HUD shows as "Day 47" and never resets) instead of the within-season day. That means every festival fires **exactly once in the entire game**, on whatever absolute day it happens to land on, then silently never again — no matter how many years pass. This was always broken, just easy to miss without a multi-year playthrough. Flagged to `PO_INBOX.md`, not fixed here (control-flow logic, outside art-lane scope) — but it's the single most important fix for this timeline to actually hold up, since without it, a player's *second* Songkran never happens.

---

## Year 1 — Learning the valley (Days 1–90)

**Hot (Days 1–30)**
- Day 1: wake on the Title Screen, spawn at map center. Starting inventory: rice, seed_rice, a machete. Jasmine rice is the only default-plantable crop until a different seed is held (TASK-043's generalized planting).
- **Day 3 — Songkran** (assuming the recurrence bug above is fixed; otherwise this is the *only* Songkran the player will ever see). First festival, whole village gets splashed.
- Meet the core five: Elder, Child, Handler, Monk, Trader.
- First Binthabat offering (05:00–07:30 window).
- With 30 days now instead of 10, there's real room to plant, grow, and harvest jasmine rice multiple times before the season turns — the "farming" part of a farming sim finally has space to repeat and improve within a single season.

**Monsoon (Days 31–60)**
- Lotus root, pandan, water spinach open up.
- **New: "The Canal Breaks."** Handler warns the rising water is outpacing the sluice gate; gather wood, report to him, help reinforce the bank before it floods. Zero-combat "disaster" framing — a race against weather, not a fight. Reward: a flood-ward charm + solid harmony.
- **Quest: "The Elder's Request"** reachable — harvest jasmine rice, offer it at Binthabat.
- Buffalo care loop running (hearts, 0–100 in 25-point steps).
- First market barter, first taste of the coastal-goods offers.

**Cool (Days 61–90)**
- Thai basil, garlic, lettuce, cabbage, tomato open up.
- **Day 5 (Wan Sart)** and **Day 7 (Loy Krathong)** — both land early in the 30-day cool season now, leaving 20+ days of "aftermath" to actually feel the harmony payoff rather than immediately rushing into the next season.
- Fishing rod obtainable, skill starts at 1.
- Meet Niran and Fah — "stranger" tier.

*End of Year 1: every core system introduced, one full quest and one new disaster-quest closed, both festivals experienced once (pending the bug fix, which is what makes "once" become "every year").*

---

## Year 2 — Depth and relationships (Days 91–180)

**Hot (Days 91–120)**
- Full hot-season roster: chili, sesame, peanut, sugarcane, watermelon, mango, durian, papaya, banana, coconut.
- **Quest: "Fah's Elusive Catch"** — needs fishing skill past 1, realistic by now with 90 extra days of practice behind the player.
- **Quest: "Phi Ta Khon"** — Nong Ton and Uncle Somchai, both real NPCs now.
- **Wing Kwai** — `stamina_mash`, the race itself, and the big payoff: mounted buffalo riding + instant 3×3 auto-plow. The single biggest quality-of-life jump in the game; farming speed changes from here on.
- Niran/Fah likely at "friendly" tier with regular gifting (per-NPC preference tables now cover all 7 social NPCs).

**Monsoon (Days 121–150)**
- Taro, ginger round out the wet-season set.
- **Quest: "Niran's Harvest Challenge"** — durian's 6-day final stage is no longer a season-dominating commitment at this length; realistic to complete alongside everything else.
- Second Canal Breaks-style monsoon should feel routine by now if the recurrence bug is fixed — competence, not crisis.
- Tool tiers climbing (can/hoe/sickle).

**Cool (Days 151–180)**
- **Quest: "Trader's Coastal Order"** — fish_sauce now a routine market good.
- **Quest: "Monk's Morning Merit"** — a patience quest that finally has the calendar room to feel like patience rather than a scramble.
- Niran/Fah likely at "close" tier.

---

## Year 3 — Payoff and legacy (Days 181–270)

**Hot (Days 181–210)**
- **Quest: "Lopburi Monkey Banquet"** — the donation step is trivial by now given three years of crop surplus; "Crop Truce" buff resolves it peacefully.
- Rare and legendary fish (Mekong Giant Catfish, Golden Mahseer) realistic targets at skill 3–4.
- Third Songkran — "romantic" tier dialogue live if affinity's been maintained.

**Monsoon (Days 211–240)**
- No new unlocks by design — this is where the loop should feel *complete*, not expanding. Full rotation: multi-crop farming with the mount, three animals, a fishing habit, a deepening relationship, a recipe book covering all 27 crops.

**Cool (Days 241–270)**
- Third full festival cycle. Still the natural horizon for whatever's next — marriage payoff, a legendary-fish milestone, or nothing at all if the loop is meant to simply continue, genre-standard style.

---

## What's still true, even at 3x the length

The three low-priority findings from the original version of this document (issues #143–145: long-term repetition, fishing-skill ceiling, romance ceiling) are **not resolved by the calendar change alone** — they're just proportionally further away now (Day 270+ instead of Day 91+). The calendar fix bought real room, not a permanent answer. Still deferred, same reasoning as before: build them once there's actual play data, not guesses.

**New, higher-priority than any of those three:** the festival-recurrence bug. Everything in this document assumes festivals repeat every year — right now, in the actual codebase, they don't.
