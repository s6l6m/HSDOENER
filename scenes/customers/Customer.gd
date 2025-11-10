extends CharacterBody2D

signal customer_left(customer)

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
