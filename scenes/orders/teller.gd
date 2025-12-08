class_name Teller
extends PickableResource

var ingredients: Array[Ingredient] = []

func addIngredient(_newIngredient: Ingredient):
	if(ingredients.size() != 0):
		ingredients.append(_newIngredient)
	elif(_newIngredient.name == "Brot"):
		ingredients.append(_newIngredient)
