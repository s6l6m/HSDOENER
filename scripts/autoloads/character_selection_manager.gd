extends Node

signal selection_changed(player_number: int, character_id: StringName)

var character_database: CharacterDatabase
var selections: Dictionary = {}

const DEFAULT_P1 := &"chef_one"
const DEFAULT_P2 := &"chef_two"

func _ready() -> void:
	character_database = load("res://resources/characters/character_database.tres")

	if not character_database:
		push_error("Failed to load character database!")
		return

	reset_to_defaults()

func reset_to_defaults() -> void:
	selections[0] = DEFAULT_P1
	selections[1] = DEFAULT_P2

func select_character(player_number: int, character_id: StringName) -> void:
	if character_database.get_character(character_id):
		selections[player_number] = character_id
		selection_changed.emit(player_number, character_id)
	else:
		push_warning("Character ID not found: %s" % character_id)

func get_character_for_player(player_number: int) -> CharacterData:
	var character_id = selections.get(player_number, DEFAULT_P1)
	return character_database.get_character(character_id)

func get_sprite_frames_for_player(player_number: int) -> SpriteFrames:
	var character = get_character_for_player(player_number)
	return character.sprite_frames if character else null
