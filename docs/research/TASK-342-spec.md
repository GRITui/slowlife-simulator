# TASK-342 — 6 rival NPCs, wired-up win/loss clock, friendship + confession dilemma

The biggest single task in this plan. Depends on TASK-340 (schema +
`RivalClock`), TASK-341 (all 6 candidates exist), and **TASK-347**
(`rival_friendship` field + `SignalBus.rival_clock` registry — read
that spec first, this task is where its field actually gets used).

## Part A: `scripts/entities/RivalNPC.gd` — talk-only base, now with gifting

Extends the original design (talk-only) with gift-giving, since the
confession/dilemma needs a way for friendship to grow. NOT a
`VillagerNPC.gd` instance (rivals still don't have seasonal dialogue or
a schedule) and NOT a `RomanceNPC.gd` instance (no player-romance
affinity) — but DOES now reuse the `_give_gift()` mechanic's shape
(same `FOOD_ITEMS`-gated auto-picker, same `GameData.gift_tier()`/
`gift_affinity()` functions, applied to `rival_friendship` instead of
`affinity`).

```gdscript
extends CharacterBody2D
## RivalNPC — TASK-342. A named rival competing for a specific romance
## candidate. Talks (dialogue escalates with the courtship clock) AND
## accepts gifts (building rival_friendship, TASK-347) — high enough
## friendship unlocks a one-time reward + the confession dilemma
## (TASK-342 part C). Never touches the candidate's own affinity.

const DialogueDBScript: GDScript = preload("res://scripts/narrative/DialogueDB.gd")

@export var npc_id: String = ""
@export var display_name: String = ""
@export var candidate_id: String = ""

var _player_in_range: bool = false
@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null

func _ready() -> void:
	add_to_group("villager_npc")
	add_to_group("rival_npc")
	if _area != null:
		_area.body_entered.connect(_on_body_entered)
		_area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		try_interact()
		get_viewport().set_input_as_handled()

## Gift first (builds friendship, may trigger the confession), else talk.
func try_interact() -> void:
	if _try_confession_resolution():
		return
	if _give_gift():
		return
	talk()

func talk() -> void:
	var tier: int = int(GameData.rival_warning_shown.get(candidate_id, 0))
	var has_won: bool = bool(GameData.lost_to_rival.get(candidate_id, false))
	var line: String = DialogueDBScript.get_rival_line(npc_id, tier, has_won)
	SignalBus.show_dialogue.emit(display_name, line)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body != self:
		_player_in_range = false
```

`_give_gift()`/`_try_confession_resolution()` are detailed in Part C.

Uses a `.tscn` per rival (same shape as `NiranNPC.tscn`), one portrait
each — same as originally planned, unchanged.

## Part B: rival dialogue — tier-0 now reveals the stakes (TASK-345 fix)

