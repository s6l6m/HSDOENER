class_name CharacterSelectMenu
extends Control

signal selection_complete

@onready var p1_grid := %P1CharacterGrid
@onready var p2_grid := %P2CharacterGrid
@onready var p1_ready_label := %P1ReadyLabel
@onready var p2_ready_label := %P2ReadyLabel
@onready var start_button := %StartButton
@onready var p1_portrait := %P1Portrait
@onready var p2_portrait := %P2Portrait
@onready var p1_name_label := %P1NameLabel
@onready var p2_name_label := %P2NameLabel
@onready var _char_manager := get_node("/root/CharacterSelectionManager")

const CHARACTER_BUTTON_SCENE = preload("res://scenes/menus/character_select_menu/character_button.tscn")

var ready_state := {0: false, 1: false}
var _grids_populated := false

var p1_buttons: Array[TextureButton] = []
var p2_buttons: Array[TextureButton] = []
var p1_focus_index := 0
var p2_focus_index := 0
const FOCUS_SCALE := 1.15

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	hide()

func show_menu() -> void:
	if not _grids_populated:
		_populate_character_grids()
		_grids_populated = true

	ready_state = {0: false, 1: false}
	_update_ui()
	show()

func _populate_character_grids() -> void:
	if not _char_manager:
		push_error("CharacterSelectionManager not found!")
		return

	if not _char_manager.character_database:
		push_error("Character database is null!")
		return

	var characters = _char_manager.character_database.get_all_characters()

	p1_buttons.clear()
	p2_buttons.clear()

	for character in characters:
		var btn_p1 = CHARACTER_BUTTON_SCENE.instantiate()
		btn_p1.setup(character)
		btn_p1.pressed.connect(_on_character_selected.bind(0, character.character_id))
		p1_grid.add_child(btn_p1)
		p1_buttons.append(btn_p1)

		var btn_p2 = CHARACTER_BUTTON_SCENE.instantiate()
		btn_p2.setup(character)
		btn_p2.pressed.connect(_on_character_selected.bind(1, character.character_id))
		p2_grid.add_child(btn_p2)
		p2_buttons.append(btn_p2)

	_update_focus_visuals()

func _on_character_selected(player_number: int, character_id: StringName) -> void:
	if not _char_manager:
		return

	_char_manager.select_character(player_number, character_id)
	ready_state[player_number] = true
	_update_ui()

func _update_ui() -> void:
	if not _char_manager:
		return

	var p1_char = _char_manager.get_character_for_player(0)
	if p1_char:
		p1_portrait.texture = p1_char.portrait
		p1_name_label.text = p1_char.display_name
	p1_ready_label.visible = ready_state[0]

	var p2_char = _char_manager.get_character_for_player(1)
	if p2_char:
		p2_portrait.texture = p2_char.portrait
		p2_name_label.text = p2_char.display_name
	p2_ready_label.visible = ready_state[1]

	var both_ready = ready_state[0] and ready_state[1]
	start_button.disabled = not both_ready

	if both_ready:
		start_button.text = "SPIEL STARTEN"
	else:
		var waiting_for = []
		if not ready_state[0]:
			waiting_for.append("P1")
		if not ready_state[1]:
			waiting_for.append("P2")
		start_button.text = "Warte auf " + " & ".join(waiting_for)

func _on_start_pressed() -> void:
	selection_complete.emit()
	hide()

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("move_left_p1"):
		_navigate_player(0, -1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_right_p1"):
		_navigate_player(0, 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact_a_p1") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_E):
		_confirm_selection(0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_left_p2"):
		_navigate_player(1, -1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_right_p2"):
		_navigate_player(1, 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact_a_p2"):
		_confirm_selection(1)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_SPACE:
		if ready_state[0] and ready_state[1]:
			get_viewport().set_input_as_handled()
			_on_start_pressed()

func _navigate_player(player_number: int, direction: int) -> void:
	var buttons = p1_buttons if player_number == 0 else p2_buttons
	if buttons.is_empty():
		return

	if player_number == 0:
		p1_focus_index = wrapi(p1_focus_index + direction, 0, buttons.size())
	else:
		p2_focus_index = wrapi(p2_focus_index + direction, 0, buttons.size())

	_update_focus_visuals()

func _confirm_selection(player_number: int) -> void:
	var buttons = p1_buttons if player_number == 0 else p2_buttons
	var focus_index = p1_focus_index if player_number == 0 else p2_focus_index

	if focus_index < buttons.size():
		buttons[focus_index].emit_signal("pressed")

func _update_focus_visuals() -> void:
	for btn in p1_buttons:
		btn.scale = Vector2.ONE
	for btn in p2_buttons:
		btn.scale = Vector2.ONE

	if p1_focus_index < p1_buttons.size():
		p1_buttons[p1_focus_index].scale = Vector2.ONE * FOCUS_SCALE

	if p2_focus_index < p2_buttons.size():
		p2_buttons[p2_focus_index].scale = Vector2.ONE * FOCUS_SCALE
