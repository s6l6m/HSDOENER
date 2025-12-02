@tool
extends WorkStation
class_name CuttingStation

var cutting: bool = false
var cutting_progress: float = 0.0
var cutting_duration: float = 2.0  # Sekunden bis fertig
var _player_cutting: Player = null

var stored_ingredient: Ingredient
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


func start_cut(player):
	_player_cutting = player
	
	if stored_ingredient == null:
		return
	if not (stored_ingredient is Ingredient):
		return
	if stored_ingredient.is_prepared:
		return
	
	cutting = true
	player.start_cutting()


func stop_cut(player):
	_player_cutting = null
	cutting = false
	player.stop_cutting()


func _finish_cut():
	cutting = false
	cutting_progress = 0.0
	
	var ing := stored_ingredient

	ing.is_prepared = true
	if ing.cut_icon:
		ing.icon = ing.cut_icon

	update_visual()
	
	if _player_cutting:
		_player_cutting.stop_cutting()
		_player_cutting = null


func interact(player):
	var held = player.getHeldPickable()
	if stored_ingredient != null:
		if player.pickUpPickable(stored_ingredient):
			if stored_ingredient is Ingredient:
				stored_ingredient.remove_from_workstation()
			stored_ingredient = null
			update_visual()
		return
		
	if held != null:
		stored_ingredient = held
		if stored_ingredient is Ingredient:
			stored_ingredient.put_into_workstation()
		player.dropPickable()
		update_visual()


func update_visual():
	if stored_ingredient == null:
		food.visible = false
		return
	
	food.texture = stored_ingredient.icon
	food.modulate = stored_ingredient.get_icon_tint()
	food.visible = true
