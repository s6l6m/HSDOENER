@tool
extends WorkStation
class_name TrashStation

func update_direction() -> void:
	return

func interact(player: Player):
	var item := player.drop_item()
	if item:
		item.queue_free()
