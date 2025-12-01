@tool
extends WorkStation
class_name SaladStation

var item = load("res://assets/food/items/salad-item.png")

func interact(player: Player):
	player.pickUp(item)
