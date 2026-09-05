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

**Grandmother-figure, "Elder"** — keeper of planting wisdom and half-true stories about the canal maze's origin. The one villager old enough to remember the valley before the sluice gate was fixed for good. Trader's mother.

**"Child"** — young enough to still find the flooded paths after monsoon genuinely magical rather than an inconvenience. Wants mango sticky rice and kite weather in roughly equal measure. Handler's younger sister — the one person who can drag him away from the sluice gate to go looking for kite weather.

**"Handler"** — minds the sluice gate and the water's temperament. Practical, unromantic about the valley, and the person actually responsible for it not flooding the wrong fields. Child's older brother.

**"Monk"** (Phra Wichai) — keeps the 05:00–07:30 alms window at the temple lane. Accepts rice or fruit "with care," which is the closest thing the village has to a moral center. Ampai's older brother, which makes him Yaa's uncle — the two rarely mention it, since a monk's alms line isn't the place for family favor.

**"Trader"** — runs the evening market stall, one seasonal barter offer at a time. Knows exactly what the village has too much of and too little of, and never says so directly. Elder's son.

**The buffalo** — pasture-kept, milk-giving, asks nothing of anyone. The valley's oldest resident by temperament if not by years.

**The temple cat** — Siamese-coated, recently willing to follow the farmer into the fields. Says nothing, judges everything.

### New this round — peer-age villagers

**Niran** — works a neighboring plot, same age as the farmer, treats every shared harvest like a friendly competition. The rivalry is the flirtation; neither of them has said so out loud yet. Comfortable being the first to admit the fields feel shorter with company.

**Fah** — the canal's fisherfolk, quieter than the village gives her credit for, keeper of the deep-water spots she doesn't share with just anyone. Where Niran is loud about affection, Fah shows it by what she's willing to say only to you.

### The ones who live alone (locked 2026-09-05)

Three villagers who keep their own company by choice, not misfortune — each holding a different flavor of thing worth knowing, if you bother to ask.

**The Ferryman** — lives alone at a small dock past the working end of the canal, where the paddies give way to open water. Rarely seen before dusk, minds his own nets and his own business. He's the one person in the valley for whom the canal maze's origin isn't a story that changes with the telling — he remembers who actually dug it, and why, and has simply never seen a reason to correct the Elder's version. The deep water off his dock holds a prawn nobody else fishes up.

**The Fish-Keeper** — an old woman who lives alone in a cabin up past the tree line, further out than most villagers bother to walk. She loves fish more than she loves company, by her own admission, and spends her days working out how to keep a catch longer than a single day — salting, smoking over banana leaf, curing in clay jars the way it was done before anyone had a cold box. What she knows isn't a village secret, it's a nearly-lost practical craft: real food-preservation technique nobody else left in the valley still does properly. The wild turmeric growing wild around her cabin is the reason her jars keep as long as they do.

**The Scrap Collector** — never sleeps in the same place twice, camping at whichever field edge is empty that week. Nobody thinks much of a scavenger sifting through what people throw away, which is exactly why he ends up knowing the most about everyone's small discarded regrets — an old letter never sent, a gift someone couldn't bring themselves to keep. Gossip and quiet intrigue rather than lore or craft, and the only one of the three who'd actually enjoy being asked about it. Whatever pile he's picked through that week is worth a look — usable scrap, if nothing else.

*(Both are designed romance candidates per this round's request — see `docs/research` / `PO_INBOX.md` for the affinity-system spec needed to make that mechanical. The dialogue in `DialogueDB.gd`'s `niran`/`fah` branches is written in four tiers — stranger, friendly, close, romantic — ready for whichever affinity value gates them.)*

### Romance candidate persona/flaw archetypes (locked 2026-09-05)

Owner-sourced (via Gemini) a "traditional Siam dating sim" archetype set —
six personas each with a distinct normal-mode charm and a "gap moe"
comedic flaw. Per this project's standing rule (Gemini output gets
verified, not pasted in unreviewed — see `AI-ENG-001`), these were
matched against each candidate's ALREADY-ESTABLISHED occupation and
dialogue voice rather than taken as literal replacements — every
candidate keeps her existing job/visual identity (fisher's net, paddy
fields, market stall, carving tools, drum, herb basket); only the
underlying persona/flaw layer is new.

- **Mali** (rice-paddy farmer, npc_id `ek`, established as
  competitive/guarded — "still sizing you up") → **Cool Swordswoman**:
  fearless, stoic front. Flaw: flusters into a stuttering mess the
  moment a compliment is sincere rather than competitive banter.
- **Fah** (canal fisher, npc_id `fah`, established as
  quiet/reads-the-water) → **Chill Buffalo Whisperer** (adapted: reads
  canal/tide instead of buffalo/weather): unbothered, sharp-tongued,
  sees things others miss. Flaw: disorganized recluse — a messy hut,
  sleeps straight through the morning catch.
- **Ploy** (dessert vendor, npc_id `ploy`, established as
  warm/magnetic — "first one's always free") → **Village Bombshell**:
  confident, playful, turns heads. Flaw: a dessert prodigy who is
  catastrophically bad at any savory cooking (rice, curry) — one-trick
  genius, hopeless outside it.
- **Kwan** (wood carver, npc_id `chang`, established as
  quiet/soft-spoken — "I don't talk much while I carve") → **Soft Silk
  Weaver** (adapted craft): sweet, patient, quiet grace. Flaw: an
  unhinged, trash-talking tactician the instant a riverboat race or
  kite duel starts.
- **Rin** (festival drummer, npc_id `klong`, established as
  lively/teasing — "might drag you into the dance circle") →
  **Sensual Canal Trader** (persona match over literal trade): bold,
  flirtatious, takes charge. Flaw: terrified of ghost stories (phi) —
  fearless on stage, useless in the dark.
- **Yaa** (herbalist/gardener) → **Sharp Herbalist Scholar**: the one
  direct occupation match, needed no adaptation. Brilliant, precise
  about plants and medicine. Flaw: zero physical coordination — trips
  over thresholds and into mud paddies despite handling delicate herbs
  all day.

This is persona/flaw canon only — it does NOT yet change any actual
`DialogueDB.gd` dialogue text. Rewriting each candidate's dialogue tiers
to actually reflect these voices/flaws is real narrative-writing work
(self-executed tier per `CLAUDE.md`, not delegated) and is queued as a
separate follow-up task rather than folded into tonight's art-pipeline
work.

## The two festivals

**Loy Krathong** — once a season, the valley releases krathongs on the lotus pond. Village harmony rises. The pond glows a little that night; the lanterns aren't just decoration, they're the one night a year the whole village agrees to stop and look at the water instead of working around it.

**Songkran** — the hot-season water festival, arriving mid-heat like a relief valve. The village fills its jars early. Nobody stays dry, and nobody minds.

## What the valley believes, without saying it out loud

Nothing here is fought for. The zero-combat design isn't just a mechanical constraint — in-world, it's the valley's actual temperament. Hardship in Ban Suan Chai is a long durian wait, an unwatered plot, a fish that got away, a season that didn't go your way. Nothing is ever taken from anyone by force, including from the animals — the buffalo gives milk because it's cared for, not because anything is owed. Whatever story content gets built on top of this (quests, deeper NPC arcs, the eventual dating payoff) should keep failing *soft* — the way a missed alms window or an unripe durian tree already does.