Original plan had tier 0 as deliberately soft ("casual, no pressure
yet"), which — combined with the candidate's own rival-hint being
gated behind close-tier (unreachable by an at-risk player) — meant a
disengaged player could get zero warning ever. Fix: **tier 0 already
establishes the competing interest**, just without urgency. Example
shape (adapt per rival's personality):

```
0: "I've been meaning to talk to [Candidate] more myself, honestly."
1: (25%+) "[Candidate] and I have been talking a lot lately."
2: (50%+) "I think [Candidate] and I understand each other pretty well by now."
3: (75%+) "I'm not going to pretend I'm not hoping this goes somewhere."
"won": "[Candidate] and I are happy. I hope you understand."
```

`RIVAL_DIALOGUE` dict shape unchanged from the original plan (`rival_id
-> {0,1,2,3,"won"} -> lines`), 2 lines per state × 6 rivals = 30+ lines,
just with tier 0 rewritten per the above for all 6.

`get_rival_line()` unchanged from the original design.

## Part C: rival friendship + the confession dilemma

**Design principle: resolved through action, not a dialogue menu** —
this game has no branching-choice UI anywhere; every existing decision
(gift, propose, specialty-sell) is resolved by what the player is
holding when they interact. This follows the same pattern.

### Gift-giving builds `rival_friendship`

```gdscript
## Mirrors RomanceNPC._give_gift() exactly, applied to rival_friendship
## instead of affinity. Uses the SAME GIFT_PREFERENCES/gift_tier()
## mechanism — add a GIFT_PREFERENCES entry per rival (see table below).
func _give_gift() -> bool:
	var gift_id: String = ""
	for item_id: String in GameData.inventory.keys():
		if item_id in GameData.FOOD_ITEMS and int(GameData.inventory[item_id]) > 0:
			gift_id = item_id
			break
	if gift_id.is_empty():
		return false
	GameData.remove_item(gift_id, 1)
	var tier: String = DialogueDBScript.gift_tier(npc_id, gift_id)
	var delta: int = DialogueDBScript.gift_affinity(tier)
	GameData.rival_friendship[npc_id] = clampi(int(GameData.rival_friendship.get(npc_id, 0)) + delta, 0, 100)
	SignalBus.show_dialogue.emit(display_name, "Thanks for the %s." % gift_id.replace("_", " "))
	_maybe_trigger_confession()
	return true
```

`GIFT_PREFERENCES` additions, one per rival — pick items thematically
loose (rivals aren't gift-connoisseurs like romance candidates, keep it
simple): reuse each rival's paired candidate's OWN loved items is a
nice touch (they'd know what their candidate likes) but isn't required
— your call, verify against `FOOD_ITEMS` either way.

### Confession trigger (one-time, at a friendship threshold)

```gdscript
## Fires once, the first time rival_friendship reaches level 6+
## (GameData.level_for() from TASK-346 — friendly-NPC affiliation uses
## the same 10-level scale per the owner's instruction). Grants an
## immediate reward regardless of what the player chooses next, then
## marks the confession as delivered so it never repeats.
func _maybe_trigger_confession() -> void:
	if bool(GameData.rival_confessed.get(npc_id, false)):
		return
	if GameData.level_for(int(GameData.rival_friendship.get(npc_id, 0))) < 6:
		return
	GameData.rival_confessed[npc_id] = true
	GameData.add_silver(25)
	GameData.add_harmony(15)
	SignalBus.show_dialogue.emit(display_name,
		"Can I tell you something? I'm in love with %s. Has been for a while. ... Thank you for listening — that's worth more than you know. (+25 silver, +15 harmony)" % _candidate_display_name())

func _candidate_display_name() -> String:
	# Small lookup — candidate display names aren't currently exposed by
	# GameData; hardcode a rival_id -> candidate display name map here,
	# or thread it through @export like candidate_id (your call, whichever
	# is less duplication given how RivalClock.PAIRS already stores this).
	return candidate_id.capitalize()
```

### Resolution: continue rivalry (default) vs. concede

**Continue rivalry** = no special action. The player just keeps
courting the candidate normally; `RivalClock`'s existing win/loss logic
is completely unaffected by any of this. This is the default and needs
no code — explicitly note this in a comment so nobody tries to build a
"choice A" branch that doesn't need to exist.

**Concede** = the player gives the RIVAL a krathong (the same item used
to propose marriage — deliberately reused so the gesture reads as "I'm
setting this down instead of using it on them"), but ONLY after the
confession has fired:

```gdscript
## Checked BEFORE _give_gift() in try_interact() — a krathong is not a
## FOOD_ITEMS entry, so _give_gift() would never pick it up anyway, but
## checking it explicitly first makes the precedence unambiguous.
func _try_confession_resolution() -> bool:
	if not bool(GameData.rival_confessed.get(npc_id, false)):
		return false
	if bool(GameData.lost_to_rival.get(candidate_id, false)) or (GameData.married and GameData.spouse == candidate_id):
		return false # already resolved one way or the other
	if not GameData.has_item("krathong", 1):
		return false
	GameData.remove_item("krathong", 1)
	GameData.lost_to_rival[candidate_id] = true
	GameData.earn_milestone("matchmaker_%s" % npc_id, 20) # TASK-331's existing milestone system, reused
	SignalBus.show_dialogue.emit(display_name,
		"You're... sure? ... Thank you. I won't forget this. (Milestone: Matchmaker! +20 harmony)")
	return true
```

This is a genuinely permanent, deliberate choice — same enforcement
point as neglect-loss (`lost_to_rival[candidate_id] = true`), just
reached by generosity instead of inaction, and rewarded distinctly
(the `matchmaker_<rival_id>` milestone, reusing TASK-331's existing
`earn_milestone()` with zero new persisted structure needed beyond what
it already has).

### New `GameData.gd` field: `rival_confessed`

`var rival_confessed: Dictionary = {}` (`rival_id -> bool`) — needs
adding to the SAME v5 migration TASK-347 already builds (if TASK-347
lands first as planned, add this one field to it directly rather than
opening a 3rd migration; if this task somehow lands first, do the v5
bump here instead and note it clearly for TASK-347 to build on).

## Roster (unchanged from the original draft)

| Rival | Candidate | Personality | Position (re-verify before placing) |
|---|---|---|---|
| Decha | Niran | Louder, brasher version of Niran's own competitiveness | `Vector2(14*48+24, 4*48)` |
| Chai | Fah | Quietly persistent, patient in a way that unsettles | `Vector2(9*48+24, 12*48)` |
| Rung | Ploy | Charming, social, effortlessly likable | `Vector2(7*48+24, 3*48)` |
| Anon | Kiet | Less patient than Kiet, showy craft over careful craft | `Vector2(9*48+24, 3*48)` |
| Siri | Malee | Flashier performer, competitive about the spotlight | `Vector2(2*48+24, 9*48)` |
| Boon | Kanya | Calm scholarly rival, competes through quiet expertise | `Vector2(18*48+24, 8*48)` |

6 placeholder portraits, hue-shift technique, 6 distinct rotations.

## Wiring

1. `Main.gd`: add all 6 to `_ensure_peer_npcs()`'s `spots` dictionary.
2. `RivalClock.gd`: populate `PAIRS` with all 6 real pairings (exact
   dict shape from the original draft, unchanged).

## Tests

New `tests/test_rival_npcs.gd`:
- All 6 instanced, correct npc_id/candidate_id/display_name.
- Tier-0 `talk()` line differs from the old "casual" placeholder text —
  confirm it actually names the candidate or otherwise establishes
  competing interest (a simple `.contains()` check against the
  candidate's display name is enough).
- Gift-giving raises `rival_friendship`, mirrors the existing
  `test_gift_prefs.gd` shape.
- Confession fires exactly once at friendship level 6+, grants the
  fixed reward exactly once (repeat gifts after confession don't
  re-trigger it or re-grant the reward).
- **Concede path**: after confession, giving a krathong sets
  `lost_to_rival[candidate_id] = true`, grants the `matchmaker_<rival_id>`
  milestone (check `GameData.milestones_earned`), and a second krathong
  attempt is a no-op (already resolved).
- **Continue-rivalry path**: after confession, the player courting the
  candidate normally (gifts, talk) is completely unaffected — no new
  gate, no change in behavior from before the confession existed.
- Full end-to-end: `RivalClock`'s existing 90-day neglect-loss test
  from TASK-340/347 still passes unmodified with `PAIRS` now populated
  (regression, not new coverage).

## Constraints

- Do not modify `RivalClock._check_candidate()`/`_resolve_loss()`
  themselves — TASK-347 already built and tested that logic; this task
  only populates `PAIRS` and adds the separate friendship/confession
  system alongside it.
- The concede path and the neglect-loss path both set
  `lost_to_rival[candidate_id] = true` — this is intentional (one
  permanent outcome, two different roads to it) — do not add a second
  boolean to distinguish them unless a real need for that distinction
  shows up in testing.
- Run `bash scripts/ci/run_gate.sh all` — Y-sort budget will need
  another bump (6 more sprited NPCs).
- No git/gh actions — stop after code + tests are written and the gate
  is green. Do not commit, push, open a PR, or merge.
