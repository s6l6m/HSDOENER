extends CharacterBody2D

@export var speed = 150
@export var player_number = 1

var facing_dir = Vector2.DOWN
var velocity_target = Vector2.ZERO

var current_station: WorkStation = null
var stations_in_range: Array = []

@onready var sprite = $AnimatedSprite2D
@onready var interaction_icon = $InteractIcon
@onready var heldItem = $HeldItem

func _ready():
	add_to_group("players")
	if player_number == 1:
		interaction_icon.texture = load("res://assets/ui/interact_button_p1.png")
	else:
		interaction_icon.texture = load("res://assets/ui/interact_button_p2.png")

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
		if Input.is_action_just_pressed("interact_p1"):
			if(current_station):
				current_station.interact(self)
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
		if Input.is_action_just_pressed("interact_p2"):
			if(current_station):
				current_station.interact(self)

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

func enter_station(station: WorkStation):
	stations_in_range.append(station)
	_update_current_station()
	$InteractIcon.visible = true

func exit_station(station: WorkStation):
	stations_in_range.erase(station)
	_update_current_station()

func _update_current_station():
	if stations_in_range.is_empty():
		current_station = null
		interaction_icon.visible = false
	else:
		current_station = stations_in_range.back()

func pickUp(item):
	if(heldItem.texture == null):
		heldItem.texture = item
		heldItem.visible = true
		return true
	else:
		print("Already holding an item")
		return false

func layDown():
	if(heldItem.texture != null):
		var item = heldItem.texture
		heldItem.texture = null
		heldItem.visible = false
		return item
	else:
		print("Not holding an item")
		return false
