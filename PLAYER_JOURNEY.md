# PLAYER JOURNEY — Three Years in Ban Suan Chai

**Revised 2026-09-01, round 3** — this pass reflects what's actually shipped, not what's planned. Since the last revision, engine-lane closed out the entire Wing Kwai, Phi Ta Khon, and Lopburi arcs, fixed the festival-recurrence bug, added the silver currency economy, and shipped all three previously-deferred long-term-play payoffs (repetition, fishing ceiling, romance ceiling). The skeleton below is now mostly a map of real systems, not speculation.

Calendar: `TimeManager.gd` — 30 days/season × 3 seasons (hot → monsoon → cool) = **90 days/year**. `day_of_season()` and `year()` are the real APIs everything (festivals, veteran scaling) keys on now.

---

## Year 1 — Learning the valley (Days 1–90)

**Hot (Days 1–30)**
- Day 1: wake at map center. Starting inventory: rice, seed_rice, a machete.
- **Day 3 — Songkran.** Confirmed recurring now (see "The bug that's now fixed" below) — this is the first of many, not the only one.
- Meet the core five: Elder, Child, Handler, Monk, Trader. Village Headman and Vet also live from the start now (instanced for Wing Kwai/animal care).
- First Binthabat offering (05:00–07:30 window).
- Barter economy active (`GameData.BARTER_PAIRS`) — **silver doesn't exist yet** narratively; the market stall handles both barter and, once a player has sellable surplus, silver sale (see Economy section).

**Monsoon (Days 31–60)**
- Lotus root, pandan, water spinach open up.
- **"The Canal Breaks"** — Handler's disaster quest. Gather wood, report, reinforce the bank before it floods. Reward: flood-ward charm + harmony. Wood-gathering (the resource system, axe tool) is the same system Lopburi's raid economy will later use — this quest is effectively the tutorial for it.
- **"The Elder's Request"** — harvest jasmine rice, offer at Binthabat.
- Buffalo care loop running; affinity hearts (0–100, 25/heart, 4 hearts max) visible from day one now.
- First silver sale at the market stall, once there's surplus to sell.

**Cool (Days 61–90)**
- Thai basil, garlic, lettuce, cabbage, tomato open up.
- **Wan Sart (day 5)** and **Loy Krathong (day 7)** — both early in the season, real breathing room afterward.
- Fishing rod obtainable, skill starts at 1.
- Meet Niran and Fah — "stranger" tier. Meet Nong Ton and Uncle Somchai (now fully instanced, speaking NPCs, not scaffolds).

*End of Year 1: full core loop, one scripted quest, one disaster quest, two festivals experienced once — all four confirmed to fire again next year.*

---

## Year 2 — Depth, economy, and Wing Kwai (Days 91–180)

**Hot (Days 91–120)**
- Full hot-season crop roster live: chili, sesame, peanut, sugarcane, watermelon, mango, durian, papaya, banana, coconut.
- **"Fah's Elusive Catch"** — realistic now with a season of fishing practice behind the player.
- **Phi Ta Khon quest** — Nong Ton and Uncle Somchai are real NPCs with their own dialogue branches now, not placeholders.
- **Wing Kwai, fully built:** stamina-mash race minigame, then the payoff — mounted buffalo riding with an instant 3×3 auto-plow. This is the single biggest farming-speed jump in the game, and it's live from here on, not a "someday" system.
- Niran/Fah likely "friendly" tier, regular gifting against the real per-NPC preference table.

**Monsoon (Days 121–150)**
- Taro, ginger round out the wet-season set.
- **"Niran's Harvest Challenge"** — durian's 6-day final stage is a comfortable commitment at this calendar length.
- Second Canal Breaks-style monsoon should read as competence, not crisis, by now.
- Tool tiers climbing (can/hoe/sickle) — barter-priced in rice_grain, coexists with the silver economy.

**Cool (Days 151–180)**
- **"Trader's Coastal Order"** — fish_sauce now a routine sellable/market good.
- **"Monk's Morning Merit"** — a patience quest with room to actually feel like patience.
- **"Lopburi Monkey Banquet," fully built:** wood-gathering economy, the monkey raid event itself, and the "Crop Truce" buff that resolves the donation step peacefully — no combat, no chase, matches the zero-harm pillar exactly as designed.
- Niran/Fah likely "close" tier.

---

## Year 3 — Systems designed to keep paying off (Days 181–270)

This is the section that changed most. The three findings that used to live here as *deferred, low-priority, pending playtest* (issues #143–145 / TASK-280–282) are no longer deferred — they shipped, this round, as real systems:

- **Repetition softening (TASK-280):** veteran-year scaling. Each completed year adds +1 flat harvest yield (cap +3 at Year 4+), plus a veteran-flavored dialogue branch. No new content chain needed — the existing loop quietly gets more generous the longer you've played.
- **Fishing ceiling payoff (TASK-281):** at skill 4, catches get a big-fish bias (0.55) and a flat +5 silver "mastery tip" per catch. Maxing the skill now has a tangible payoff instead of just unlocking rarer entries in `fish.json`.
- **Romance ceiling payoff (TASK-282):** married NPCs now trigger a yearly anniversary event — +30 silver, +10 harmony, a dedicated event line — once per year, with a cozy daily fallback line the rest of the year. Marriage was previously the ceiling; now it's a floor with its own repeating beat.

**Hot (Days 181–210)**
- Third Songkran. Romantic-tier dialogue live if affinity's been maintained, now with the anniversary system layered on top if married.
- Rare/legendary fish (Mekong Giant Catfish, Golden Mahseer) realistic at skill 3–4, with the mastery tip making the grind pay literal dividends.

**Monsoon (Days 211–240)**
- No new unlocks by design — full rotation: mount-assisted multi-crop farming, three animals, a fishing habit with a real payoff curve, a maturing relationship with its own yearly beat, a recipe book covering all 27 crops, a functioning dual economy (barter + silver).

**Cool (Days 241–270)**
- Third full festival cycle — confirmed recurring, not a one-off anymore.
- Veteran yield bonus at its cap. The natural horizon for whatever comes next.

---

## The bug that's now fixed

Round 2 of this document flagged that all four festival triggers compared against the absolute day counter instead of the within-season day, so every festival could only ever fire once, total, across the whole game. That's fixed (`TASK-292`, PR #148): `TimeManager.day_of_season()` and `TimeManager.year()` are now the real APIs, each trigger keys its "already fired" dictionary on `year-season`, and all three festivals plus the Lopburi raid confirmed re-firing correctly year over year. Everything above that says "third Songkran" or "third festival cycle" is now something the game actually does, not something it should do.

## The bigger change: a currency economy exists now

Earlier rounds of this document treated zero-currency as a fixed design pillar — the Lopburi quest's literal reward was deliberately reworked away from a currency payout for that reason. That decision has since been reversed at the owner's direct order (`ISSUE-135`, ["Owner decision reversal on #135 (no-currency → silver) per user order"]) — a silver wallet, sell prices, and a buy counter now sit alongside the original barter system rather than replacing it. Every quest/system reward above that lists silver is describing this new economy, not barter goods.

## What's still genuinely open

Two small items survive from prior rounds, both minor:
- `data/npc/gift_preferences.json` is still an orphaned file — zero references anywhere in the codebase, superseded by `DialogueDB.GIFT_PREFERENCES`.
- Nong Ton's forest-monster/ghost-story line and the generic Child NPC's forest-sighting line cover overlapping thematic ground now that Nong Ton is a real speaking NPC rather than a silent scaffold — not a bug, just a content-polish overlap.

Both are covered in the gap discussion below.
