extends Camera2D

@export var move_speed: float = 0.1
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.7
@export var max_zoom: float = 1
@export var margin: Vector2 = Vector2(300, 150)
@export var targets: Array[Node2D] = []

func remove_target(t: Node2D) -> void:
	if t in targets:
		targets.erase(t)

func _process(_delta: float) -> void:
	if targets.is_empty():
		return

	# Mittelpunkt aller Ziele
	var avg_pos: Vector2 = Vector2.ZERO
	for t in targets:
		avg_pos += t.global_position
	avg_pos /= targets.size()
	global_position = global_position.lerp(avg_pos, move_speed)

	# Rechteck um alle Ziele
	var rect: Rect2 = Rect2(avg_pos, Vector2.ONE)
	for t in targets:
		rect = rect.expand(t.global_position)
	rect = rect.grow_individual(margin.x, margin.y, margin.x, margin.y)

	var width: float = rect.size.x
	var height: float = rect.size.y
	var aspect: float = get_viewport_rect().size.aspect()

	if width / height > aspect:
		height = width / aspect
	else:
		width = height * aspect

	
	var screen_size: Vector2 = get_viewport_rect().size
	var zoom_x: float = screen_size.x / width
	var zoom_y: float = screen_size.y / height
	var target_zoom_val: float = min(zoom_x, zoom_y)

	
	target_zoom_val = clampf(target_zoom_val, 1.0 / max_zoom, 1.0 / min_zoom)

	var target_zoom: Vector2 = Vector2.ONE * target_zoom_val
	zoom = zoom.lerp(target_zoom, zoom_speed)
