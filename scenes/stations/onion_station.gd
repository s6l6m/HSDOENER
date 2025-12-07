@tool
extends WorkStation
class_name OnionStation

var onion_resource := preload("res://scenes/ingredients/zwiebel.tres")

func interact(player):
	# Wenn der Player schon was hält, abgeben nicht möglich
	if player.isHoldingPickable():
		return

	# Neue Gurken-Instanz erzeugen
	var onion: Ingredient = onion_resource.duplicate(true)

	# Player bekommt das Ingredient
	player.pickUpPickable(onion)
