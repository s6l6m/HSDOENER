@tool
extends WorkStation
class_name SaladStation

var salad_resource := preload("res://scenes/ingredients/salat.tres")

func interact(player: Player):
	var salad: Ingredient = salad_resource.duplicate(true)
	player.pickUpPickable(salad)
