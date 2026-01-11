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
signal item_picked_up(item: ItemEntity)
signal item_dropped(item: ItemEntity)

# =====================================================
# Export / Config
# =====================================================
@export var speed := 150.0
@export var player_number: PlayerNumber = PlayerNumber.ONE

# =====================================================
# Sprite Frame Resources
# =====================================================
const SPRITE_FRAMES := {
	PlayerNumber.ONE: preload("res://scenes/player/player_1_sprite_frames.tres"),
	PlayerNumber.TWO: preload("res://scenes/player/player_2_sprite_frames.tres"),
}

# =====================================================
# Runtime State
# =====================================================
var current_state: State = State.FREE
var facing_dir := Vector2.DOWN
var held_item_entity: ItemEntity

# Bobbing animation
var bobbing_tween: Tween
var base_held_item_offset: Vector2 = Vector2.ZERO
var is_bobbing: bool = false

# Stations
var current_station: Node2D
var stations_in_range: Array[Node2D] = []

var walk_audio_player: AudioStreamPlayer

# =====================================================
# Nodes
# =====================================================
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_icon: TextureRect = %InteractIcon
@onready var cut_icon: TextureRect = %CutIcon
@onready var held_item_anchor: Node2D = $HeldItem
@onready var item_background: Panel = $HeldItem/ItemBackground

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
	_load_sprite_frames()
	_setup_interaction_icon()
	_connect_stations()
	set_state(State.FREE)

	# Store the base position of held_item_anchor from the scene
	if held_item_anchor:
		base_held_item_offset = held_item_anchor.position

func _process(_delta: float) -> void:
	pass

func _load_sprite_frames() -> void:
	"""Load player-specific sprite frames based on player_number."""
	if player_number in SPRITE_FRAMES:
		sprite.sprite_frames = SPRITE_FRAMES[player_number]
		print_debug("Player %s: Loaded sprite frames" % PlayerNumber.keys()[player_number])
	else:
		push_warning("Player: Unknown player_number %s, using default sprite frames" % player_number)

func _physics_process(delta: float) -> void:
	if current_state == State.DISABLED:
		return

	var direction := _get_move_direction()
	_handle_interactions()

	_move(direction, delta)
	_update_animation(direction)
	_update_held_item_bobbing(direction)

	if not walk_audio_player and direction != Vector2.ZERO:
		walk_audio_player = AudioPlayerManager.play(AudioPlayerManager.AudioID.PLAYER_MOVE)

	if walk_audio_player and direction.is_equal_approx(Vector2.ZERO):
		AudioPlayerManager.stop(walk_audio_player)

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

	if Input.is_action_just_released(interact_a):
		if current_station is DonerStation:
			current_station.stop_cut(self)

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
	var anim: String
	if direction == Vector2.ZERO:
		# Idle: wähle basierend auf letzter Bewegungsrichtung
		anim = "idleBackView" if facing_dir.y < 0 else "idle"
	else:
		# Bewegung: normale Run-Animation
		anim = _get_run_animation(direction)

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

func _update_held_item_bobbing(direction: Vector2) -> void:
	"""Updates the bobbing animation for held items when the player is moving."""
	if not held_item_entity or not held_item_anchor:
		return

	var should_bob := direction != Vector2.ZERO and velocity.length() > 10.0

	if should_bob and not is_bobbing:
		_start_bobbing()
	elif not should_bob and is_bobbing:
		_stop_bobbing()

func _start_bobbing() -> void:
	"""Starts the continuous bobbing animation."""
	is_bobbing = true

	# Kill any existing tween
	if bobbing_tween and bobbing_tween.is_valid():
		bobbing_tween.kill()

	# Create looping tween
	bobbing_tween = create_tween().set_loops()

	# Bob parameters (tuned for Zelda-style feel)
	var bob_amplitude := 2.0  # Pixels to move up/down
	var bob_duration := 0.25  # Seconds per bob cycle (0.25s = 4 bobs per second)

	var up_position := base_held_item_offset + Vector2(0, -bob_amplitude)
	var down_position := base_held_item_offset + Vector2(0, bob_amplitude)

	# Smooth sine wave bobbing
	bobbing_tween.tween_property(
		held_item_anchor,
		"position",
		up_position,
		bob_duration / 2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	bobbing_tween.tween_property(
		held_item_anchor,
		"position",
		down_position,
		bob_duration / 2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_bobbing() -> void:
	"""Stops the bobbing and smoothly returns to base position."""
	is_bobbing = false

	# Kill the looping tween
	if bobbing_tween and bobbing_tween.is_valid():
		bobbing_tween.kill()

	# Smooth return to base position
	var return_tween := create_tween()
	return_tween.tween_property(
		held_item_anchor,
		"position",
		base_held_item_offset,
		0.15
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

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
# Items
# =====================================================
func pick_up_item(item: ItemEntity) -> bool:
	if not item:
		return false

	# Special case: if we're already holding a Döner, picking up an ingredient should add it.
	if held_item_entity is DonerEntity and item is IngredientEntity:
		# Ownership note: the caller (station/workstation) owns the temporary entity and handles cleanup
		# if this returns false. DonerEntity consumes the ingredient entity on success.
		var doner := held_item_entity as DonerEntity
		var ingredient_entity := item as IngredientEntity
		if doner.add_ingredient(ingredient_entity):
			return true
		return false

	# Symmetric: holding an ingredient and picking up a Döner.
	if held_item_entity is IngredientEntity and item is DonerEntity:
		# If successful, the held ingredient is consumed and the player ends up holding the döner.
		var ingredient_entity := held_item_entity as IngredientEntity
		var doner := item as DonerEntity
		if doner.add_ingredient(ingredient_entity):
			held_item_entity = doner
			doner.attach_to(held_item_anchor)
			doner.visible = true
			item_background.visible = true
			return true
		return false

	if not held_item_entity:
		held_item_entity = item
		item.attach_to(held_item_anchor)
		item.visible = true
		item_background.visible = true
		item_picked_up.emit(item)
		set_state(State.CARRYING)
		return true

	return false

func drop_item() -> ItemEntity:
	if not held_item_entity:
		return null
	var item := held_item_entity
	held_item_entity = null
	item_background.visible = false
	item_dropped.emit(item)
	set_state(State.FREE)
	return item

func is_holding_item() -> bool:
	return held_item_entity != null

func get_held_item() -> ItemEntity:
	return held_item_entity

# =====================================================
# Helpers
# =====================================================
func _setup_interaction_icon() -> void:
	var action = INPUT_MAP[player_number][InputAction.INTERACT_A]
	var event := InputMap.action_get_events(action)[0]
	interaction_icon.texture = $InputIconMapper.get_icon(event)
