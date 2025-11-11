extends CharacterBody2D

@export var speed = 150
@export var player_number = 1

var facing_dir = Vector2.DOWN
var velocity_target = Vector2.ZERO

@onready var sprite = $AnimatedSprite2D

func _physics_process(delta):
	var direction = Vector2.ZERO

	# Steuerung für Player 1
	if player_number == 1:
		if Input.is_action_pressed("move_right_p1"):
			direction.x += 1
		if Input.is_action_pressed("move_left_p1"):
			direction.x -= 1
		if Input.is_action_pressed("move_down_p1"):
			direction.y += 1
		if Input.is_action_pressed("move_up_p1"):
			direction.y -= 1
	# Steuerung für Player 2
	elif player_number == 2:
		if Input.is_action_pressed("move_right_p2"):
			direction.x += 1
		if Input.is_action_pressed("move_left_p2"):
			direction.x -= 1
		if Input.is_action_pressed("move_down_p2"):
			direction.y += 1
		if Input.is_action_pressed("move_up_p2"):
			direction.y -= 1

	# Richtung merken
	if direction != Vector2.ZERO:
		facing_dir = direction.normalized()

	# Sanfte Bewegung
	var accel = 15.0
	var friction = 10.0

	var target_velocity = direction.normalized() * speed
	velocity = velocity.lerp(target_velocity, (accel if direction != Vector2.ZERO else friction) * delta)


	move_and_slide()
	
	# Animation steuern
	if direction != Vector2.ZERO:
		if not sprite.is_playing() or sprite.animation != "run_right":
			sprite.play("run_right")
		sprite.flip_h = direction.x < 0
	else:
		if sprite.is_playing():
			sprite.play("idle")
