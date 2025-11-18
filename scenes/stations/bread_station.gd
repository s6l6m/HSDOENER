@tool
extends WorkStation
class_name BreadStation

var item = load("res://assets/food/items/bread-item.png")

func interact(player):
	player.pickUp(item)
