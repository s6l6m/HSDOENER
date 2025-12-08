@tool
extends WorkStation
class_name CucumberStation

var cucumber_resource := preload("res://scenes/ingredients/gurke.tres")

func interact(player):
	# Wenn der Player schon was hält, abgeben nicht möglich
	if player.isHoldingPickable():
		return

	# Neue Gurken-Instanz erzeugen
	var cucumber: Ingredient = cucumber_resource.duplicate(true)

	# Player bekommt das Ingredient
	player.pickUpPickable(cucumber)
