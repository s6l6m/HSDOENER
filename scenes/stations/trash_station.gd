@tool
extends WorkStation
class_name TrashStation

func update_direction() -> void:
	return

func interact(player: Player):
	player.dropPickable()
