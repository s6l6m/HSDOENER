class_name Order
extends PickableResource

## Order ist ein PickableResource (Resource + Pickable-Funktionalität)
## Kann vom Player gehalten und herumgetragen werden
## Erbt von PickableResource:
##   - Resource-Funktionalität (kann gespeichert werden)
##   - name, icon, description
##   - on_picked_up(), on_dropped()

@export var required_ingredients: Array[Ingredient] = []
@export var fulfilled_ingredients: Array[Ingredient] = []
@export var price: float = 0.0
@export var time_limit: float = 120.0  # Zeit in Sekunden bis Order abläuft

var customer: Customer
var time_remaining: float = 0.0

signal is_complete(order: Order)
signal time_expired(order: Order)

func _init(_icon: Texture2D = null, _required_ingredients: Array[Ingredient] = [], _price: float = 0.0):
	super._init("Order", _icon, "Döner Order")
	required_ingredients = _required_ingredients
	price = _price
	time_remaining = time_limit

func fulfill_ingredient(ingredient: Ingredient) -> bool:
	if ingredient not in required_ingredients:
		print("ingredient not required")
		return false

	var needed := _count(required_ingredients, ingredient)
	var have := _count(fulfilled_ingredients, ingredient)

	if have >= needed:
		print("ingredient is already there")
		return false

	fulfilled_ingredients.append(ingredient)

	if _is_complete():
		emit_signal("is_complete", self)

	print("ingredient success")
	return true

func _is_complete() -> bool:
	if fulfilled_ingredients.size() != required_ingredients.size():
		return false

	for ing in required_ingredients:
		if _count(fulfilled_ingredients, ing) < _count(required_ingredients, ing):
			return false

	return true

func _count(arr: Array, item) -> int:
	var c := 0
	for a in arr:
		if a == item:
			c += 1
	return c
