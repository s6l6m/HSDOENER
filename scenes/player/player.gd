extends CharacterBody2D
class_name Player

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
enum PlayerNumber { ONE, TWO }
@export var player_number: PlayerNumber = PlayerNumber.ONE

var facing_dir: Vector2 = Vector2.DOWN
var velocity_target: Vector2 = Vector2.ZERO
var current_state: State = State.FREE

# Station Interaktion
var current_station: Node2D = null
var stations_in_range: Array[Node2D] = []

# Was der Player gerade hält (Player State) - PickableResource (Ingredient oder Order)
var held_pickable: PickableResource = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_icon: TextureRect = %InteractIcon
@onready var cut_icon: TextureRect = %CutIcon
@onready var heldItem: Sprite2D = $HeldItem

func _ready() -> void:
	add_to_group("players")
	match player_number:
		PlayerNumber.ONE:
			var event := InputMap.action_get_events("interact_a_p1")[0]
			interaction_icon.texture = $InputIconMapper.get_icon(event)
		PlayerNumber.TWO:
			var event := InputMap.action_get_events("interact_a_p2")[0]
			interaction_icon.texture = $InputIconMapper.get_icon(event)
	set_state(State.FREE)
	# mit Workstations verbinden
	for station in get_tree().get_nodes_in_group("stations"):
		if station is WorkStation:
			station.player_entered_station.connect(_on_player_entered_station)
			station.player_exited_station.connect(_on_player_exited_station)
	for counter in get_tree().get_nodes_in_group("counterslots"):
		if counter is CounterSlot:
			counter.player_entered_slot.connect(_on_player_entered_station)
			counter.player_exited_slot.connect(_on_player_exited_station)


func _process(_delta):
	if held_pickable != null and held_pickable is Ingredient:
		held_pickable.update_rot(_delta)
		heldItem.modulate = held_pickable.get_icon_tint()

func _physics_process(delta: float) -> void:
	# Wenn Player DISABLED ist, keine Bewegung erlauben
	if current_state == State.DISABLED:
		return

	var direction: Vector2 = Vector2.ZERO

	# Steuerung für Player 1
	match player_number:
		PlayerNumber.ONE:
			if can_move():
				if Input.is_action_pressed("move_right_p1"):
					direction.x += 1
				if Input.is_action_pressed("move_left_p1"):
					direction.x -= 1
				if Input.is_action_pressed("move_down_p1"):
					direction.y += 1
				if Input.is_action_pressed("move_up_p1"):
					direction.y -= 1
			if Input.is_action_just_pressed("interact_a_p1"):
				if current_station:
					if current_station is WorkStation or current_station is CounterSlot:
						current_station.interact(self)
			if Input.is_action_just_pressed("interact_b_p1"):
				if current_station:
					if current_station is WorkStation or current_station is CounterSlot:
						current_station.interact_b(self)
			if Input.is_action_just_released("interact_b_p1"):
				if current_station and current_station is WorkStation and current_station.station_type == WorkStation.StationType.CUTTINGSTATION:
					current_station.stop_cut(self)
	
	# Steuerung für Player 2
		PlayerNumber.TWO:
			if can_move():
				if Input.is_action_pressed("move_right_p2"):
					direction.x += 1
				if Input.is_action_pressed("move_left_p2"):
					direction.x -= 1
				if Input.is_action_pressed("move_down_p2"):
					direction.y += 1
				if Input.is_action_pressed("move_up_p2"):
					direction.y -= 1
			if Input.is_action_just_pressed("interact_a_p2"):
				if current_station:
					if current_station is WorkStation or current_station is CounterSlot:
						current_station.interact(self)
			if Input.is_action_just_pressed("interact_b_p2"):
				if current_station:
					if current_station is WorkStation or current_station is CounterSlot:
						current_station.interact_b(self)
			if Input.is_action_just_released("interact_b_p2"):
				if current_station and current_station.station_type == WorkStation.StationType.CUTTINGSTATION:
					current_station.stop_cut(self)

	# Richtung merken
	if direction != Vector2.ZERO:
		facing_dir = direction.normalized()

	# Sanfte Bewegung
	var accel: float = 15.0
	var friction: float = 10.0

	var target_velocity: Vector2 = direction.normalized() * speed
	velocity = velocity.lerp(target_velocity, (accel if direction != Vector2.ZERO else friction) * delta)

	move_and_slide()

	# Animation steuern (8-Richtungen)
	_update_animation(direction)

