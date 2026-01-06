@tool
extends WorkStation
class_name CuttingStation

var cutting: bool = false
var cutting_progress: float = 0.0
var cutting_duration: float = 2.0  # Sekunden bis fertig
var _player_cutting: Player = null

var stored_ingredient: IngredientEntity
@onready var food: Sprite2D = $Rotatable/Food
@onready var progress_bar := $ProgressBar

func _process(delta):
	# Schneidefortschritt zurücksetzen, wenn kein Ingredient zum Schneiden
	if not stored_ingredient:
		cutting_progress = 0.0
	
	# Progress Bar anzeigen oder verstecken
	if cutting_progress > 0.0:
		progress_bar.visible = true
	else:
		progress_bar.visible = false
	
	# Schneidefortschritt steuern
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


func interact_b(player: Player):
	if stored_ingredient == null:
		return

	if stored_ingredient.is_prepared:
		return
	
	if player.can_move():
		cutting = true
		_player_cutting = player
		player.set_state(Player.State.CUTTING)
		audio_player = AudioPlayerManager.play(AudioPlayerManager.AudioID.STATION_CUTTING)

func stop_cut(player: Player):
	if player.current_state == Player.State.CUTTING:
		_player_cutting = null
		cutting = false
		player.set_state(Player.State.FREE)
		AudioPlayerManager.stop(audio_player)


func _finish_cut():
	cutting = false
	cutting_progress = 0.0
	
	stored_ingredient.set_prepared(true)

	stop_cut(_player_cutting)
	update_visual()


func interact(player: Player):
	var held := player.get_held_item()
	
	if stored_ingredient != null:
		if player.pick_up_item(stored_ingredient):
			AudioPlayerManager.play(AudioPlayerManager.AudioID.PLAYER_GRAB)
			stored_ingredient = null
			update_visual()
		return
		
	if held != null and held is IngredientEntity:
		stored_ingredient = player.drop_item() as IngredientEntity
		if stored_ingredient:
			AudioPlayerManager.play(AudioPlayerManager.AudioID.PLAYER_PUT)
			stored_ingredient.attach_to(food)
		update_visual()


func update_visual():
	if stored_ingredient == null:
		food.visible = false
		return

	food.texture = null
	food.visible = true
