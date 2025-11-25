class_name Order
extends Resource

@export var icon: Texture2D
@export var required_ingredients: Array[Ingredient] = []
@export var fulfilled_ingredients: Array[Ingredient] = []
@export var price: float = 0.0

var customer: Node = null

signal is_complete(order: Order)

func _init(_icon: Texture2D = null, _required_ingredients: Array[Ingredient] = [], _price: float = 0.0):
	icon = _icon
	required_ingredients = _required_ingredients
	price = _price

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
