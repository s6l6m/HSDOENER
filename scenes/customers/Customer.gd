extends CharacterBody2D
class_name Customer

signal customer_left(customer)
signal customer_arrived_exit(customer)

@export var speed: float = 100.0
var target_position: Vector2
var is_moving = false
var order: Order
var color: Color

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

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
		
		# Animation basierend auf Bewegungsrichtung aktualisieren
		_update_animation(direction)
		
		if global_position.distance_to(target_position) < 5:
			is_moving = false
			velocity = Vector2.ZERO
			# Idle-Animation wenn angekommen
			if animated_sprite:
				animated_sprite.play("idle")

			# Wenn Kunde sein Ziel erreicht hat (z. B. Exit)
			var exit_pos = get_parent().get_node(get_parent().exit_point).global_position
			if target_position == exit_pos:
				customer_arrived_exit.emit(self)
	else:
		# Idle-Animation wenn nicht bewegt
		if animated_sprite and animated_sprite.animation != "idle":
			animated_sprite.play("idle")

func fillFulfilledIngredients(ingredients: Array[Ingredient]) -> void:
	if order == null:
		push_warning("Customer has no order assigned in fillFulfilledIngredients()")
		return

	# neue Liste setzen (Kopie, nicht Referenz übernehmen)
	order.fulfilled_ingredients = ingredients.duplicate()
	

# Animation basierend auf Bewegungsrichtung aktualisieren
func _update_animation(direction: Vector2) -> void:
	if not animated_sprite:
		return
	
	if direction == Vector2.ZERO:
		animated_sprite.play("idle")
		return
	
	# Winkel in Grad umrechnen (0° = rechts, 90° = unten, -90° = oben, 180° = links)
	var degrees = rad_to_deg(direction.normalized().angle())
	
	var animation_name: String
	if degrees >= -45.0 and degrees < 45.0:
		animation_name = "run_right"
	elif degrees >= 45.0 and degrees < 135.0:
		animation_name = "run_down"
	elif degrees >= 135.0 or degrees < -135.0:
		animation_name = "run_left"
	else:  # degrees >= -135.0 and degrees < -45.0
		animation_name = "run_up"
	
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)

func leave_queue() -> void:
	customer_left.emit(self)
