class_name Plate
extends PickableResource

var ingredients: Array[Ingredient] = []

func addIngredient(_newIngredient: Ingredient) -> bool:
	var breadIncluded = isBreadIncluded()
	if _newIngredient.name == "Brot":
		if breadIncluded:
			return false
		ingredients.append(_newIngredient)
		printIngredients()
		return true
	if breadIncluded:
		ingredients.append(_newIngredient)
		printIngredients()
		return true
	return false

func isBreadIncluded() -> bool:
	for i in ingredients:
		if i.name == "Brot":
			return true
	return false

func printIngredients():
	for i in ingredients:
		print(i.name)

func hasIngredients():
	return ingredients.size() > 0