func _on_player_entered_station(player, station):
	if player != self:
		return
	stations_in_range.append(station)
	_update_current_station()
	interaction_icon.get_parent().show()

func _on_player_exited_station(player, station):
	if player != self:
		return
	
	stations_in_range.erase(station)
	_update_current_station()
	
func _update_current_station() -> void:
	if stations_in_range.is_empty():
		current_station = null
		interaction_icon.get_parent().hide()
	else:
		current_station = stations_in_range.back()

func start_cutting():
	if current_state == State.FREE or current_state == State.CARRYING:
		set_state(State.CUTTING)

func stop_cutting():
	if current_state == State.CUTTING:
		set_state(State.FREE)

# Animation System - 8 Richtungen
func _update_animation(direction: Vector2) -> void:
	var anim_name: String = ""

	if direction == Vector2.ZERO:
		# Idle Animation basierend auf letzter Blickrichtung
		anim_name = _get_idle_animation_from_direction(facing_dir)
	else:
		# Lauf-Animation basierend auf aktueller Bewegungsrichtung
		anim_name = _get_run_animation_from_direction(direction)

	# Animation abspielen, nur wenn sie sich geändert hat
	if sprite.animation != anim_name:
		sprite.play(anim_name)

func _get_run_animation_from_direction(dir: Vector2) -> String:
	# Normalisiere die Richtung
	var normalized = dir.normalized()

	# Bestimme die 8 Richtungen basierend auf Winkel
	var angle = normalized.angle()

	# Winkel in Grad umrechnen (0° = rechts, 90° = unten, -90° = oben, 180° = links)
	var degrees = rad_to_deg(angle)

	# 8-Richtungs-Logik (45° Bereiche)
	if degrees >= -22.5 and degrees < 22.5:
		return "run_right"
	elif degrees >= 22.5 and degrees < 67.5:
		return "run_down_right"
	elif degrees >= 67.5 and degrees < 112.5:
		return "run_down"
	elif degrees >= 112.5 and degrees < 157.5:
		return "run_down_left"
	elif degrees >= 157.5 or degrees < -157.5:
		return "run_left"
	elif degrees >= -157.5 and degrees < -112.5:
		return "run_up_left"
	elif degrees >= -112.5 and degrees < -67.5:
		return "run_up"
	elif degrees >= -67.5 and degrees < -22.5:
		return "run_up_right"

	# Fallback
	return "run_right"

func _get_idle_animation_from_direction(dir: Vector2) -> String:
	# Falls du nur eine Idle-Animation hast:
	# return "idle"

	# Für 8-Richtungs Idle:
	var normalized = dir.normalized()
	var angle = normalized.angle()
	var degrees = rad_to_deg(angle)

	if degrees >= -22.5 and degrees < 22.5:
		return "idle_right"
	elif degrees >= 22.5 and degrees < 67.5:
		return "idle_down_right"
	elif degrees >= 67.5 and degrees < 112.5:
		return "idle_down"
	elif degrees >= 112.5 and degrees < 157.5:
		return "idle_down_left"
	elif degrees >= 157.5 or degrees < -157.5:
		return "idle_left"
	elif degrees >= -157.5 and degrees < -112.5:
		return "idle_up_left"
	elif degrees >= -112.5 and degrees < -67.5:
		return "idle_up"
	elif degrees >= -67.5 and degrees < -22.5:
		return "idle_up_right"

	# Fallback
	return "idle_down"

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
	return current_state == State.FREE or current_state == State.CARRYING

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
		# wenn der Spieler einen Teller hält, fügen wir den Ingredient seiner Liste hinzu
		if held_pickable is Plate and pickable is Ingredient:
			if pickable.is_prepared:
				held_pickable.addIngredient(pickable)
				return true
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
	if held_pickable and held_pickable is Order:
		return held_pickable as Order
	return null

func isHoldingOrder() -> bool:
	return held_pickable != null and held_pickable is Order

func getHeldIngredient() -> Ingredient:
	if held_pickable and held_pickable is Ingredient:
		return held_pickable as Ingredient
	return null

func isHoldingIngredient() -> bool:
	return held_pickable != null and held_pickable is Ingredient

func getHeldPlate() -> Plate:
	if held_pickable and held_pickable is Plate:
		return held_pickable as Plate
	return null

func isHoldingPlate() -> bool:
	return held_pickable != null and held_pickable is Plate
