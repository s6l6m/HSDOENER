class_name CharacterSelectMenu
extends Control

signal selection_complete

# UI references
@onready var p1_grid: GridContainer = %P1CharacterGrid
@onready var p2_grid: GridContainer = %P2CharacterGrid
@onready var p1_ready_label: Label = %P1ReadyLabel
@onready var p2_ready_label: Label = %P2ReadyLabel
@onready var start_button: Button = %StartButton
@onready var p1_portrait: TextureRect = %P1Portrait
@onready var p2_portrait: TextureRect = %P2Portrait
@onready var p1_name_label: Label = %P1NameLabel
@onready var p2_name_label: Label = %P2NameLabel
@onready var selection_manager: CharacterSelectionManager = %CharacterSelectionManager

@export var character_button: PackedScene

# State
var players_ready = { Player.PlayerNumber.ONE: false, Player.PlayerNumber.TWO: false }
var grids_initialized := false

var buttons := {
	Player.PlayerNumber.ONE: [] as Array[CharacterButton],
	Player.PlayerNumber.TWO: [] as Array[CharacterButton]
}

var focus_index := { Player.PlayerNumber.ONE: 0, Player.PlayerNumber.TWO: 0 }


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	hide()

func show_menu() -> void:
	if not grids_initialized:
		_create_character_grids()
		grids_initialized = true

	players_ready = { Player.PlayerNumber.ONE: false, Player.PlayerNumber.TWO: false }
	focus_index = { Player.PlayerNumber.ONE: 0, Player.PlayerNumber.TWO: 0 }

	_update_focus(Player.PlayerNumber.ONE)
	_update_focus(Player.PlayerNumber.TWO)
	_update_ui()
	_update_buttons_texture()
	
	show()

func _update_buttons_texture() -> void:
	var game_state := GameState.get_or_create_state()
	
	%P1NavigationHintButtonLeft.texture = $InputIconMapper.get_icon($InputIconMapper.get_event_for_device(Player.INPUT_MAP[Player.PlayerNumber.ONE][Player.InputAction.MOVE].left, game_state.last_device_used[Player.PlayerNumber.ONE]))
	%P1NavigationHintButtonRight.texture = $InputIconMapper.get_icon($InputIconMapper.get_event_for_device(Player.INPUT_MAP[Player.PlayerNumber.ONE][Player.InputAction.MOVE].right, game_state.last_device_used[Player.PlayerNumber.ONE]))
	%P1SelectionHintButton.texture = $InputIconMapper.get_icon($InputIconMapper.get_event_for_device(Player.INPUT_MAP[Player.PlayerNumber.ONE][Player.InputAction.INTERACT_A], game_state.last_device_used[Player.PlayerNumber.ONE]))

	%P2NavigationHintButtonLeft.texture = $InputIconMapper.get_icon($InputIconMapper.get_event_for_device(Player.INPUT_MAP[Player.PlayerNumber.TWO][Player.InputAction.MOVE].left, game_state.last_device_used[Player.PlayerNumber.TWO]))
	%P2NavigationHintButtonRight.texture = $InputIconMapper.get_icon($InputIconMapper.get_event_for_device(Player.INPUT_MAP[Player.PlayerNumber.TWO][Player.InputAction.MOVE].right, game_state.last_device_used[Player.PlayerNumber.TWO]))
	%P2SelectionHintButton.texture = $InputIconMapper.get_icon($InputIconMapper.get_event_for_device(Player.INPUT_MAP[Player.PlayerNumber.TWO][Player.InputAction.INTERACT_A], game_state.last_device_used[Player.PlayerNumber.TWO]))

	%StartHintButton.texture = $InputIconMapper.get_icon($InputIconMapper.get_event_for_device("start_game", $InputIconMapper.last_joypad_device))

func _create_character_grids() -> void:
	assert(selection_manager)
	assert(selection_manager.character_database)

	var characters = selection_manager.character_database.get_all_characters()

	for player in Player.PlayerNumber.values():
		buttons[player].clear()

	for character in characters:
		_add_character_button(Player.PlayerNumber.ONE, p1_grid, character)
		_add_character_button(Player.PlayerNumber.TWO, p2_grid, character)

