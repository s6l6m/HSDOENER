extends CharacterBody2D
class_name Customer

## Signal, wenn Kunde die Szene verlässt
signal customer_left(customer)
## Signal, wenn Kunde am Ausgang ankommt
signal customer_arrived_exit(customer)

## Bewegungsgeschwindigkeit des Kunden
@export var speed: float = 100.0
## Zielposition für Bewegung
var target_position: Vector2
## Bool, ob der Kunde sich bewegt
var is_moving = false
## Die Order des Kunden
var order: Order
## Farbe des Kunden für UI
var color: Color

## AnimatedSprite für Animationen
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

## Initialisiert den Kunden und generiert zufällige Farbe
func _ready() -> void:
	add_to_group("customers")
	if not color:
		color = _generate_random_rgb_color()

## Generiert eine zufällige RGB-Farbe
func _generate_random_rgb_color() -> Color:
	return Color(
		randf(), # RED
		randf(), # GREEN
		randf(), # BLUE
	)

## Setzt die SpriteFrames für den Kunden-Skin
func set_skin_frames(frames: SpriteFrames):
	# Wir tauschen das komplette "Gehirn" des AnimatedSprite aus
	$AnimatedSprite2D.sprite_frames = frames
	
	# Jetzt kannst du ganz normal play("idle") aufrufen, 
	# weil in jedem Paket die Animation gleich heißt!
	$AnimatedSprite2D.play("idle")

## Bewegt den Kunden zu einer Zielposition
func move_to(pos: Vector2):
	target_position = pos
	is_moving = true

## Verarbeitet Bewegung und Animation im Frame
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

## Füllt die erfüllten Zutaten in die Order des Kunden
func fillFulfilledIngredients(ingredients: Array[Ingredient]) -> void:
	if order == null:
		push_warning("Customer has no order assigned in fillFulfilledIngredients()")
		return

	# neue Liste setzen (Kopie, nicht Referenz übernehmen)
	order.fulfilled_ingredients = ingredients.duplicate()
	

## Aktualisiert Animation basierend auf Bewegungsrichtung
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
		animation_name = "right"
	elif degrees >= 45.0 and degrees < 135.0:
		animation_name = "down"
	elif degrees >= 135.0 or degrees < -135.0:
		animation_name = "left"
	else:  # degrees >= -135.0 and degrees < -45.0
		animation_name = "up"
	
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)

## Lässt den Kunden die Warteschlange verlassen
func leave_queue() -> void:
	customer_left.emit(self)
