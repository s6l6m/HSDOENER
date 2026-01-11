class_name CharacterDatabase
extends Resource

## Alle verfügbaren Charaktere
@export var characters: Array[CharacterData] = []

## Charakter per ID finden
func get_character(character_id: StringName) -> CharacterData:
	for character in characters:
		if character.character_id == character_id:
			return character
	return null

## Alle Charaktere zurückgeben (für zukünftige Unlock-Logik)
func get_all_characters() -> Array[CharacterData]:
	return characters