func _add_character_button(player: Player.PlayerNumber, grid: GridContainer, character) -> void:
	var btn: CharacterButton = character_button.instantiate()
	btn.setup(character)
	btn.focus_mode = Control.FOCUS_ALL
	btn.pressed.connect(_on_character_selected.bind(player, character.character_id))
	grid.add_child(btn)
	buttons[player].append(btn)

func _on_character_selected(player: Player.PlayerNumber, character_id: StringName) -> void:
	selection_manager.select_character(player, character_id)
	players_ready[player] = true
	_update_ui()

func _update_ui() -> void:
	_update_player_ui(Player.PlayerNumber.ONE)
	_update_player_ui(Player.PlayerNumber.TWO)

	var both_ready: bool = players_ready[Player.PlayerNumber.ONE] and players_ready[Player.PlayerNumber.TWO]
	start_button.disabled = not both_ready
	start_button.text = "SPIEL STARTEN" if both_ready else "Warte auf " + _waiting_players()

func _update_player_ui(player: Player.PlayerNumber) -> void:
	var game_state := GameState.get_or_create_state()
	var character = %CharacterSelectionManager.get_character_for_player(game_state, player)
	if not character:
		return

	if player == Player.PlayerNumber.ONE:
		p1_portrait.texture = character.portrait
		p1_name_label.text = character.display_name
		p1_ready_label.visible = players_ready[player]
	else:
		p2_portrait.texture = character.portrait
		p2_name_label.text = character.display_name
		p2_ready_label.visible = players_ready[player]

func _waiting_players() -> String:
	var list := []
	if not players_ready[Player.PlayerNumber.ONE]: list.append("P1")
	if not players_ready[Player.PlayerNumber.TWO]: list.append("P2")
	return " & ".join(list)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	
	var game_state := GameState.get_or_create_state()
	var device_name = InputEventHelper.get_device_name(event)
	for player in Player.PlayerNumber.values():
		if device_name != game_state.last_device_used[player] and Player._input_is_from_player(event) == player:
			game_state.last_device_used[player] = device_name
			GlobalState.save()
			_update_buttons_texture()

	if event.is_action_pressed("move_left_p1"):
		_navigate(Player.PlayerNumber.ONE, -1)
	elif event.is_action_pressed("move_right_p1"):
		_navigate(Player.PlayerNumber.ONE, +1)
	elif event.is_action_pressed("interact_a_p1"):
		_confirm(Player.PlayerNumber.ONE)

	elif event.is_action_pressed("move_left_p2"):
		_navigate(Player.PlayerNumber.TWO, -1)
	elif event.is_action_pressed("move_right_p2"):
		_navigate(Player.PlayerNumber.TWO, +1)
	elif event.is_action_pressed("interact_a_p2"):
		_confirm(Player.PlayerNumber.TWO)

	elif event.is_action_pressed("start_game") and players_ready[Player.PlayerNumber.ONE] and players_ready[Player.PlayerNumber.TWO]:
		_on_start_pressed()

	var viewport = get_viewport()
	if viewport: viewport.set_input_as_handled()

func _navigate(player: Player.PlayerNumber, direction: int) -> void:
	if buttons[player].is_empty():
		return

	focus_index[player] = wrapi(
		focus_index[player] + direction,
		0,
		buttons[player].size()
	)

	_update_focus(player)

func _update_focus(player: Player.PlayerNumber) -> void:
	for btn in buttons[player]:
		btn.set_player_focus(player, false)

	var focused_btn: CharacterButton = buttons[player][focus_index[player]]
	focused_btn.set_player_focus(player, true)

func _confirm(player: Player.PlayerNumber) -> void:
	var btn: CharacterButton = buttons[player][focus_index[player]]
	btn.pressed.emit()

func _on_start_pressed() -> void:
	selection_complete.emit()
	hide()
