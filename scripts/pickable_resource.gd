class_name PickableResource
extends Resource

## Zwischenklasse: Resource mit Pickable-Funktionalität
## Alle Items die der Player aufheben kann erben von dieser Klasse
## Ingredients und Orders sind PickableResources
## 
## Hierarchie:
##   Resource (Godot)
##     └── PickableResource (diese Klasse)
##          ├── Ingredient
##          └── Order

@export var name: String = ""
@export var icon: Texture2D
@export var description: String = ""

func _init(_name: String = "", _icon: Texture2D = null, _description: String = ""):
	name = _name
	icon = _icon
	description = _description

## Wird aufgerufen wenn Player das Item aufhebt
func on_picked_up() -> void:
	pass

## Wird aufgerufen wenn Player das Item ablegt
func on_dropped() -> void:
	pass

## Gibt zurück ob das Item mit einem anderen kombiniert werden kann
func can_combine_with(other: PickableResource) -> bool:
	return false

## Kombiniert dieses Item mit einem anderen
func combine_with(other: PickableResource) -> PickableResource:
	return null

## Prüft ob dies ein Ingredient ist
## Nutzt String-Vergleich um zirkuläre Abhängigkeiten zu vermeiden
func is_ingredient() -> bool:
	var script_instance = get_script()
	if script_instance == null:
		return false
	return script_instance.resource_path.ends_with("ingredient-data.gd")

## Prüft ob dies eine Order ist
## Nutzt String-Vergleich um zirkuläre Abhängigkeiten zu vermeiden  
func is_order() -> bool:
	var script_instance = get_script()
	if script_instance == null:
		return false
	return script_instance.resource_path.ends_with("order.gd")
