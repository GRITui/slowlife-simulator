extends StaticBody2D
# CarpenterUpgrade — TASK-322 house kitchen extension.
# Hybrid A/B: 50 silver + 5 wood + 3 silver_ore + 20 stamina to extend the
# home into a full Thai kitchen. Repairs infrastructure "house_kitchen",
# unlocks two new recipes (khao_soi, massaman_curry). Soft-fail dialogue
# per missing requirement (silver / wood / silver_ore / stamina) — no
# hard fail state. Mirrors SluiceGate.gd's interaction contract (Area2D
# proximity + `interact`).
# TASK-362: silver_ore added as the first real consume site for the
# rarest ore tier (MiningSpot._roll_ore weight 1.2 vs copper's 4.0).

@export var structure_id: String = "house_kitchen"
@export var repair_cost_silver: int = 50
@export var repair_cost_wood: int = 5
@export var repair_cost_silver_ore: int = 3
@export var repair_cost_stamina: float = 20.0
@export var reward_harmony: int = 5

var _player_in_range: bool = false

@onready var _sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var _prompt: Label = $PromptLabel if has_node("PromptLabel") else null
@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null

func _ready() -> void:
	add_to_group("carpenter_upgrade")
	if _area:
		_area.body_entered.connect(_on_body_entered)
		_area.body_exited.connect(_on_body_exited)
	_update_visual()
	# react to external repair (e.g., loaded save)
	SignalBus.infrastructure_repaired.connect(_on_infra_repaired)
	if _prompt:
		_prompt.visible = false
		_prompt.text = "Press [E] to upgrade"

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		_try_repair()
		get_viewport().set_input_as_handled()

func _try_repair() -> bool:
	if GameData.is_repaired(structure_id):
		SignalBus.show_dialogue.emit("Carpenter", "The kitchen is already extended. Khao Soi and Massaman Curry are unlocked.")
		return false
	# Check every requirement before touching any resource (mirrors
	# SluiceGate.gd's pattern) — no speculative deduct+refund, which would
	# otherwise double-fire SignalBus.silver_changed on a soft fail.
	if GameData.silver < repair_cost_silver:
		SignalBus.show_dialogue.emit("Carpenter", "Need %d silver to hire the carpenter." % repair_cost_silver)
		return false
	if not GameData.has_item("wood", repair_cost_wood):
		SignalBus.show_dialogue.emit("Carpenter", "Need %d wood planks for the new kitchen counter." % repair_cost_wood)
		return false
	if GameData.current_stamina < repair_cost_stamina:
		SignalBus.show_dialogue.emit("Carpenter", "Too tired to help build. Need %.0f stamina." % repair_cost_stamina)
		return false
	# TASK-362: silver_ore material sink — first real consume site for the
	# rarest of the 3 ore tiers (see MiningSpot._roll_ore weights: silver is
	# rare/1.2 vs copper common/4.0). Charged on top of the existing silver +
	# wood + stamina stack, mirroring GameData.upgrade_tool()'s
	# additive-ore-on-rice_grain precedent for spending ore via the standard
	# has_item / remove_item API.
	if not GameData.has_item("silver_ore", repair_cost_silver_ore):
		SignalBus.show_dialogue.emit("Carpenter", "Need %d silver ore to forge the kitchen fittings." % repair_cost_silver_ore)
		return false
	# All checks passed — deduct.
	if not GameData.spend_silver(repair_cost_silver):
		return false
	if not GameData.remove_item("wood", repair_cost_wood):
		GameData.add_silver(repair_cost_silver) # wood-fail rollback: refund silver
		return false
	if not GameData.remove_item("silver_ore", repair_cost_silver_ore):
		# silver_ore-fail rollback: refund silver + restore wood (TASK-362).
		GameData.add_silver(repair_cost_silver)
		GameData.add_item("wood", repair_cost_wood)
		return false
	GameData.current_stamina -= repair_cost_stamina
	GameData.repair_infrastructure(structure_id)
	GameData.add_harmony(reward_harmony)
	SignalBus.show_dialogue.emit("Carpenter", "Kitchen extended! Khao Soi and Massaman Curry are now unlocked.")
	_update_visual()
	_update_prompt()
	return true

func _update_visual() -> void:
	if _sprite == null:
		return
	var repaired := GameData.is_repaired(structure_id)
	if repaired:
		_sprite.modulate = Color(1, 1, 1, 1)
		_sprite.material = null
	else:
		# not yet built: weathered wood, darker
		_sprite.modulate = Color(0.65, 0.6, 0.58, 1)

func _update_prompt() -> void:
	if _prompt == null:
		return
	if not _player_in_range:
		_prompt.visible = false
		return
	if GameData.is_repaired(structure_id):
		_prompt.text = "Kitchen extended — khao soi and massaman unlocked"
		_prompt.visible = true
	else:
		var can := GameData.silver >= repair_cost_silver \
			and GameData.has_item("wood", repair_cost_wood) \
			and GameData.has_item("silver_ore", repair_cost_silver_ore) \
			and GameData.current_stamina >= repair_cost_stamina
		if can:
			_prompt.text = "Press [E] to upgrade (%d silver, %d wood, %d silver ore, %.0f stamina)" % [repair_cost_silver, repair_cost_wood, repair_cost_silver_ore, repair_cost_stamina]
		else:
			_prompt.text = "Need %d silver, %d wood, %d silver ore, %.0f stamina" % [repair_cost_silver, repair_cost_wood, repair_cost_silver_ore, repair_cost_stamina]
		_prompt.visible = true

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") or body.name == "Player" or body is CharacterBody2D:
		if body != self:
			_player_in_range = true
			_update_prompt()

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") or body.name == "Player" or body is CharacterBody2D:
		if body != self:
			_player_in_range = false
			if _prompt:
				_prompt.visible = false

func _on_infra_repaired(id: String) -> void:
	if id == structure_id:
		_update_visual()
		_update_prompt()