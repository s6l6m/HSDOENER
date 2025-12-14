@tool
extends WorkStation
class_name TomatoStation

var tomato_resource := preload("res://scenes/ingredients/tomate.tres")

func interact(player: Player):
	var tomato: Ingredient = tomato_resource.duplicate(true)
	player.pickUpPickable(tomato)
