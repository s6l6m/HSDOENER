@tool
extends WorkStation
class_name CuttingStation

@onready var food = $Food

func interact(player: Player):
	if(food.visible):
		if(player.pickUp(food.texture)):
			food.visible = false
			food.texture = null
	else:
		var item = player.layDown()
		if(item):
			food.texture = item
			food.visible = true
			print("Laying down item:", player.heldItem)
		else:
			print("Interacting with base station:", self.name)
	# wird von Child-Stationen überschrieben
