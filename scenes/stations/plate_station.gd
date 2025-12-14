@tool
extends WorkStation
class_name PlateStation

var plate_item := preload("res://scenes/orders/plate.tres")

func interact(player: Player):
	var plate: Plate = plate_item.duplicate(true)
	player.pickUpPickable(plate)
