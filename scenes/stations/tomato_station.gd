@tool
extends WorkStation
class_name TomatoStation

var tomato_resource := preload("res://scenes/ingredients/tomate.tres")

func interact(player):
	# Wenn der Player schon was hält, abgeben nicht möglich
	if player.isHoldingPickable():
		return

	# Neue Gurken-Instanz erzeugen
	var tomato: Ingredient = tomato_resource.duplicate(true)

	# Player bekommt das Ingredient
	player.pickUpPickable(tomato)
