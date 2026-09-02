extends SceneTree
# TASK-325 companion bond + race tie-in gate.
# Verifies: GameData.companion_bond/companion_bond_tier/add_companion_bond
# mirror the buffalo pattern (clamp 0..100, level_for() tier math),
# bond accrues only while within COMFORT of the player at the documented
# rate (1 per 60 nearby-minute ticks), caps at 100 (tier 10), does not
# grow while the companion is not nearby, and BuffaloRace._finish(true)
# grants the extra sticky_rice only when both conditions (companion
# within ~200px of the player AND bond tier >= 5) hold. Companion
# tier-up dialogue is emitted through SignalBus.show_dialogue only
# when the tier actually increases, not on every tick.
#
# TASK-348: scale unified with the 0-10 hearts system. The old /25.0
# 0-4 tier math is gone — tier now is level_for(bond) (0..10). The
# race bonus gate moved from tier >= 2 to tier >= 5 (same 50% of
# ceiling); the inseparable cap moved from 4 to 10 (same 100% of
# ceiling).

var _passed: int = 0
var _failed: int = 0
var _dialogue_hits: Array = [] # [speaker, text] pairs from show_dialogue

func _on_show_dialogue(speaker: String, text: String) -> void:
	_dialogue_hits.append([speaker, text])

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  companion_bond :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  companion_bond :: %s" % label)

