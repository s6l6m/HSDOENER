class_name Order
extends Resource

@export var icon: Texture2D
@export var required_ingredients: Array[Ingredient] = []
@export var fulfilled_ingredients: Array[Ingredient] = []
@export var creation_time: int = 0
@export var price: float = 0.0
@export var time_limit: int = 0

var customer: Customer

signal is_complete(order: Order)

func _init(_icon: Texture2D = null, _required_ingredients: Array[Ingredient] = [], _price: float = 0.0, _creation_time: int = 0, _time_limit: int = 0):
	icon = _icon
	required_ingredients = _required_ingredients
	price = _price
	creation_time = creation_time
	time_limit = _time_limit

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

	if _evaluate_is_complete():
		emit_signal("is_complete", self)

	print("ingredient success")
	return true

func _evaluate_is_complete() -> float:
	if fulfilled_ingredients.size() != required_ingredients.size():
		return 0

	for ing in required_ingredients:
		if _count(fulfilled_ingredients, ing) < _count(required_ingredients, ing):
			return 0

	return 1

func _count(arr: Array, item) -> int:
	var c := 0
	for a in arr:
		if a == item:
			c += 1
	return c
	
func _evaluate_freshness():
	#TODO
	return 1
	
func _evaluate_time_left(current_time: int) -> float:
	var elapsed: int = current_time - self.creation_time
	
	#normalisieren
	return 1.0 - clamp(float(elapsed) / self.time_limit, 0.0, 1.0)
