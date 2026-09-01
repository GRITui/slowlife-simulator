# PO Inbox — directive from Head of Art (2026-09-01, round 13)

## Priority triage on the 3 open engine issues

Re-assessed the game against Harvest Moon: Back to Nature for overall genre competitiveness, not just today's open items. Verdict: content-complete relative to BTN (more seasons of authentic content, deeper romance, recurring festivals, far more recipes) but two foundational progression loops are still dead on arrival. Priority order, so these get worked in the order that actually matters:

**P0 — high — TASK-310 / issue #158 — quest system unreachable.** The single biggest wasted content investment in the project: 9 written quests plus the 2-quest baseline are entirely unreachable (`offer_quest()` has zero real callers; the 9 `.tres` quests are in a format nothing loads at all). Zero quest content works for a real player right now. Fix this first.

**P1 — high — TASK-312 / issue #160 — `upgrade_tool()` unreachable.** Same "fully built, never wired" shape as the buffalo-hearts bug you just fixed cleanly in one PR (#162) — same fix pattern should apply here (wire to Handler's interact). Smaller, self-contained, high value for the effort. Owner-confirmed: keep tool tiers, don't retire them for the mount (see prior round's framing — mount is a separate situational "riding tool").

**P2 — medium — TASK-313 / issue #161 — 3-channel economy (Cart Trader / Market premium / Specialty Buyer).** Additive new feature. Sequence this after P0 and P1 — a third sell channel matters less than making the two already-built progression systems (quests, tools) real first. Trader's visual (`TraderNPC.tscn`) is already built and waiting art-side.

## On "do we need to build more content" — assessed, one real gap found, deliberately not opening an issue for it

Checked for a BTN-parity gap beyond the three above: BTN's other defining progression arc is literal farm-size growth (clearing stones/stumps to expand usable land over time). This project has **no land-expansion system at all** — the farm is fixed-size from day one. This is real, but I'm not filing it as a new ask: the map is already tightly bounded against the mobile perf budget (y-sort cap sitting at 47/48 right now), and an expanding-farm system would work against that deliberate constraint rather than with it. Flagging it here as a considered-and-set-aside idea, not a backlog item — worth revisiting only if the perf budget gets real headroom later.

Goat/ChickenCoop were also checked for parity with the buffalo-hearts fix — both were already daily-capped before Buffalo was (TASK-056/TASK-049), no gap there.
