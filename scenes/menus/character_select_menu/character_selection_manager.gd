extends Node
class_name CharacterSelectionManager

signal selection_changed(player_number: int, character_id: StringName)

@export var character_database: CharacterDatabase

func _ready() -> void:
	assert(character_database)
	var game_state := GameState.get_or_create_state()
	if character_database:
		game_state.character_database = character_database
		GlobalState.save()

func select_character(player_number: Player.PlayerNumber, character_id: StringName) -> void:
	if character_database.get_character(character_id):
		var game_state := GameState.get_or_create_state()
		game_state.character_selections[player_number] = character_id
		selection_changed.emit(player_number, character_id)
	else:
		push_warning("Character ID not found: %s" % character_id)

func get_character_for_player(game_state: GameState, player_number: Player.PlayerNumber) -> CharacterData:
	var character_id = game_state.character_selections.get(player_number, game_state.character_database.characters[0].character_id)
	var character := game_state.character_database.get_character(character_id)
	return character

static func get_sprite_frames_for_player(game_state: GameState, player_number: Player.PlayerNumber) -> SpriteFrames:
	var character_id = game_state.character_selections.get(player_number)
	var character = game_state.character_database.get_character(character_id)
	return character.sprite_frames if character else null
