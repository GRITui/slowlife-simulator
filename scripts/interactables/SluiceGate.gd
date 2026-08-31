extends StaticBody2D
# SluiceGate — TASK-011 irrigation canal repair mechanic (Reverse pillar)
# Hybrid A/B: canal row y=13 at maze south (cell 15,13), TILE 48. Hard center-locked Y-sort.
# Interact via E/Space when player in range. Cost: 3 rice_grain + 15 stamina.
# On repair: GameData.repair_infrastructure("sluice_gate"), add 2 seed_pandan, +5 harmony.
# Unlocks CropData with required_infrastructure="sluice_gate" (pandan, lotus_root).
# Visual: 48x72 sluice_gate_tall.png, broken = dark modulate, repaired = normal + glow.
# Signal: SignalBus.infrastructure_repaired -> dialogue.

@export var structure_id: String = "sluice_gate"
@export var repair_cost_rice: int = 3
@export var repair_cost_stamina: float = 15.0
@export var reward_seeds: int = 2
@export var reward_harmony: int = 5

var _player_in_range: bool = false

@onready var _sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var _prompt: Label = $PromptLabel if has_node("PromptLabel") else null
@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null

func _ready() -> void:
	add_to_group("sluice_gate")
	if _area:
		_area.body_entered.connect(_on_body_entered)
		_area.body_exited.connect(_on_body_exited)
	_update_visual()
	# react to external repair (e.g., loaded save)
	SignalBus.infrastructure_repaired.connect(_on_infra_repaired)
	if _prompt:
		_prompt.visible = false
		_prompt.text = "Press [E] to repair"

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		_try_repair()
		get_viewport().set_input_as_handled()

func _try_repair() -> bool:
	if GameData.is_repaired(structure_id):
		SignalBus.show_dialogue.emit("Sluice Gate", "The sluice gate is already flowing. Pandan seeds are unlocked.")
		return false
	if GameData.current_stamina < repair_cost_stamina:
		SignalBus.show_dialogue.emit("Sluice Gate", "Too tired to repair. Need %.0f stamina." % repair_cost_stamina)
		return false
	if not GameData.has_item("rice_grain", repair_cost_rice):
		SignalBus.show_dialogue.emit("Sluice Gate", "Need %d rice grain to barter for repair materials." % repair_cost_rice)
		return false
	# deduct
	if not GameData.remove_item("rice_grain", repair_cost_rice):
		return false
	GameData.current_stamina -= repair_cost_stamina
	GameData.repair_infrastructure(structure_id)
	GameData.add_item("seed_pandan", reward_seeds)
	GameData.add_harmony(reward_harmony)
	SignalBus.show_dialogue.emit("Sluice Gate", "Repaired! Canal flows again. +%d pandan seeds, +%d harmony." % [reward_seeds, reward_harmony])
	_update_visual()
	_update_prompt()
	return true

func _update_visual() -> void:
	if _sprite == null:
		return
	var repaired := GameData.is_repaired(structure_id)
	if repaired:
		_sprite.modulate = Color(1, 1, 1, 1)
		# subtle repaired hint: slightly brighter
		_sprite.material = null
	else:
		# broken: desaturated + darker (Thai rural weathered wood)
		_sprite.modulate = Color(0.65, 0.6, 0.58, 1)

func _update_prompt() -> void:
	if _prompt == null:
		return
	if not _player_in_range:
		_prompt.visible = false
		return
	if GameData.is_repaired(structure_id):
		_prompt.text = "Sluice gate flowing — pandan unlocked"
		_prompt.visible = true
	else:
		var can := GameData.has_item("rice_grain", repair_cost_rice) and GameData.current_stamina >= repair_cost_stamina
		_prompt.text = "Press [E] to repair (%d rice, %.0f stamina)" % [repair_cost_rice, repair_cost_stamina] if can else "Need %d rice grain + %.0f stamina" % [repair_cost_rice, repair_cost_stamina]
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
