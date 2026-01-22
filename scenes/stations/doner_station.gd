@tool
extends WorkStation
class_name DonerStation

# Config
@export var burn_time := 10.0
@export var sprite_offset := Vector2(0, 60):
	set(value):
		sprite_offset = value
		if is_inside_tree():
			_update_doner_direction()
@export var fire_offset := Vector2(0, -10):
	set(value):
		fire_offset = value
		if is_inside_tree():
			_update_doner_direction()

var cutting_duration := 2.0

# State
var burn_level := 0
var burn_timer := burn_time
var timer_running := true
var cutting := false
var cutting_progress := 0.0
var _player_cutting: Player = null

# Animation
var cook_tween: Tween
var shake_tween: Tween
var _base_sprite_position: Vector2

# Resources
var ingredient_entity_scene := preload("res://scenes/items/ingredient_entity.tscn")
var meat_resource := preload("res://scenes/ingredients/fleisch.tres")
var burnt_meat_resource := preload("res://scenes/ingredients/fleisch-angebrannt.tres")

# Nodes
@onready var progress_bar := %ProgressBar
@onready var doner_sprite: AnimatedSprite2D = %DonerSprite
@onready var steam_particles: CPUParticles2D = %SteamParticles
@onready var fire_particles: CPUParticles2D = %FireParticles


func _ready() -> void:
	super._ready()
	_update_doner_direction()

	if Engine.is_editor_hint():
		return

	if doner_sprite:
		_base_sprite_position = doner_sprite.position

	_update_visual_state()
	audio_player = AudioPlayerManager.play(AudioPlayerManager.AudioID.STATION_FIRE_ON)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_update_burn(delta)
	_update_cutting(delta)


func _exit_tree() -> void:
	_stop_cook_pulse()
	_stop_cutting_shake()
	if audio_player != null:
		AudioPlayerManager.stop(audio_player)
		audio_player = null


# Direction
func _update_doner_direction() -> void:
	if not doner_sprite:
		return

	var base_pos := Vector2.ZERO
	var steam_pos := Vector2.ZERO
	var fire_pos := Vector2.ZERO
	var fire_dir := Vector2(0, -1)

	match direction:
		Direction.UP:
			base_pos = Vector2(0, -59)
			doner_sprite.rotation_degrees = 0
			steam_pos = Vector2(0, -90)
			fire_pos = Vector2(0, -20)
			fire_dir = Vector2(0, -1)
			if steam_particles:
				steam_particles.direction = Vector2(0, -1)
		Direction.RIGHT:
			base_pos = Vector2(-32, -55)
			doner_sprite.rotation_degrees = -90
			steam_pos = Vector2(-60, -55)
			fire_pos = Vector2(-25, -40)
			fire_dir = Vector2(-0.5, -1)
			if steam_particles:
				steam_particles.direction = Vector2(-1, 0)
		Direction.DOWN:
			base_pos = Vector2(0, -20)
			doner_sprite.rotation_degrees = -180
			steam_pos = Vector2(0, 10)
			fire_pos = Vector2(0, 15)
			fire_dir = Vector2(0, 1)
			if steam_particles:
				steam_particles.direction = Vector2(0, 1)
		Direction.LEFT:
			base_pos = Vector2(32, -55)
			doner_sprite.rotation_degrees = -270
			steam_pos = Vector2(60, -55)
			fire_pos = Vector2(25, -40)
			fire_dir = Vector2(0.5, -1)
			if steam_particles:
				steam_particles.direction = Vector2(1, 0)

	doner_sprite.position = base_pos + sprite_offset

	if steam_particles:
		steam_particles.position = steam_pos + sprite_offset

	if fire_particles:
		fire_particles.position = fire_pos + fire_offset
		fire_particles.direction = fire_dir

	_base_sprite_position = doner_sprite.position


# Interaction
func interact(_player: Player):
	if Engine.is_editor_hint():
		return

	AudioPlayerManager.play(AudioPlayerManager.AudioID.PLAYER_PUT)
	burn_level = 0
	burn_timer = burn_time

	if not timer_running:
		timer_running = true

	_update_visual_state()


