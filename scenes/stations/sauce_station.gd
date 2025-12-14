@tool
extends WorkStation
class_name SauceStation

func interact(player: Player):
	if not player.isHoldingPlate():
		print("Du brauchst einen Teller!")

func interact_b(player: Player):
	if not player.isHoldingPlate():
		print("Du brauchst einen Teller!")
