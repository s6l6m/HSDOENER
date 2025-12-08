@tool
extends WorkStation
class_name TrashStation

func update_direction() -> void:
	return

func interact(player: Player):
	var held = player.getHeldPickable()
	if held != null:
		player.dropPickable()
