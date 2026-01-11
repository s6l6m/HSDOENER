@tool
extends WorkStation
class_name TrashStation

# =====================================================
# Helpers
# =====================================================
func update_direction() -> void:
	return

# =====================================================
# Interaction
# =====================================================
func interact(player: Player):
	var item := player.drop_item()
	if item:
		AudioPlayerManager.play(AudioPlayerManager.AudioID.STATION_TRASH)
		item.queue_free()
