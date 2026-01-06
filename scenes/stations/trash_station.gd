@tool
extends WorkStation
class_name TrashStation

func update_direction() -> void:
	return

func interact(player: Player):
	var item := player.drop_item()
	if item:
		AudioPlayerManager.play(AudioPlayerManager.AudioID.STATION_TRASH)
		item.queue_free()
