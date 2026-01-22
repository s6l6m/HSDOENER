extends ItemEntity
class_name IngredientEntity

@export var ingredient: Ingredient
@export var is_prepared: bool = false

@onready var sprite: Sprite2D = $Sprite2D

## Zeitpunkt, wann die Zutat genommen wurde (für Frische-Berechnung)
var creation_time: int = 0
## Dauer in Sekunden, bis die Zutat verdorben ist (nur für Gemüse, also nicht für Brot / Fleisch)
@export var freshness_duration: float = 120.0  

func _ready() -> void:
	if ingredient and not data:
		data = ingredient
	is_prepared = _resolve_start_prepared()
	## Speichere Entstehungszeit für Frische-Berechnung
	creation_time = Time.get_ticks_msec()  # Speichere Entstehungszeit
	print("[IngredientEntity] Erstellt: ", ingredient.name if ingredient else "Unbekannt", " at time: ", creation_time)
	_update_visual()

func _resolve_start_prepared() -> bool:
	if is_prepared:
		return true
	if ingredient:
		return ingredient.is_prepared
	return false

func requires_preparation() -> bool:
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

# Prüft, ob es sich um Gemüse handelt
func is_vegetable() -> bool:
	if not ingredient:
		return false
	var veg_ids := ["tomate", "gurke", "salat", "zwiebel"]
	return ingredient.item_id in veg_ids
