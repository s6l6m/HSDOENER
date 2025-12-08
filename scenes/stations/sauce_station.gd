@tool
extends WorkStation
class_name SauceStation

func interact(player):
	if(not player.isHoldingOrder()):
		print("Du brauchst einen Teller!")

func interact_b(player):
	if(not player.isHoldingOrder()):
		print("Du brauchst einen Teller!")
