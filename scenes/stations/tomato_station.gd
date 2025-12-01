@tool
extends WorkStation
class_name TomatoStation

var item = load("res://assets/food/items/tomato-item.png")

func interact(player: Player):
	player.pickUp(item)
