extends CharacterBody2D
class_name Customer

signal customer_left(customer)
signal customer_arrived_exit(customer)

@export var speed: float = 100.0
var target_position: Vector2
var is_moving = false
var order: Order
var color: Color

func _ready() -> void:
	add_to_group("customers")
	if not color:
		color = _generate_random_rgb_color()

func _generate_random_rgb_color() -> Color:
	return Color(
		randf(), # RED
		randf(), # GREEN
		randf(), # BLUE
	)

func move_to(pos: Vector2):
	target_position = pos
	is_moving = true

func _process(_delta):
	if is_moving:
		var direction = (target_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		
		if global_position.distance_to(target_position) < 5:
			is_moving = false
			velocity = Vector2.ZERO

			# Wenn Kunde sein Ziel erreicht hat (z. B. Exit)
			var exit_pos = get_parent().get_node(get_parent().exit_point).global_position
			if target_position == exit_pos:
				customer_arrived_exit.emit(self)

func leave_queue() -> void:
	customer_left.emit(self)
