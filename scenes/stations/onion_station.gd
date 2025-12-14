@tool
extends WorkStation
class_name OnionStation

var onion_resource := preload("res://scenes/ingredients/zwiebel.tres")

func interact(player: Player):
	var onion: Ingredient = onion_resource.duplicate(true)
	player.pickUpPickable(onion)
