extends Camera2D
class_name MultiTargetCamera

@export var move_speed = 1  # camera position lerp speed
@export var zoom_speed = 0.5  # camera zoom lerp speed
@export var min_zoom = 1.5  # camera won't zoom closer than this
@export var max_zoom = 5  # camera won't zoom farther than this
@export var margin = Vector2(400, 200)  # include some buffer area around targets

@export var targets: Array[Node2D] = []  # Array of targets to be tracked.

@export_category("Camera Smoothing")
@export var smoothing_enabled : bool
@export_range(1, 10) var smoothing_distance : int = 5
@onready var weight: float = float(11 - smoothing_distance) / 100

func _physics_process(_delta):
	if targets.is_empty():
		return

	# --- 1. Compute center point ---
	var p := Vector2.ZERO
	for t in targets:
		p += t.global_position
	p /= targets.size()

	# target camera position = exact center
	var desired_pos = p

	# --- 2. Smooth movement (if enabled) ---
	var new_pos: Vector2
	if smoothing_enabled:
		new_pos = global_position.lerp(desired_pos, weight)
	else:
		new_pos = desired_pos

	# --- 3. Pixel snap (only at final step) ---
	global_position = new_pos.round()

	# --- 4. Zoom logic (unchanged) ---
	var first := targets[0].global_position
	var r := Rect2(first, Vector2.ZERO)
	for t in targets:
		r = r.expand(t.global_position)
	r = r.grow_individual(margin.x, margin.y, margin.x, margin.y)

	var screen_size := get_viewport_rect().size
	var width_factor := r.size.x / screen_size.x
	var height_factor := r.size.y / screen_size.y
	var z: float = max(width_factor, height_factor)
	z = clamp(z, min_zoom, max_zoom)

	zoom = zoom.lerp(Vector2(z, z), zoom_speed)

func add_target(t):
	if not t in targets:
		targets.append(t)

func remove_target(t):
	if t in targets:
		targets.erase(t)
