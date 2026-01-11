extends TextureButton

var character_data: CharacterData

func setup(character: CharacterData) -> void:
	character_data = character
	texture_normal = character.portrait
	tooltip_text = character.display_name

func _on_mouse_entered() -> void:
	modulate = Color(1.2, 1.2, 1.2)

func _on_mouse_exited() -> void:
	modulate = Color.WHITE
