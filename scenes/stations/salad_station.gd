@tool
extends WorkStation
class_name SaladStation

var salad_resource := preload("res://scenes/ingredients/salat.tres")

func interact(player):
	# Wenn der Player schon was hält, abgeben nicht möglich
	if player.isHoldingPickable():
		return

	# Neue Gurken-Instanz erzeugen
	var salad: Ingredient = salad_resource.duplicate(true)

	# Player bekommt das Ingredient
	player.pickUpIngredient(salad)
