extends CharacterBody2D
class_name Player

# =====================================================
# Enums
# =====================================================
enum State { FREE, CARRYING, INTERACTING, CUTTING, DISABLED }
enum PlayerNumber { ONE, TWO }
enum InputAction { MOVE, INTERACT_A, INTERACT_B }

# =====================================================
# Signals
# =====================================================
signal state_changed(old_state: State, new_state: State)
signal pickable_picked_up(pickable: PickableResource)
signal pickable_dropped(pickable: PickableResource)

# =====================================================
# Export / Config
# =====================================================
@export var speed := 150.0
@export var player_number: PlayerNumber = PlayerNumber.ONE

# =====================================================
# Runtime State
# =====================================================
var current_state: State = State.FREE
var facing_dir := Vector2.DOWN
var held_pickable: PickableResource

# Stations
var current_station: Node2D
var stations_in_range: Array[Node2D] = []

# =====================================================
# Nodes
# =====================================================
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_icon: TextureRect = %InteractIcon
@onready var cut_icon: TextureRect = %CutIcon
@onready var held_item: Sprite2D = $HeldItem

# =====================================================
# Input Mapping (ENUM → ACTION STRING)
# =====================================================
const INPUT_MAP := {
	PlayerNumber.ONE: {
		InputAction.MOVE: {
			"right": "move_right_p1",
			"left":  "move_left_p1",
			"down":  "move_down_p1",
			"up":    "move_up_p1",
		},
		InputAction.INTERACT_A: "interact_a_p1",
		InputAction.INTERACT_B: "interact_b_p1",
	},
	PlayerNumber.TWO: {
		InputAction.MOVE: {
			"right": "move_right_p2",
			"left":  "move_left_p2",
			"down":  "move_down_p2",
			"up":    "move_up_p2",
		},
		InputAction.INTERACT_A: "interact_a_p2",
		InputAction.INTERACT_B: "interact_b_p2",
	}
}

# =====================================================
# Lifecycle
# =====================================================
func _ready() -> void:
	add_to_group("players")
	_setup_interaction_icon()
	_connect_stations()
	set_state(State.FREE)

#func _process(delta: float) -> void:
	#if held_pickable is Ingredient:
		#held_pickable.update_rot(delta)
		#held_item.modulate = held_pickable.get_icon_tint()
	#elif held_pickable is Plate:
		#held_item.modulate = Color(1,1,1)

func _physics_process(delta: float) -> void:
	if current_state == State.DISABLED:
		return

	var direction := _get_move_direction()
	_handle_interactions()

	_move(direction, delta)
	_update_animation(direction)

# =====================================================
# Input Handling
# =====================================================
func _get_move_direction() -> Vector2:
	if not can_move():
		return Vector2.ZERO

	var map = INPUT_MAP[player_number][InputAction.MOVE]
	var dir := Vector2(
		Input.get_action_strength(map.right) - Input.get_action_strength(map.left),
		Input.get_action_strength(map.down)  - Input.get_action_strength(map.up)
	)

	if dir != Vector2.ZERO:
		facing_dir = dir.normalized()

	return dir

func _handle_interactions() -> void:
	if not current_station:
		return

	var interact_a = INPUT_MAP[player_number][InputAction.INTERACT_A]
	var interact_b = INPUT_MAP[player_number][InputAction.INTERACT_B]

	if Input.is_action_just_pressed(interact_a):
		current_station.interact(self)

	if Input.is_action_just_pressed(interact_b):
		current_station.interact_b(self)

	if Input.is_action_just_released(interact_b):
		if current_station is CuttingStation:
			current_station.stop_cut(self)

# =====================================================
# Movement
# =====================================================
func _move(direction: Vector2, delta: float) -> void:
	var accel := 15.0
	var friction := 10.0

	var target := direction.normalized() * speed
	velocity = velocity.lerp(
		target,
		(accel if direction != Vector2.ZERO else friction) * delta
	)

	move_and_slide()

# =====================================================
# Stations
# =====================================================
func _connect_stations() -> void:
	for station in get_tree().get_nodes_in_group("stations"):
		station.player_entered_station.connect(_on_player_entered_station)
		station.player_exited_station.connect(_on_player_exited_station)

	for counter in get_tree().get_nodes_in_group("counterslots"):
		counter.player_entered_slot.connect(_on_player_entered_station)
		counter.player_exited_slot.connect(_on_player_exited_station)

func _on_player_entered_station(player, station) -> void:
	if player != self:
		return
	stations_in_range.append(station)
	_update_current_station()
	interaction_icon.get_parent().show()

func _on_player_exited_station(player, station) -> void:
	if player != self:
		return
	stations_in_range.erase(station)
	_update_current_station()

func _update_current_station() -> void:
	current_station = stations_in_range.back() if stations_in_range else null
	interaction_icon.get_parent().visible = current_station != null

# =====================================================
# Animation
# =====================================================
func _update_animation(direction: Vector2) -> void:
	var anim := "idle" if direction == Vector2.ZERO else _get_run_animation(direction)
	if sprite.animation != anim:
		sprite.play(anim)

func _get_run_animation(dir: Vector2) -> String:
	# Winkel in Grad umrechnen (0° = rechts, 90° = unten, -90° = oben, 180° = links)
	var degrees = rad_to_deg(dir.normalized().angle())

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
	return "run_up_right"

# =====================================================
# State Machine
# =====================================================
func set_state(new_state: State) -> void:
	if current_state == new_state:
		return
	var old := current_state
	current_state = new_state
	state_changed.emit(old, new_state)

func can_move() -> bool:
	return current_state in [State.FREE, State.CARRYING]

func can_interact() -> bool:
	return can_move()

# =====================================================
# Pickables
# =====================================================
func pickUpPickable(pickable: PickableResource) -> bool:
	if not pickable:
		return false

	if not held_pickable:
		held_pickable = pickable
		held_item.texture = pickable.icon
		held_item.visible = true
		pickable.on_picked_up()
		pickable_picked_up.emit(pickable)
		set_state(State.CARRYING)
		return true

	if held_pickable is Plate and pickable is Ingredient and pickable.is_prepared:
		held_pickable.addIngredient(pickable)
		return true

	return false

func dropPickable() -> PickableResource:
	if not held_pickable:
		return null

	var p := held_pickable
	held_pickable = null
	held_item.visible = false
	p.on_dropped()
	pickable_dropped.emit(p)
	set_state(State.FREE)
	return p

func isHoldingPickable() -> bool:
	return self.held_pickable != null

func getHeldPickable() -> PickableResource:
	return self.held_pickable if self.isHoldingPickable() else null

func isHoldingPlate() -> bool:
	return self.getHeldPickable() is Plate

# =====================================================
# Helpers
# =====================================================
func _setup_interaction_icon() -> void:
	var action = INPUT_MAP[player_number][InputAction.INTERACT_A]
	var event := InputMap.action_get_events(action)[0]
	interaction_icon.texture = $InputIconMapper.get_icon(event)
