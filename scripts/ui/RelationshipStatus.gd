extends CanvasLayer
## RelationshipStatus — TASK-381 romance-candidate status overlay.
## Opened by pressing "view_relationship" near a RomanceNPC (see
## RomanceNPC.gd / SignalBus.show_relationship_status). Shows affinity
## hearts (GameData.level_for), loved/liked gifts (DialogueDB.
## GIFT_PREFERENCES), married status, and a larger avatar image once one
## exists for that candidate (gracefully hidden until then, same
## ResourceLoader.exists() convention as the dialogue portrait).

const DialogueDBScript: GDScript = preload("res://scripts/narrative/DialogueDB.gd")
const AVATAR_DIR: String = "res://assets/ui/avatars/"

const FAMILY_INFO: Dictionary = {
	"fah": {"name": "Charoen", "relation": "father"},
	"ploy": {"name": "Somsri", "relation": "mother"},
	"ek": {"name": "Gaew", "relation": "sister"},
	"klong": {"name": "Boonchu", "relation": "grandfather"},
	"yaa": {"name": "Ampai", "relation": "mother"},
	"chang": {"name": "Somchai", "relation": "mentor"},
}

@onready var _avatar: TextureRect = $Panel/VBox/Avatar
@onready var _name_label: Label = $Panel/VBox/NameLabel
@onready var _hearts_label: Label = $Panel/VBox/HeartsLabel
@onready var _loved_label: Label = $Panel/VBox/LovedLabel
@onready var _liked_label: Label = $Panel/VBox/LikedLabel
@onready var _family_label: Label = $Panel/VBox/FamilyLabel
@onready var _birthday_label: Label = $Panel/VBox/BirthdayLabel
@onready var _married_label: Label = $Panel/VBox/MarriedLabel
@onready var _close_button: Button = $Panel/VBox/CloseButton

var _npc_id: String = ""

func _ready() -> void:
	visible = false
	_close_button.pressed.connect(close)

func open(npc_id: String, display_name: String) -> void:
	_npc_id = npc_id
	_name_label.text = display_name

	var avatar_path: String = AVATAR_DIR + npc_id + "_avatar.png"
	if ResourceLoader.exists(avatar_path):
		_avatar.texture = load(avatar_path) as Texture2D
		_avatar.visible = true
	else:
		_avatar.visible = false

	var level: int = GameData.level_for(int(GameData.affinity.get(npc_id, 0)))
	_hearts_label.text = "%d / 10 hearts" % level

	var prefs: Dictionary = DialogueDBScript.GIFT_PREFERENCES.get(npc_id, {})
	_loved_label.text = "Loves: %s" % _format_items(prefs.get("loved", []))
	_liked_label.text = "Likes: %s" % _format_items(prefs.get("liked", []))

	if FAMILY_INFO.has(npc_id):
		var info: Dictionary = FAMILY_INFO[npc_id]
		_family_label.text = "Family: %s (%s)" % [info["name"], info["relation"]]
	else:
		_family_label.text = "Family: ?"

	# TASK-388: primary in-game birthday discovery path — every candidate
	# with an NPC_BIRTHDAYS entry shows her date; anyone without one
	# (family/flavor NPCs, if ever opened here) hides the label instead
	# of showing a placeholder.
	if DialogueDBScript.NPC_BIRTHDAYS.has(npc_id):
		var bday: Dictionary = DialogueDBScript.NPC_BIRTHDAYS[npc_id]
		_birthday_label.text = "Birthday: %s, day %d" % [String(bday["season"]).capitalize(), int(bday["day"])]
		_birthday_label.visible = true
	else:
		_birthday_label.visible = false

	_married_label.visible = (GameData.spouse == npc_id)
	visible = true

func close() -> void:
	visible = false

func _format_items(items: Array) -> String:
	if items.is_empty():
		return "?"
	var parts: PackedStringArray = []
	for item in items:
		parts.append(String(item).replace("_", " "))
	return ", ".join(parts)
