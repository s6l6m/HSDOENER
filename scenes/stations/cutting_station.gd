@tool
extends WorkStation
class_name CuttingStation

# =====================================================
# Config
# =====================================================
const CUTTING_DURATION := 2.0
const SHAKE_AMPLITUDE := 2.0
const SHAKE_DURATION := 0.04

# =====================================================
# State
# =====================================================
var cutting := false
var cutting_progress := 0.0
var stored_ingredient: IngredientEntity
var _player_cutting: Player
var _ingredient_shake_tween: Tween

# =====================================================
# Nodes
# =====================================================
@onready var food: Node2D = %Food
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var steam_particles: CPUParticles2D = %SteamParticles

# =====================================================
# Lifecycle
# =====================================================
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	_update_cutting(delta)

# =====================================================
# Interaction
# =====================================================
func interact(player: Player) -> void:
	var held := player.get_held_item()

	if stored_ingredient:
		if player.pick_up_item(stored_ingredient):
			AudioPlayerManager.play(AudioPlayerManager.AudioID.PLAYER_GRAB)
			stored_ingredient = null
			update_visual()
		return

	if held is IngredientEntity:
		stored_ingredient = player.drop_item() as IngredientEntity
		if stored_ingredient:
			AudioPlayerManager.play(AudioPlayerManager.AudioID.PLAYER_PUT)
			stored_ingredient.attach_to(food)
		update_visual()

func interact_b(player: Player) -> void:
	if not stored_ingredient or stored_ingredient.is_prepared:
		return

	if not player.can_move():
		return

	cutting = true
	_player_cutting = player
	player.set_state(Player.State.CUTTING)
	audio_player = AudioPlayerManager.play(AudioPlayerManager.AudioID.STATION_CUTTING)
	_set_effects(true)

func stop_cut(player: Player) -> void:
	if player.current_state != Player.State.CUTTING:
		return

	_player_cutting = null
	cutting = false
	player.set_state(Player.State.FREE)
	AudioPlayerManager.stop(audio_player)
	_set_effects(false)

func supports_interact_b() -> bool:
	return stored_ingredient != null and not stored_ingredient.is_prepared

# =====================================================
# Cutting Logic
# =====================================================
func _update_cutting(delta: float) -> void:
	if not stored_ingredient:
		cutting_progress = 0.0

	progress_bar.visible = cutting_progress > 0.0

	if not cutting:
		if cutting_progress > 0.0:
			cutting_progress -= delta / 2
			progress_bar.value = (cutting_progress / CUTTING_DURATION) * 100
	else:
		if cutting_progress < CUTTING_DURATION:
			cutting_progress += delta
			progress_bar.value = (cutting_progress / CUTTING_DURATION) * 100
		else:
			_finish_cut()

func _finish_cut() -> void:
	cutting = false
	cutting_progress = 0.0
	_set_effects(false)

	stored_ingredient.set_prepared(true)
	stop_cut(_player_cutting)
	update_visual()

# =====================================================
# Effects
# =====================================================
func _set_effects(active: bool) -> void:
	_set_steam(active)
	if active:
		_start_ingredient_shake()
	else:
		_stop_ingredient_shake()

func _set_steam(emitting: bool) -> void:
	if steam_particles:
		steam_particles.emitting = emitting

func _start_ingredient_shake() -> void:
	if not stored_ingredient or not food:
		return

	_kill_tween(_ingredient_shake_tween)
	_ingredient_shake_tween = create_tween().set_loops()

	var base_x := food.position.x
	_ingredient_shake_tween.tween_property(food, "position:x", base_x + SHAKE_AMPLITUDE, SHAKE_DURATION)
	_ingredient_shake_tween.tween_property(food, "position:x", base_x - SHAKE_AMPLITUDE, SHAKE_DURATION)

func _stop_ingredient_shake() -> void:
	_kill_tween(_ingredient_shake_tween)
	_ingredient_shake_tween = null
	if food:
		food.position.x = 0

func _kill_tween(tween: Tween) -> void:
	if tween and tween.is_valid():
		tween.kill()

# =====================================================
# Visuals
# =====================================================
func update_visual() -> void:
	if not stored_ingredient:
		food.visible = false
		return

	food.visible = true
