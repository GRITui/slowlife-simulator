# VILLAGE LORE — Ban Suan Chai

A story bible for the Thai Rural Countryside Sim. Written to give the mechanical world (Hybrid A/B: 20×16 paddy plain + 3×3 lotus canal maze, `.decision.json`) an actual narrative throughline — the game had none beyond design-principle docs before this pass. Nothing here requires new engine systems; it's the frame the existing systems already sit inside.

---

## The valley

**Ban Suan Chai** ("Village of the Garden Heart") sits where the flat paddy plain meets a stranger piece of geography: a tight maze of canals threading around a lotus pond, said to have been dug generations ago by villagers who wanted to keep a little water wild even as the rest of the land was tamed into rice squares. Nobody quite remembers whose idea it was. The elder has a story about it that changes slightly every time she tells it — which is itself the point.

The village runs on three things: the harvest, the harmony, and the calendar. None of them are separate from each other.

- **The harvest** is the 27-crop roster now growing here — staple rice through the long-committed durian and papaya trees — plus what the canal gives up to anyone patient enough to fish it.
- **The harmony** is the soft, non-numeric sense that a season went well: alms given, neighbors talked to, festivals kept.
- **The calendar** is hot, monsoon, cool, and the two festivals that mark it — Loy Krathong at the pond, Songkran at the well.

## The village, by who's in it

**Grandmother-figure, "Elder"** — keeper of planting wisdom and half-true stories about the canal maze's origin. The one villager old enough to remember the valley before the sluice gate was fixed for good.

**"Child"** — young enough to still find the flooded paths after monsoon genuinely magical rather than an inconvenience. Wants mango sticky rice and kite weather in roughly equal measure.

**"Handler"** — minds the sluice gate and the water's temperament. Practical, unromantic about the valley, and the person actually responsible for it not flooding the wrong fields.

**"Monk"** (Phra Somchai) — keeps the 05:00–07:30 alms window at the temple lane. Accepts rice or fruit "with care," which is the closest thing the village has to a moral center.

**"Trader"** — runs the evening market stall, one seasonal barter offer at a time. Knows exactly what the village has too much of and too little of, and never says so directly.

**The buffalo** — pasture-kept, milk-giving, asks nothing of anyone. The valley's oldest resident by temperament if not by years.

**The temple cat** — Siamese-coated, recently willing to follow the farmer into the fields. Says nothing, judges everything.

### New this round — peer-age villagers

**Niran** — works a neighboring plot, same age as the farmer, treats every shared harvest like a friendly competition. The rivalry is the flirtation; neither of them has said so out loud yet. Comfortable being the first to admit the fields feel shorter with company.

**Fah** — the canal's fisherfolk, quieter than the village gives her credit for, keeper of the deep-water spots she doesn't share with just anyone. Where Niran is loud about affection, Fah shows it by what she's willing to say only to you.

*(Both are designed romance candidates per this round's request — see `docs/research` / `PO_INBOX.md` for the affinity-system spec needed to make that mechanical. The dialogue in `DialogueDB.gd`'s `niran`/`fah` branches is written in four tiers — stranger, friendly, close, romantic — ready for whichever affinity value gates them.)*

## The two festivals

**Loy Krathong** — once a season, the valley releases krathongs on the lotus pond. Village harmony rises. The pond glows a little that night; the lanterns aren't just decoration, they're the one night a year the whole village agrees to stop and look at the water instead of working around it.

**Songkran** — the hot-season water festival, arriving mid-heat like a relief valve. The village fills its jars early. Nobody stays dry, and nobody minds.

## What the valley believes, without saying it out loud

Nothing here is fought for. The zero-combat design isn't just a mechanical constraint — in-world, it's the valley's actual temperament. Hardship in Ban Suan Chai is a long durian wait, an unwatered plot, a fish that got away, a season that didn't go your way. Nothing is ever taken from anyone by force, including from the animals — the buffalo gives milk because it's cared for, not because anything is owed. Whatever story content gets built on top of this (quests, deeper NPC arcs, the eventual dating payoff) should keep failing *soft* — the way a missed alms window or an unripe durian tree already does.
