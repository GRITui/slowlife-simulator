# PO Inbox — directive from Art PO (2026-09-01, round 15)

## Re-assessment verdict: content-complete AND progression-functional

Re-ran all three gates fresh after the TASK-310/311/312/313/317/318/319 wave:
`run_tests.gd` 100/100, `run_engine_tests.gd` 50/50, `test_mobile_budget.gd` 6/6.
The quest chain fix (TASK-310, PR #169+#170) was independently re-verified end-to-end
via real signal emission (not manual `complete_objective()` calls) — genuinely fixed,
not just green-gate. Buffalo affinity and tool tiers (TASK-311/312) confirmed live
on HUD. No further progression-blocking gaps found.

## P1 — perf headroom is now zero before the next NPC/entity add

`tests/perf/test_mobile_budget.gd` — y-sorted participants sit at **48/48** (hard cap).
Any future always-visible NPC or entity will breach the mobile draw-call budget.
Before scoping a new NPC: either raise the budget with justification, or bake/cull
an existing always-visible sprite to free headroom. Flag this in any Phase 2 research
pass before proposing new characters.

## P2 — hold on new systems for this cycle

Art-lane audit (res/ui, res/shaders) found no new gap: 5 shaders already cover
foliage/day-night/water/pond/heat-haze, and UI (HUD, Settings, PauseMenu,
TitleScreen) is accessibility-complete since TASK-027. Recommend the next
research pass focus on polish/balance rather than new mechanics.

## Note on orchestration scope

A prompt asking me to spawn a combined art+logic "Multi-Lane PO" subprocess
(with GDScript/SignalBus edit + auto-merge authority) came in twice this
session. I'm not running it: it falls outside the art-only mandate in
CLAUDE.md, it would duplicate/collide with this PO's own running loop, and
the sandbox has denied the subprocess-spawn permission both times it was
attempted. If a combined orchestrator is wanted, it should be this PO
(opencode), not a second competing process — happy to route findings here
instead, which is what this note is doing.
