extends ItemEntity
class_name IngredientEntity

## IngredientEntity is the world instance; `ingredient` is the shared Ingredient data resource.
## Runtime state like "prepared/cut" is stored here (not inside the Ingredient resource).
@export var ingredient: Ingredient
@export var is_prepared: bool = false

@onready var sprite: Sprite2D = $Sprite2D

# Freshness variables
var creation_time: int = 0  # Zeit in Millisekunden, wenn genommen
@export var freshness_duration: float = 120.0  # Sekunden, bis verdorben (für Gemüse)

func _ready() -> void:
	if ingredient and not data:
		data = ingredient
	is_prepared = _resolve_start_prepared()
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

# Gibt die Frische zurück (0 = verdorben, 1 = frisch). Nur für Gemüse.
func get_freshness() -> float:
	if not is_vegetable():
		print("[IngredientEntity] ", ingredient.name if ingredient else "Unbekannt", " ist kein Gemüse, Frische: 1.0")
		return 1.0  # Brot und Fleisch haben immer volle Frische
	
	var elapsed_sec := (Time.get_ticks_msec() - creation_time) / 1000.0
	var freshness: float = clamp(1.0 - (elapsed_sec / freshness_duration), 0.0, 1.0)
	print("[IngredientEntity] ", ingredient.name, " Frische berechnet: elapsed=", elapsed_sec, "s, freshness=", freshness)
	return freshness

# Prüft, ob es sich um Gemüse handelt
func is_vegetable() -> bool:
	if not ingredient:
		return false
	var veg_ids := ["tomate", "gurke", "salat", "zwiebel"]
	return ingredient.item_id in veg_ids
