@tool
extends WorkStation
class_name DonerStation

@export var burn_time := 10.0
var burn_timer := burn_time
var burn_level := 0
var timer_running := true

var cutting: bool = false
var cutting_progress: float = 0.0
var cutting_duration: float = 2.0
var _player_cutting: Player = null

var ingredient_entity_scene := preload("res://scenes/items/ingredient_entity.tscn")
var meat_resource := preload("res://scenes/ingredients/fleisch.tres")
var burnt_meat_resource := preload("res://scenes/ingredients/fleisch-angebrannt.tres")

@onready var progress_bar := $ProgressBar


func _ready() -> void:
	super._ready()

	if Engine.is_editor_hint():
		return

	audio_player = AudioPlayerManager.play(
		AudioPlayerManager.AudioID.STATION_FIRE_ON
	)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	_update_burn(delta)
	_update_cutting(delta)

func _update_burn(delta: float) -> void:
	if not timer_running:
		return

	if burn_timer <= 0:
		burn_level = 1
		update_texture()
		timer_running = false
		AudioPlayerManager.play(AudioPlayerManager.AudioID.STATION_FIRE_BURN)
	else:
		burn_timer -= delta


func interact(player: Player):
	if Engine.is_editor_hint():
		return

	if cutting:
		return

	if not player.can_move():
		return

	var held := player.get_held_item()
	if held != null and not (held is DonerEntity):
		return

	cutting = true
	_player_cutting = player
	player.set_state(Player.State.CUTTING)


func interact_b(_player: Player):
	if Engine.is_editor_hint():
		return

	burn_level = 0
	update_texture()
	burn_timer = burn_time

	if not timer_running:
		timer_running = true


func update_texture():
	var textures = [
		preload("res://assets/workstations/content/Doner_default.png"),
		preload("res://assets/workstations/content/Doner_burnt.png"),
	]
	content.texture = textures[burn_level]

func stop_cut(player: Player) -> void:
	if player == null:
		return
	if player.current_state == Player.State.CUTTING:
		_player_cutting = null
		cutting = false
		player.set_state(Player.State.FREE)

func _update_cutting(delta: float) -> void:
	if progress_bar == null:
		return
	if cutting_progress > 0.0:
		progress_bar.visible = true
	else:
		progress_bar.visible = false

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
	stop_cut(player)
	_give_meat(player)

func _give_meat(player: Player) -> void:
	if player == null:
		return
	var entity := ingredient_entity_scene.instantiate() as IngredientEntity
	entity.ingredient = burnt_meat_resource if burn_level == 1 else meat_resource
	var picked := player.pick_up_item(entity)
	if not picked and is_instance_valid(entity) and not entity.is_inside_tree():
		entity.free()
	else:
		AudioPlayerManager.play(AudioPlayerManager.AudioID.PLAYER_GRAB)


func _exit_tree() -> void:
	# Clean up looping audio when node is removed
	if audio_player != null:
		AudioPlayerManager.stop(audio_player)
		audio_player = null
