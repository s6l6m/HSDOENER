@tool
extends TextureButton
class_name CharacterButton

@onready var background: ColorRect = get_node("Background")
@onready var portrait: TextureRect = get_node("Portrait")

var character_data: CharacterData

@export var p1_focus_color := Color(0.3, 0.6, 1.0, 0.35)
@export var p2_focus_color := Color(1.0, 0.3, 0.3, 0.35)
@export var mouse_focus_color := Color(1.1, 1.1, 1.1, 0.15)

var p1_focused := false
var p2_focused := false
var mouse_focused := false

func setup(character: CharacterData) -> void:
	character_data = character
	var portrait_node = get_node("Portrait")
	assert(portrait_node)
	portrait_node.texture = character.portrait

func set_player_focus(player: Player.PlayerNumber, enabled: bool) -> void:
	match player:
		Player.PlayerNumber.ONE:
			p1_focused = enabled
		Player.PlayerNumber.TWO:
			p2_focused = enabled
	_update_background()

func _on_mouse_entered() -> void:
	if not p1_focused and not p2_focused:
		mouse_focused = true
		_update_background()

func _on_mouse_exited() -> void:
	mouse_focused = false
	_update_background()

func _update_background() -> void:
	var color_to_use: Color = Color.TRANSPARENT
	var show_background: bool = false

	if p1_focused and p2_focused:
		color_to_use = p1_focus_color.lerp(p2_focus_color, 0.5)
		show_background = true
	elif p1_focused:
		color_to_use = p1_focus_color
		show_background = true
	elif p2_focused:
		color_to_use = p2_focus_color
		show_background = true
	elif mouse_focused:
		color_to_use = mouse_focus_color
		show_background = true

	background.visible = show_background
	if show_background:
		background.color = color_to_use
