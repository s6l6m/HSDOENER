@tool
extends WorkStation
class_name DonerStation

# =====================================================
# Configuration
# =====================================================

@export var burn_time := 20.0
@export var cutting_duration := 2.0
@export var resetting_duration := 2.0

# =====================================================
# State Variables
# =====================================================

var is_burnt := false
var timer_running := true
var burn_timer: float

var resetting_burn := false
var resetting_burn_progress := 0.0

var cutting := false
var cutting_progress := 0.0
var _player_cutting: Player = null

var cook_tween: Tween

# =====================================================
# Resources
# =====================================================

var ingredient_entity_scene := preload("res://scenes/items/ingredient_entity.tscn")
var meat_resource := preload("res://scenes/ingredients/fleisch.tres")
var burnt_meat_resource := preload("res://scenes/ingredients/fleisch-angebrannt.tres")

# =====================================================
# Node References
# =====================================================

@onready var progress_bar: ProgressBar = %ProgressBar
@onready var burn_progress_bar: ProgressBar = %BurnProgressBar
@onready var doner_sprite: AnimatedSprite2D = %DonerSprite
@onready var steam_particles: CPUParticles2D = %SteamParticles
@onready var fire_particles: CPUParticles2D = %FireParticles

# =====================================================
# Lifecycle
# =====================================================

func _ready() -> void:
	super._ready()
	burn_timer = burn_time
	_update_visual_state()
	
	if not Engine.is_editor_hint():
		AudioPlayerManager.play(AudioPlayerManager.AudioID.STATION_FIRE_ON)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	_update_burn(delta)
	_update_cutting(delta)

# =====================================================
# Interaction - Reset Burn
# =====================================================

func interact(player: Player) -> void:
	if resetting_burn or cutting or not player.can_move():
		return
	
	# If not burnt, reset immediately
	if not is_burnt:
		burn_timer = burn_time
		timer_running = true
		AudioPlayerManager.play(AudioPlayerManager.AudioID.PLAYER_PUT)
		return
	
	# If burnt, require reset duration (penalty)
	resetting_burn = true
	resetting_burn_progress = 0.0
	_player_cutting = player
	player.set_state(Player.State.CUTTING)

func stop_reset(player: Player) -> void:
	if player == null or player.current_state != Player.State.CUTTING:
		return
	
	_player_cutting = null
	resetting_burn = false
	player.set_state(Player.State.FREE)

# =====================================================
# Interaction - Cut Meat
# =====================================================

func interact_b(player: Player) -> void:
	if cutting or resetting_burn or not player.can_move():
		return
	
	var held := player.get_held_item()
	if held != null and not (held is DonerEntity and held._has_bread()):
		return
	
	cutting = true
	_player_cutting = player
	player.set_state(Player.State.CUTTING)
	audio_player = AudioPlayerManager.play(AudioPlayerManager.AudioID.DONER_CUT)

func supports_interact_b() -> bool:
	return true

func stop_cut(player: Player) -> void:
	if player == null or player.current_state != Player.State.CUTTING:
		return
	
	_player_cutting = null
	cutting = false
	player.set_state(Player.State.FREE)
	AudioPlayerManager.stop(audio_player)

# =====================================================
# Update - Burn System
# =====================================================

func _update_burn(delta: float) -> void:
	if not resetting_burn:
		# Decay reset progress if not resetting
		if resetting_burn_progress > 0.0:
			resetting_burn_progress -= delta / 2
		
		# Update burn timer when not resetting
		if timer_running:
			burn_timer -= delta
			
			if burn_timer <= 0:
				is_burnt = true
				timer_running = false
				_update_visual_state()
				AudioPlayerManager.play(AudioPlayerManager.AudioID.STATION_FIRE_BURN)
		
		# Show burn progress (inverted - fills as it approaches burning)
		if timer_running:
			burn_progress_bar.visible = true
			burn_progress_bar.value = (1.0 - (burn_timer / burn_time)) * 100.0
		else:
			burn_progress_bar.visible = false
	else:
		# Resetting is in progress - show reset progress (decreasing from 100 to 0)
		burn_progress_bar.visible = true
		
		if resetting_burn_progress < resetting_duration:
			resetting_burn_progress += delta
			# Invert the progress - start at 100% and decrease to 0%
			burn_progress_bar.value = (1.0 - (resetting_burn_progress / resetting_duration)) * 100.0
		else:
			# Reset complete
			var player := _player_cutting
			stop_reset(player)
			AudioPlayerManager.play(AudioPlayerManager.AudioID.PLAYER_PUT)
			is_burnt = false
			burn_timer = burn_time
			timer_running = true
			_update_visual_state()

# =====================================================
# Update - Cutting System
# =====================================================

func _update_cutting(delta: float) -> void:
	progress_bar.visible = cutting_progress > 0.0
	
	if not cutting:
		# Decay cutting progress if not cutting
		if cutting_progress > 0.0:
			cutting_progress -= delta / 2
			progress_bar.value = cutting_progress / cutting_duration * 100
	else:
		# Cutting is in progress
		if cutting_progress < cutting_duration:
			cutting_progress += delta
			progress_bar.value = cutting_progress / cutting_duration * 100
		else:
			# Cutting complete
			cutting = false
			cutting_progress = 0.0
			var player := _player_cutting
			stop_cut(player)
			_give_meat(player)

func _give_meat(player: Player) -> void:
	if player == null:
		return
	
	var entity := ingredient_entity_scene.instantiate() as IngredientEntity
	entity.ingredient = burnt_meat_resource if is_burnt else meat_resource
	
	if player.pick_up_item(entity):
		AudioPlayerManager.play(AudioPlayerManager.AudioID.PLAYER_GRAB)
	elif is_instance_valid(entity) and not entity.is_inside_tree():
		entity.free()

# =====================================================
# Visual Updates
# =====================================================

func _update_visual_state() -> void:
	if is_burnt:
		_stop_cook_pulse()
		doner_sprite.modulate = Color(0.45, 0.35, 0.35)
		doner_sprite.play("rotate_burnt")
		_set_steam(true, Color(0.25, 0.22, 0.22, 0.5))
	else:
		_start_cook_pulse()
		doner_sprite.play("rotate_normal")
		_set_steam(true, Color(1, 1, 1, 0.35))

func _set_steam(emitting: bool, color: Color) -> void:
	if steam_particles:
		steam_particles.emitting = emitting
		steam_particles.color = color

func _start_cook_pulse() -> void:
	if cook_tween and cook_tween.is_running():
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
