extends Camera2D
class_name MultiTargetCamera

@export var move_speed: float = 1.0
@export var targets: Array[Node2D] = []

func _physics_process(_delta: float) -> void:
	if targets.is_empty():
		return

	var center := Vector2.ZERO
	for t in targets:
		center += t.global_position
	center /= float(targets.size())
	global_position = center.round()
