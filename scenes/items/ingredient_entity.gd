extends ItemEntity
class_name IngredientEntity

## IngredientEntity is the world instance; `ingredient` is the shared Ingredient data resource.
## Runtime state like "prepared/cut" is stored here (not inside the Ingredient resource).
@export var ingredient: Ingredient
@export var is_prepared: bool = false

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if ingredient and not data:
		data = ingredient
	is_prepared = _resolve_start_prepared()
	_update_visual()

func _resolve_start_prepared() -> bool:
	if is_prepared:
		return true
	if ingredient:
		return ingredient.is_prepared
	return false

func requires_preparation() -> bool:
	## If an ingredient has a cut_icon and is not marked prepared in its data, it requires preparation.
	if ingredient == null:
		return false
	return ingredient.cut_icon != null and not ingredient.is_prepared

func set_prepared(prepared: bool) -> void:
	is_prepared = prepared
	_update_visual()

func _update_visual() -> void:
	if not sprite:
		return
	if ingredient == null:
		sprite.texture = data.icon if data else null
		return
	if is_prepared and ingredient.cut_icon:
		sprite.texture = ingredient.cut_icon
	else:
		sprite.texture = ingredient.icon
