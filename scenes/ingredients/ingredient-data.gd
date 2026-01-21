class_name Ingredient
extends "res://scripts/items/item_data.gd"

## Zeit in Sekunden, die für die Vorbereitung benötigt wird
@export var preparation_time: float = 0.0
## Bool, ob die Zutat bereits vorbereitet ist
@export var is_prepared: bool = false
## Icon-Textur für die vorbereitete Zutat
@export var cut_icon: Texture2D
