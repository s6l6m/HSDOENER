@tool
extends WorkStation
class_name BreadStation

var bread_resource = load("res://scenes/ingredients/brot.tres")

func interact(player):
	# Wenn der Player schon was hält, abgeben nicht möglich
	if player.isHoldingPickable():
		return

	# Neue Brot-Instanz erzeugen
	var bread: Ingredient = bread_resource.duplicate(true)

	# Player bekommt das Ingredient
	player.pickUpPickable(bread)
