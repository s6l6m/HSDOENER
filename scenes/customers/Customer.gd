extends CharacterBody2D

signal customer_left(customer)
signal customer_arrived_exit(customer)

@export var speed: float = 100.0
var target_position: Vector2
var is_moving = false

func move_to(pos: Vector2):
	target_position = pos
	is_moving = true

func _process(delta):
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
				emit_signal("customer_arrived_exit", self)


# Wird aufgerufen, wenn auf den Kunden geklickt wird
func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("customer_left", self)
