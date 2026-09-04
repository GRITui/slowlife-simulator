extends Node2D
## FarmHouseBedStylePicker — TASK-367 farmhouse decor anchor-slots.
## A small sibling interactable that sits next to the existing
## FarmHouseBed and lets the player cycle through the bed's
## currently-owned styles. Each press of `interact` advances one slot
## in `GameData.owned_decor_styles("bed")` and calls
## `GameData.set_decor_choice("bed", next_style)`. On success the
## new style name is announced via SignalBus.show_dialogue and the
## SignalBus.decor_style_changed signal fires so any area's bed
## sprite can re-skin itself.
##
## Deliberately NOT a full picker UI: a single interact-to-cycle is the
## right scope for TASK-367 (following TASK-360's pattern). The list
## it cycles over is `owned_decor_styles()`, so unowned styles are
## silently absent — the player cannot reach them without first buying
## the matching blueprint at the market.
##
## Same InteractArea + `interact` action convention as
## FarmHouseShrineStylePicker.gd. The
## style picker's own Sprite2D is intentionally tiny/invisible — the
## "decor" lives on the adjacent FarmHouseBed node (FarmHouse.gd
## drives its texture from GameData.decor_choice()).

const SLOT: String = "bed"

var _player_in_range: bool = false
var _owned_styles: Array[String] = []
var _cycle_index: int = 0

@onready var _area: Area2D = $InteractArea if has_node("InteractArea") else null
@onready var _prompt: Label = $PromptLabel if has_node("PromptLabel") else null

func _ready() -> void:
	add_to_group("farmhouse_decor_picker")
	if _area:
		_area.body_entered.connect(_on_body_entered)
		_area.body_exited.connect(_on_body_exited)
	# React to inventory changes (purchasing a new blueprint elsewhere
	# should expand the cycle list immediately, not only on the next
	# scene reload). Cozy pacing: one re-read per signal, no timers.
	SignalBus.craft_completed.connect(_on_inventory_changed)
	SignalBus.barter_completed.connect(_on_inventory_changed_any)
	_refresh_owned_styles()
	if _prompt:
		_prompt.visible = false
		_prompt.text = "Press [E] to change bed style"

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		_cycle_style()
		get_viewport().set_input_as_handled()

func _cycle_style() -> void:
	# Re-read the owned list every press — a blueprint bought since the
	# last cycle shouldn't be skipped just because _cycle_index points
	# at the old tail.
	_refresh_owned_styles()
	if _owned_styles.is_empty():
		SignalBus.show_dialogue.emit("Farmer", "The bed sits quietly.")
		return
	_cycle_index = (_cycle_index + 1) % _owned_styles.size()
	var next_style: String = _owned_styles[_cycle_index]
	if not GameData.set_decor_choice(SLOT, next_style):
		# Catalogue/ownership mismatch is impossible from owned_decor_styles
		# but guard anyway — never crash on a UI edge case.
		SignalBus.show_dialogue.emit("Farmer", "That style isn't available right now.")
		return
	SignalBus.show_dialogue.emit("Farmer", "Bed style: %s." % _style_label(next_style))
	SignalBus.decor_style_changed.emit(SLOT, next_style)

func _style_label(style: String) -> String:
	# Pretty-print the style id ("basic" -> "basic wood", "ornate" -> "ornate")
	# for the dialogue line. Keep the catalogue as the source of truth for
	# ids; this only formats them.
	if style == "basic":
		return "basic wood"
	if style == "ornate":
		return "ornate cloth"
	return style

func _refresh_owned_styles() -> void:
	_owned_styles = GameData.owned_decor_styles(SLOT)
	# Keep _cycle_index valid even if the cycle list shrank (player spent
	# the last owned blueprint somehow, or a save reload changed state).
	if _owned_styles.is_empty():
		_cycle_index = 0
		return
	var current: String = GameData.decor_choice(SLOT)
	var found: int = _owned_styles.find(current)
	if found >= 0:
		_cycle_index = found
	else:
		# Current choice is no longer in the owned set (defensive — would
		# require set_decor_choice() to have accepted something the player
		# no longer owns, which the API forbids, but be safe).
		_cycle_index = 0

func _on_inventory_changed(_item_id: String, _qty: int) -> void:
	_refresh_owned_styles()

func _on_inventory_changed_any(_have_id: String, _want_id: String) -> void:
	# Barter doesn't actually grant decor blueprints, but cheap to wire
	# so the cycle list self-heals after any inventory mutation.
	_refresh_owned_styles()

func _on_body_entered(body: Node) -> void:
	if body == self:
		return
	if body.is_in_group("player") or body.name == "Player" or body is CharacterBody2D:
		_player_in_range = true
		if _prompt:
			_prompt.visible = true

func _on_body_exited(body: Node) -> void:
	if body == self:
		return
	if body.is_in_group("player") or body.name == "Player" or body is CharacterBody2D:
		_player_in_range = false
		if _prompt:
			_prompt.visible = false