func interact_b(player: Player):
	if Engine.is_editor_hint():
		return

	if cutting or not player.can_move():
		return

	var held := player.get_held_item()
	if held != null and not (held is DonerEntity and held._has_bread()):
		return

	cutting = true
	_player_cutting = player
	player.set_state(Player.State.CUTTING)
	audio_player = AudioPlayerManager.play(AudioPlayerManager.AudioID.DONER_CUT)
	_start_cutting_shake()


func supports_interact_b() -> bool:
	return true


# Burn Logic
func _update_burn(delta: float) -> void:
	if not timer_running:
		return

	burn_timer -= delta

	if burn_timer <= 0:
		burn_level = 1
		timer_running = false
		AudioPlayerManager.play(AudioPlayerManager.AudioID.STATION_FIRE_BURN)
		_update_visual_state()


# Visual State
func _update_visual_state() -> void:
	if not doner_sprite:
		return

	_stop_cook_pulse()

	if burn_level == 0:
		_start_cook_pulse()
		doner_sprite.play("rotate_normal")
		_set_steam(true, Color(1, 1, 1, 0.35))
	else:
		doner_sprite.modulate = Color(0.45, 0.35, 0.35)
		doner_sprite.play("rotate_burnt")
		_set_steam(true, Color(0.25, 0.22, 0.22, 0.5))


func _set_steam(emitting: bool, color: Color) -> void:
	if steam_particles:
		steam_particles.emitting = emitting
		steam_particles.color = color


# Cook Pulse Animation
func _start_cook_pulse() -> void:
	if not doner_sprite or (cook_tween and cook_tween.is_running()):
		return

	cook_tween = create_tween().set_loops()
	cook_tween.tween_property(doner_sprite, "modulate", Color(1.0, 0.85, 0.65), 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	cook_tween.tween_property(doner_sprite, "modulate", Color(1.0, 0.92, 0.8), 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_cook_pulse() -> void:
	if cook_tween and cook_tween.is_valid():
		cook_tween.kill()
		cook_tween = null


# Cutting Shake Animation
func _start_cutting_shake() -> void:
	if not doner_sprite or (shake_tween and shake_tween.is_running()):
		return

	shake_tween = create_tween().set_loops()
	shake_tween.tween_property(doner_sprite, "position:x", _base_sprite_position.x + 2, 0.04)
	shake_tween.tween_property(doner_sprite, "position:x", _base_sprite_position.x - 2, 0.04)


func _stop_cutting_shake() -> void:
	if shake_tween and shake_tween.is_valid():
		shake_tween.kill()
		shake_tween = null

	if doner_sprite and is_instance_valid(doner_sprite):
		var return_tween := create_tween()
		return_tween.tween_property(doner_sprite, "position", _base_sprite_position, 0.1) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# Cutting Logic
func stop_cut(player: Player) -> void:
	if player == null or player.current_state != Player.State.CUTTING:
		return

	_player_cutting = null
	cutting = false
	player.set_state(Player.State.FREE)
	AudioPlayerManager.stop(audio_player)
	_stop_cutting_shake()


func _update_cutting(delta: float) -> void:
	if progress_bar == null:
		return

	progress_bar.visible = cutting_progress > 0.0

	if not cutting:
		if cutting_progress > 0.0:
			cutting_progress -= delta / 2
			progress_bar.value = cutting_progress / cutting_duration * 100
	else:
		if cutting_progress < cutting_duration:
			cutting_progress += delta
			progress_bar.value = cutting_progress / cutting_duration * 100
		else:
			_finish_cut()


func _finish_cut() -> void:
	cutting = false
	cutting_progress = 0.0

	var player := _player_cutting
	AudioPlayerManager.play(AudioPlayerManager.AudioID.PLAYER_PUT)
	stop_cut(player)
	_give_meat(player)


func _give_meat(player: Player) -> void:
	if player == null:
		return

	var entity := ingredient_entity_scene.instantiate() as IngredientEntity
	entity.ingredient = burnt_meat_resource if burn_level == 1 else meat_resource

	if player.pick_up_item(entity):
		AudioPlayerManager.play(AudioPlayerManager.AudioID.PLAYER_GRAB)
	elif is_instance_valid(entity) and not entity.is_inside_tree():
		entity.free()
