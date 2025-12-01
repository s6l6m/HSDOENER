extends CharacterBody2D

# Player States
enum State {
	FREE,           # Freie Bewegung
	CARRYING,       # Trägt ein Item
	INTERACTING,    # Interagiert mit Station
	CUTTING,        # Schneidet an Cutting Station
	DISABLED        # Kann sich nicht bewegen (Tutorial/Cutscene)
}

# Signals für Player-Events (nur was direkt den Player betrifft)
signal state_changed(old_state: State, new_state: State)
signal pickable_picked_up(pickable: PickableResource)
signal pickable_dropped(pickable: PickableResource)

@export var speed: float = 150.0
@export var player_number: int = 1

var facing_dir: Vector2 = Vector2.DOWN
var velocity_target: Vector2 = Vector2.ZERO
var current_state: State = State.FREE

# Station Interaktion
var current_station: WorkStation = null
var stations_in_range: Array[WorkStation] = []

# Was der Player gerade hält (Player State) - PickableResource (Ingredient oder Order)
var held_pickable: PickableResource = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_icon: Sprite2D = $InteractIcon
@onready var heldItem: Sprite2D = $HeldItem

func _ready() -> void:
	add_to_group("players")
	if player_number == 1:
		interaction_icon.texture = load("res://assets/ui/interact_button_p1.png")
	else:
		interaction_icon.texture = load("res://assets/ui/interact_button_p2.png")
	
	set_state(State.FREE)

func _process(_delta):
	if held_pickable != null:
		held_pickable.update_rot(_delta)
		heldItem.modulate = held_pickable.get_icon_tint()
		print(held_pickable.rot_amount)

func _physics_process(delta: float) -> void:
	# Wenn Player DISABLED ist, keine Bewegung erlauben
	if current_state == State.DISABLED:
		return
	
	var direction: Vector2 = Vector2.ZERO

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
			if current_station:
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
			if current_station:
				current_station.interact(self)

	# Richtung merken
	if direction != Vector2.ZERO:
		facing_dir = direction.normalized()

	# Sanfte Bewegung
	var accel: float = 15.0
	var friction: float = 10.0

	var target_velocity: Vector2 = direction.normalized() * speed
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

func enter_station(station: WorkStation) -> void:
	stations_in_range.append(station)
	_update_current_station()
	interaction_icon.visible = true

func exit_station(station: WorkStation) -> void:
	stations_in_range.erase(station)
	_update_current_station()

func _update_current_station() -> void:
	if stations_in_range.is_empty():
		current_station = null
		interaction_icon.visible = false
	else:
		current_station = stations_in_range.back()

# State Machine
func set_state(new_state: State) -> void:
	if current_state == new_state:
		return
	
	var old_state: State = current_state
	current_state = new_state
	emit_signal("state_changed", old_state, new_state)
	print("Player ", player_number, " state: ", State.keys()[old_state], " -> ", State.keys()[new_state])

func get_state() -> State:
	return current_state

func can_move() -> bool:
	return current_state != State.DISABLED

func can_interact() -> bool:
	return current_state == State.FREE or current_state == State.CARRYING

# PickableResource System - vereinheitlicht Ingredients, Orders, etc.
func pickUpPickable(pickable: PickableResource) -> bool:
	if pickable == null:
		print("Cannot pick up null pickable")
		return false
	
	if held_pickable == null:
		held_pickable = pickable
		heldItem.texture = pickable.icon
		heldItem.visible = true
		pickable.on_picked_up()
		emit_signal("pickable_picked_up", pickable)
		set_state(State.CARRYING)
		print("Player ", player_number, " picked up: ", pickable.name)
		return true
	else:
		print("Already holding a pickable: ", held_pickable.name)
		return false

func dropPickable() -> PickableResource:
	if held_pickable != null:
		var pickable: PickableResource = held_pickable
		held_pickable = null
		heldItem.texture = null
		heldItem.visible = false
		pickable.on_dropped()
		emit_signal("pickable_dropped", pickable)
		set_state(State.FREE)
		print("Player ", player_number, " dropped: ", pickable.name)
		return pickable
	else:
		print("Not holding a pickable")
		return null

func getHeldPickable() -> PickableResource:
	return held_pickable

func isHoldingPickable() -> bool:
	return held_pickable != null

# Type-safe Getter für spezifische Typen
func getHeldOrder() -> Order:
	if held_pickable and held_pickable.is_order():
		return held_pickable as Order
	return null

func isHoldingOrder() -> bool:
	return held_pickable != null and held_pickable.is_order()

# Legacy-Funktionen für Backward Compatibility mit bestehenden Stations
func pickUp(item: Texture2D) -> bool:
	if heldItem.texture == null:
		heldItem.texture = item
		heldItem.visible = true
		set_state(State.CARRYING)
		return true
	else:
		print("Already holding an item")
		return false

func layDown() -> Texture2D:
	if heldItem.texture != null:
		var item: Texture2D = heldItem.texture
		heldItem.texture = null
		heldItem.visible = false
		set_state(State.FREE)
		return item
	else:
		print("Not holding an item")
		return null

# Backward Compatibility - Ingredient-spezifische Funktionen
func pickUpIngredient(ingredient: Ingredient) -> bool:
	return pickUpPickable(ingredient)

func getHeldIngredient() -> Ingredient:
	if held_pickable is Ingredient:
		return held_pickable as Ingredient
	return null

func isHoldingIngredient() -> bool:
	return held_pickable is Ingredient
