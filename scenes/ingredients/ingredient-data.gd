class_name Ingredient
extends PickableResource

## Ingredient ist ein PickableResource (Resource + Pickable-Funktionalität)
## Erbt von PickableResource:
##   - Resource-Funktionalität (kann gespeichert werden als .tres)
##   - name, icon, description
##   - on_picked_up(), on_dropped()
##   - can_combine_with(), combine_with()

# Zusätzliche Ingredient-spezifische Eigenschaften
@export var preparation_time: float = 0.0  # Zeit zum Schneiden/Vorbereiten
@export var is_prepared: bool = false  # Wurde geschnitten/vorbereitet
@export var cut_icon: Texture2D  # Icon wenn geschnitten
