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

# Cutting animation
var cutting_tween: Tween

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
	_update_interaction_buttons()
	_connect_stations()
	set_state(State.FREE)

	if held_item_anchor:
		base_held_item_offset = held_item_anchor.position

func _load_sprite_frames() -> void:
	var gamestate := GameState.get_or_create_state()
	var sprite_frames_resource = CharacterSelectionManager.get_sprite_frames_for_player(gamestate, player_number)

	if sprite_frames_resource:
		sprite.sprite_frames = sprite_frames_resource
		return

	if player_number in SPRITE_FRAMES:
		sprite.sprite_frames = SPRITE_FRAMES[player_number]
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

static func _event_matches_action(event: InputEvent, action_name: String) -> bool:
	return event.is_action(action_name)

static func _input_is_from_player(event: InputEvent):
	for player in INPUT_MAP.keys():
		var player_map = INPUT_MAP[player]
		for action in player_map.values():
			# MOVE is a dictionary of directions
			if action is Dictionary:
				for action_name in action.values():
					if _event_matches_action(event, action_name):
						return player
			# INTERACT_A / INTERACT_B are strings
			elif action is String:
				if _event_matches_action(event, action):
					return player
	return null

func _input(event: InputEvent) -> void:
	var game_state := GameState.get_or_create_state()
	var device_name = InputEventHelper.get_device_name(event)
	if device_name != game_state.last_device_used[player_number] and _input_is_from_player(event) == player_number:
		game_state.last_device_used[player_number] = device_name
		GlobalState.save()
		_update_interaction_buttons()

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

	if Input.is_action_just_pressed(interact_b) and _station_supports_interact_b(current_station):
		current_station.interact_b(self)

	if Input.is_action_just_released(interact_b):
		if current_station is CuttingStation or current_station is DonerStation:
			current_station.stop_cut(self)
	
	_update_interaction_icons()


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

func _on_player_exited_station(player, station) -> void:
	if player != self:
		return
	stations_in_range.erase(station)
	_update_current_station()

func _update_current_station() -> void:
	current_station = null

	if not stations_in_range.is_empty():
		# Pick the LAST CounterSlot in range, if any
		for station in stations_in_range:
			if station is CounterSlot:
				current_station = station

		# Fallback to the last station in range
		if current_station == null or current_station.stored_doner == null and self.get_held_item() == null:
			current_station = stations_in_range.back()

	_update_interaction_icons()

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
	is_bobbing = true
	_kill_tween(bobbing_tween)
	bobbing_tween = create_tween().set_loops()

	const BOB_AMPLITUDE := 2.0
	const BOB_DURATION := 0.25
	var up_pos := base_held_item_offset + Vector2(0, -BOB_AMPLITUDE)
	var down_pos := base_held_item_offset + Vector2(0, BOB_AMPLITUDE)

	bobbing_tween.tween_property(held_item_anchor, "position", up_pos, BOB_DURATION / 2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bobbing_tween.tween_property(held_item_anchor, "position", down_pos, BOB_DURATION / 2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_bobbing() -> void:
	is_bobbing = false
	_kill_tween(bobbing_tween)

	var return_tween := create_tween()
	return_tween.tween_property(held_item_anchor, "position", base_held_item_offset, 0.15) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# =====================================================
# Cutting Animation
# =====================================================
func _start_cutting_animation() -> void:
	_kill_tween(cutting_tween)
	cutting_tween = create_tween().set_loops()
	var base_pos := sprite.position

	# Wind-up (move up)
	cutting_tween.tween_property(sprite, "position:y", base_pos.y - 1.5, 0.12) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Chop down
	cutting_tween.tween_property(sprite, "position:y", base_pos.y + 2.0, 0.08) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Subtle horizontal shake
	cutting_tween.tween_property(sprite, "position:x", base_pos.x + 0.8, 0.03) \
		.set_trans(Tween.TRANS_SINE)
	cutting_tween.tween_property(sprite, "position:x", base_pos.x - 0.8, 0.03) \
		.set_trans(Tween.TRANS_SINE)
	cutting_tween.tween_property(sprite, "position:x", base_pos.x, 0.03) \
		.set_trans(Tween.TRANS_SINE)

	# Return to base
	cutting_tween.tween_property(sprite, "position:y", base_pos.y, 0.14) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_cutting_animation() -> void:
	_kill_tween(cutting_tween)
	cutting_tween = null

func _kill_tween(tween: Tween) -> void:
	if tween and tween.is_valid():
		tween.kill()

# =====================================================
# State Machine
# =====================================================
func set_state(new_state: State) -> void:
	if current_state == new_state:
		return
	var old := current_state
	current_state = new_state

	# Cutting Animation starten/stoppen
	if new_state == State.CUTTING:
		_start_cutting_animation()
	elif old == State.CUTTING:
		_stop_cutting_animation()

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
func _update_interaction_buttons() -> void:
	var gamestate := GameState.get_or_create_state()
	var action = INPUT_MAP[player_number][InputAction.INTERACT_A]
	var event = $InputIconMapper.get_event_for_device(action, gamestate.last_device_used[player_number])
	interaction_icon.texture = $InputIconMapper.get_icon(event)
	
	var action_b = INPUT_MAP[player_number][InputAction.INTERACT_B]
	var event_b = $InputIconMapper.get_event_for_device(action_b, gamestate.last_device_used[player_number])
	cut_icon.texture = $InputIconMapper.get_icon(event_b)

func _update_interaction_icons() -> void:
	var show_a := current_station != null
	var show_b := show_a and _station_supports_interact_b(current_station)
	interaction_icon.get_parent().visible = show_a
	cut_icon.get_parent().visible = show_b

func _station_supports_interact_b(station: Node) -> bool:
	if station == null:
		return false
	if station.has_method("supports_interact_b"):
		return station.supports_interact_b()
	return false
