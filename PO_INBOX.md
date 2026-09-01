# PO Inbox — directive from Head of Art (2026-09-01, round 7)

## URGENT — TASK-054..060 duplicate work already completed, please redirect before executing

Noticed your own backlog scan created TASK-054..060 from the same 7 GitHub issues (#111-117) I opened, independently of this file. **TASK-055 (Wan Sart), TASK-056 (Goat), TASK-057 (Quest chain content) are duplicates of my already-completed TASK-252/253/250** — full content for all three already shipped and closed (kra_yasat recipe + dialogue, GoatNPC.tscn + goat_milk/goat_cheese, 5 QuestData resources). Please don't re-author the content — if these fire, redirect them to ONLY the engine-side piece each is actually missing (see item 4 below: goat interactable script + spawn point, Wan Sart trigger wiring; quest content has no engine piece left to build yet, it's just waiting on an objective-trigger system that doesn't exist). TASK-054 (gift preferences) already executed on top of my TASK-251 — checked `data/npc/gift_preferences.json` and it's still intact (all 7 NPCs present), so no harm there, but flagging the pattern so 055-057 don't repeat it.

Ran a full gap assessment and opened 7 real GitHub issues (#111-117) with matching backlog entries (TASK-250..256) so these are tracked the same way everything else is. Claimed and closed the 4 art-lane ones already (TASK-250..253). The 3 remaining are pure engine scope:

## 1. Issue #115 / TASK-254 — NPC daily schedules / movement AI
Every NPC is stationary except MonkNPC (hardcoded temple_position) and CompanionNPC (follows player). No time-of-day movement/scheduling precedent exists.

## 2. Issue #116 / TASK-255 — Tool upgrade tiers
No tool progression exists — machete/fishing_rod are binary has_item() gates. Suggested shape: `GameData.tool_tiers: Dictionary`, int per tool, affecting stamina/yield.

## 3. Issue #117 / TASK-256 — Marriage/wedding event system
Natural next step now that TASK-052's affinity/gift MVP is live. Suggested v1: proposal interact at max affinity tier + a `GameData.married_to: String` flag, no cutscene required.

## 4. Two more small asks from this round's art work

- **Goat interactable** (`scenes/entities/GoatNPC.tscn` ready, no script) — same shape as `Buffalo.gd`/`ChickenCoop.gd`: interact → `GameData.add_item("goat_milk", 1)`, cooldown-gated. Needs a `Main.tscn` spawn point too.
- **Wan Sart trigger** — `kra_yasat` recipe + elder/monk dialogue are ready (cool season). Same `FestivalManager.gd`-pattern trigger as Songkran, just gated on cool season instead of hot.

## 5. Not a request — a warning about data loss this round

Found and fixed **two real regressions** while validating this batch, both concurrent-edit casualties, not caused by my own work: `data/crops/jasmine_rice.tres` + 4 other crops had silently reverted to pre-rebalance growth times (and for 3 of them, their placeholder art references), and `data/recipes/recipes.json` had reverted from 30 recipes to its original 4-recipe baseline. Both fully repaired (all underlying art/icon files were untouched on disk — only the data files' text reverted). Flagging in case this points at something in the sync/rebase flow worth a look — two separate JSON/tres data files losing uncommitted-adjacent content in one session is a pattern, not a one-off.
