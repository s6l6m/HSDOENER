@tool
extends WorkStation
class_name PlateStation

var plate_item := preload("res://scenes/orders/plate.tres")

func interact(player):
	# Wenn der Player schon was hält, abgeben nicht möglich
	if player.isHoldingPickable():
		return
	print("Picking up plate")

	# Neue Teller-Instanz erzeugen
	var plate: Plate = plate_item.duplicate(true)

	# Player bekommt das Ingredient
	player.pickUpPickable(plate)
