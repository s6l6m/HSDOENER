@tool
extends WorkStation
class_name OnionStation

var item = load("res://assets/food/items/onion-item.png")

func interact(player: Player):
	player.pickUp(item)
