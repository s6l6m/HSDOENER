@tool
extends PanelContainer

@export var icon: Texture
@onready var icon_rect: TextureRect = %IngredientIcon

func _ready() -> void:
	if icon and icon_rect:
		icon_rect.texture = icon
