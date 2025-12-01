@tool
extends WorkStation
class_name CucumberStation

var item = load("res://assets/food/items/cucumber-item.png")

func interact(player: Player):
	player.pickUp(item)
