@tool
extends WorkStation
class_name BreadStation

var bread_resource = load("res://scenes/ingredients/brot.tres")

func interact(player: Player):
	var bread: Ingredient = bread_resource.duplicate(true)
	player.pickUpPickable(bread)
