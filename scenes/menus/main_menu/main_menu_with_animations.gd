extends MainMenu
## Main menu extension that adds options and animates the title and menu fading in.
## The scene adds a 'Continue' button if a game is in progress.
## The animation can be skipped by the player with any input.

## Optional scene to open when the player clicks a 'Level Select' button.
@export var level_select_packed_scene: PackedScene
@export var character_select_menu_scene: PackedScene

var animation_state_machine : AnimationNodeStateMachinePlayback

@onready var level_select_button = %LevelSelectButton

func load_game_scene() -> void:
	GameState.start_game()
	super.load_game_scene()

func new_game() -> void:
	GameState.reset()
	if character_select_menu_scene:
		_open_character_select()
	else:
		load_game_scene()

func _open_character_select() -> void:
	var character_select_menu = _open_sub_menu(character_select_menu_scene)
	character_select_menu.show_menu()
	character_select_menu.selection_complete.connect(_on_character_selection_complete, CONNECT_ONE_SHOT)

func _on_character_selection_complete() -> void:
	_close_sub_menu()
	load_game_scene()

func intro_done() -> void:
	animation_state_machine.travel("OpenMainMenu")

func _is_in_intro() -> bool:
	return animation_state_machine.get_current_node() == "Intro"

func _event_skips_intro(event : InputEvent) -> bool:
	return event.is_action_released("ui_accept") or \
		event.is_action_released("ui_select") or \
		event.is_action_released("ui_cancel") or \
		_event_is_mouse_button_released(event)

func _open_sub_menu(menu : PackedScene) -> Node:
	animation_state_machine.travel("OpenSubMenu")
	return super._open_sub_menu(menu)

func _close_sub_menu() -> void:
	super._close_sub_menu()
	animation_state_machine.travel("OpenMainMenu")

func _input(event : InputEvent) -> void:
	if _is_in_intro() and _event_skips_intro(event):
		intro_done()
		return
	super._input(event)

func _show_level_select_if_set() -> void: 
	if level_select_packed_scene == null: return
	if GameState.get_levels_reached() <= 1 : return
	level_select_button.show()

func _ready() -> void:
	super._ready()
	_show_level_select_if_set()
	animation_state_machine = $MenuAnimationTree.get("parameters/playback")

func _on_continue_game_button_pressed() -> void:
	GameState.continue_game()
	_open_character_select()

func _on_level_select_button_pressed() -> void:
	var level_select_scene := _open_sub_menu(level_select_packed_scene)
	if level_select_scene.has_signal("level_selected"):
		level_select_scene.connect("level_selected", load_game_scene)
