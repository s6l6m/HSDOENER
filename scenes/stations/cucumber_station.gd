@tool
extends WorkStation
class_name CucumberStation

var cucumber_resource := preload("res://scenes/ingredients/gurke.tres")

func interact(player: Player):
	var cucumber: Ingredient = cucumber_resource.duplicate(true)
	player.pickUpPickable(cucumber)
