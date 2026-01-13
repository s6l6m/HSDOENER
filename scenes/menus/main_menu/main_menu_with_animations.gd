extends MainMenu

## Main menu extension that adds options and animates the title and menu fading in.
@export_group("Sub-Menu Scenes")
@export var level_select_packed_scene: PackedScene
@export var character_select_menu_packed_scene: PackedScene

var level_select_scene: Node = null
var character_select_menu_scene: Node = null
var animation_state_machine : AnimationNodeStateMachinePlayback

func _ready() -> void:
	super._ready()
	# Ensure the path to AnimationTree is correct for your scene tree
	if has_node("MenuAnimationTree"):
		animation_state_machine = $MenuAnimationTree.get("parameters/playback")
	else:
		push_error("MenuAnimationTree node not found!")

func new_game() -> void: 
	_level_select()

func _level_select() -> void:
	level_select_scene = _open_sub_menu(level_select_packed_scene)
	
	if level_select_scene and level_select_scene.has_signal("level_selected"):
		level_select_scene.level_selected.connect(_on_finish_select_scene, CONNECT_ONE_SHOT)
	else:
		push_warning("Level Select scene loaded but 'level_selected' signal is missing!")

func _on_finish_select_scene(_level_data = null) -> void:
	if is_instance_valid(level_select_scene):
		level_select_scene.queue_free()

	_open_character_select()


func _open_character_select() -> void:
	character_select_menu_scene = _open_sub_menu(character_select_menu_packed_scene)

	if character_select_menu_scene and character_select_menu_scene.has_signal("selection_complete"):
		character_select_menu_scene.selection_complete.connect(
			_on_character_selection_complete,
			CONNECT_ONE_SHOT
		)
	else:
		push_error("Character Select scene loaded but 'selection_complete' signal is missing!")

func _on_character_selection_complete() -> void:
	print("Character selection complete. Loading game...")
	load_game_scene()

func load_game_scene() -> void:
	GameState.start_game()
	super.load_game_scene()

func _open_sub_menu(menu : PackedScene) -> Node:
	if animation_state_machine:
		animation_state_machine.travel("OpenSubMenu")
	return super._open_sub_menu(menu)

func _close_sub_menu(return_to_main := true) -> void:
	super._close_sub_menu()
	if return_to_main and animation_state_machine:
		animation_state_machine.travel("OpenMainMenu")

func intro_done() -> void:
	if animation_state_machine:
		animation_state_machine.travel("OpenMainMenu")

func _is_in_intro() -> bool:
	if animation_state_machine:
		return animation_state_machine.get_current_node() == "Intro"
	return false

func _event_skips_intro(event : InputEvent) -> bool:
	return event.is_action_released("ui_accept") or \
		event.is_action_released("ui_select") or \
		event.is_action_released("ui_cancel") or \
		_event_is_mouse_button_released(event)

func _input(event : InputEvent) -> void:
	if _is_in_intro() and _event_skips_intro(event):
		intro_done()
		return
	super._input(event)