func _initialize() -> void:
	var gd: Node = root.get_node("GameData")
	var sb: Node = root.get_node("SignalBus")
	# GameData API surface (mirrors buffalo_affinity exactly).
	_check("add_companion_bond" in gd, "GameData has add_companion_bond")
	_check("companion_bond_tier" in gd, "GameData has companion_bond_tier")
	gd.companion_bond = 0
	_check(int(gd.companion_bond_tier()) == 0, "starts at 0 / tier 0")
	# TASK-348: under the new 0-10 scale, 9 affinity = tier 0 (was 24 / 25).
	gd.add_companion_bond(9)
	_check(int(gd.companion_bond) == 9, "+9 -> 9")
	_check(int(gd.companion_bond_tier()) == 0, "9 / 10 = tier 0 (TASK-348: was 24/25=0)")
	gd.add_companion_bond(1)
	_check(int(gd.companion_bond_tier()) == 1, "10 / 10 = tier 1 (TASK-348: was 25/25=1)")
	gd.add_companion_bond(90)
	_check(int(gd.companion_bond) == 100, "+90 caps at 100")
	_check(int(gd.companion_bond_tier()) == 10, "100 / 10 = tier 10 (TASK-348 max, was 4)")
	gd.add_companion_bond(50)
	_check(int(gd.companion_bond) == 100, "clamped above 100")
	_check(int(gd.companion_bond_tier()) == 10, "tier stays 10 above 100 (TASK-348 cap)")
	gd.companion_bond = 0
	gd.add_companion_bond(-30)
	_check(int(gd.companion_bond) == 0, "clamped below 0")
	_check(int(gd.companion_bond_tier()) == 0, "tier stays 0 below 0")

	# Boot Main scene and wait for companion spawn (Main._ensure_companion).
	var main: Node = (load("res://scenes/core/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var cat: CharacterBody2D = main.get_node_or_null("CompanionNPC") as CharacterBody2D
	var player: Node2D = main.get_node_or_null("Player") as Node2D
	var race: Node = main.get_node_or_null("BuffaloRace")
	_check(cat != null, "CompanionNPC instanced")
	_check(player != null, "Player instanced")
	_check(race != null, "BuffaloRace instanced")
	if cat == null or player == null or race == null:
		main.queue_free()
		await process_frame
		quit(1)
		return

	# Listen to dialogue so we can verify per-tick silence vs. tier-up emit.
	sb.show_dialogue.connect(_on_show_dialogue)

	# Park companion next to the player so they start within COMFORT (56.0).
	player.global_position = Vector2(480, 384)
	cat.global_position = player.global_position
	# TASK-348: start one point below tier 1 (10, was 25 in the /25.0 era)
	# so a single 60-tick grant crosses the tier boundary — tests the
	# dialogue-on-tier-up integration without needing 1000 ticks (60 ticks
	# only ever grants +1 bond POINT, not a full tier — reaching tier 1
	# from scratch needs 10 separate grants under the new scale).
	gd.companion_bond = 9
	cat.set("_nearby_minutes", 0)

	# 59 ticks: no bond grant yet (need 60 for +1), and no dialogue at all.
	var pre_dialogue_count: int = _dialogue_hits.size()
	for i: int in 59:
		sb.minute_ticked.emit(1, 6, i)
	_check(int(gd.companion_bond) == 9, "59 nearby ticks -> bond still 9")
	_check(int(cat.get("_nearby_minutes")) == 59, "_nearby_minutes counts up (59)")
	_check(_dialogue_hits.size() == pre_dialogue_count, "no dialogue before bond tier-up")

	# 1 more tick triggers the 10th point AND crosses into tier 1.
	sb.minute_ticked.emit(1, 6, 59)
	_check(int(gd.companion_bond) == 10, "60th nearby tick -> +1 bond (9 -> 10)")
	_check(int(gd.companion_bond_tier()) == 1, "tier 1 after crossing 10")
	_check(int(cat.get("_nearby_minutes")) == 0, "counter resets after grant")
	var tier1_dialogue: bool = false
	for d in _dialogue_hits:
		if d[0] == "Companion" and String(d[1]).contains("bond: 1"):
			tier1_dialogue = true
	_check(tier1_dialogue, "Companion dialogue on tier 1 increase")

	# No growth when companion is far away. Park cat well beyond COMFORT and
	# tick many times; bond must not move.
	cat.global_position = player.global_position + Vector2(10000, 0)
	cat.set("_nearby_minutes", 0)
	for i: int in 200:
		sb.minute_ticked.emit(1, 7, i)
	_check(int(gd.companion_bond) == 10, "no growth while beyond COMFORT (200 ticks)")
	_check(int(cat.get("_nearby_minutes")) == 0, "counter stays 0 while far")

	# TASK-348: cap at 100 (tier 10, was tier 4 in the /25.0 era): jump
	# straight to cap via the API, then verify add_companion_bond refuses
	# to over-grant.
	gd.companion_bond = 100
	gd.add_companion_bond(5)
	_check(int(gd.companion_bond) == 100, "bond caps at 100")
	_check(int(gd.companion_bond_tier()) == 10, "tier caps at 10")

	# ----- BuffaloRace bonus tie-in -----
	# Case A: companion far away + tier 0 -> no extra rice.
	gd.companion_bond = 0
	gd.inventory.erase("sticky_rice")
	var sticky_before: int = int(gd.inventory.get("sticky_rice", 0))
	# Park companion way out of the 200px bonus radius.
	cat.global_position = player.global_position + Vector2(5000, 0)
	# Bypass the mount check by setting the player.mounted flag + calling
	# force_finish directly (the existing test_race.gd uses force_finish
	# for the timeout path; this exercises _finish's exact code). force_finish
	# skips start_race(), so _player (which _companion_bonus_eligible reads)
	# is never set by the normal path — set it directly here.
	player.set("mounted", true)
	race.set("_player", player)
	race.force_finish(true)
	var sticky_after_far: int = int(gd.inventory.get("sticky_rice", 0))
	_check(sticky_after_far - sticky_before == 3, "won race far/no bond -> +3 sticky_rice (no bonus)")
	# Companion-credit dialogue must NOT have fired in this case.
	var saw_credit_a: bool = false
	for d in _dialogue_hits:
		if d[0] == "Companion" and String(d[1]).contains("extra sticky rice"):
			saw_credit_a = true
	_check(not saw_credit_a, "no companion-credit dialogue when companion far")

	# TASK-348: Case B: companion near + tier < 5 (was tier < 2 in the
	# /25.0 era) -> no extra rice (bond gate fails).
	gd.companion_bond = 0
	gd.inventory.erase("sticky_rice")
	cat.global_position = player.global_position # within 200px
	race.force_finish(true)
	var sticky_after_low: int = int(gd.inventory.get("sticky_rice", 0))
	_check(sticky_after_low == 3, "won race near + tier 0 -> +3 sticky_rice (bond gate fails)")
	var saw_credit_b: bool = false
	for d in _dialogue_hits:
		if d[0] == "Companion" and String(d[1]).contains("extra sticky rice"):
			saw_credit_b = true
	_check(not saw_credit_b, "no companion-credit dialogue at tier < 5")

	# TASK-348: Case C: companion near + tier >= 5 (was tier >= 2 in the
	# /25.0 era; bond=50 lands on tier 5 either way since 50/10=5) ->
	# +1 bonus sticky_rice.
	gd.companion_bond = 50 # tier 5
	gd.inventory.erase("sticky_rice")
	cat.global_position = player.global_position # within 200px
	race.force_finish(true)
	var sticky_after_bonus: int = int(gd.inventory.get("sticky_rice", 0))
	_check(sticky_after_bonus == 4, "won race near + tier 5 -> +4 sticky_rice (bonus)")
	var saw_credit_c: bool = false
	for d in _dialogue_hits:
		if d[0] == "Companion" and String(d[1]).contains("extra sticky rice"):
			saw_credit_c = true
	_check(saw_credit_c, "companion-credit dialogue fires when both conditions hold")

	# Case D: companion near + tier >= 5 but on a LOST race -> no bonus.
	gd.companion_bond = 50
	gd.inventory.erase("sticky_rice")
	cat.global_position = player.global_position
	race.force_finish(false)
	var sticky_after_loss: int = int(gd.inventory.get("sticky_rice", 0))
	_check(sticky_after_loss == 0, "lost race grants no sticky_rice")

	sb.show_dialogue.disconnect(_on_show_dialogue)
	main.queue_free()
	print("\n=== COMPANION BOND TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("COMPANION BOND GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
