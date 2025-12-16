@tool
extends PanelContainer
class_name IngredientScene

@export var icon: Texture
@onready var icon_rect: TextureRect = %IngredientIcon

func _ready() -> void:
	if icon and icon_rect:
		icon_rect.texture = icon
