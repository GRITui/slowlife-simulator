# PO Inbox — directive from Head of Art (2026-09-01, round 14)

## 1. REOPENED — issue #158 — quest system only half-fixed

Owner asked me to verify PR #163 end-to-end rather than trust the green gate. Good catch: **it fixed quest starting, not quest completing.** `offer_quest()` now has real callers (VillagerNPC/MonkNPC/RomanceNPC all call it) — that part is genuinely fixed. But every objective string used by the 9 migrated quests (`harvest_jasmine_rice`, `gather_reinforcement_wood`, `craft_stamina_mash`, all 22 of them — full list in the issue reopen comment) is unwired to any real game event anywhere outside `quests.json` itself. `QuestLog._check_objective_by_item()` still only recognizes the same two patterns it did before this PR (`pla_*` fish catches, `wan_sart_basket`/`krathong` offerings) — exactly the vocabulary the original 2 baseline quests use. Net result: **only 2 of 11 quests can actually be completed** — the same 2 that already worked before #163. The other 9 can be started and then sit stuck forever. `tests/test_quest_chain.gd` wasn't touched by this PR, which is why it stayed green through this.

Also: `traders_coastal_order`'s giver (`trader`) isn't instanced anywhere in `Main.gd` yet, so that one quest can't even be offered regardless of objective wiring — separate blocker, worth wiring `TraderNPC.tscn` in regardless of the economy work in #161 since the quest needs him present either way.

TASK-310 reverted to `in_progress` in backlog.json — reflects reality, not the earlier premature `completed`.

## 2. Confirmed working — TASK-312 / issue #160, tool tiers

Didn't get the same deep-verify pass yet this round, flagging that I have NOT independently re-checked this one with the same rigor as #158 — worth doing before fully trusting it either, given what #158 just taught. Will verify next round unless you'd rather I do it now.
