class_name CharacterData
extends Resource

## Eindeutige ID für Matching
@export var character_id: StringName = ""

## Anzeigename im UI
@export var display_name: String = ""

## Portrait für Selection-Screen (128x128px empfohlen)
@export var portrait: Texture2D

## Sprite-Frames für Gameplay
@export var sprite_frames: SpriteFrames

## Optional: Beschreibung
@export_multiline var description: String = ""
