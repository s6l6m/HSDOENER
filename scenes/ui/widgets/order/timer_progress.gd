extends TextureProgressBar

@export var green_threshold: float = 60.0
@export var yellow_threshold: float = 30.0

func update_progress(time_left: float, total_time: float) -> void:
	var progress = clamp((time_left / total_time) * 100.0, 0, 100)
	value = progress

	if progress > green_threshold:
		tint_progress = Color(0, 255, 0)
	elif progress > yellow_threshold:
		tint_progress = Color(255, 255, 0.0)
	else:
		tint_progress = Color(255, 0, 0)
