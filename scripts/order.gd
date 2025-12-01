class_name Order
extends PickableResource

## Order ist ein PickableResource (Resource + Pickable-Funktionalität)
## Kann vom Player gehalten und herumgetragen werden
## Erbt von PickableResource:
##   - Resource-Funktionalität (kann gespeichert werden)
##   - name, icon, description
##   - on_picked_up(), on_dropped()


@export var icon: Texture2D
@export var required_ingredients: Array[Ingredient] = []
@export var fulfilled_ingredients: Array[Ingredient] = []
@export var creation_time: int = 0
@export var price: float = 0.0
@export var time_limit: int = 0


var customer: Customer
var time_remaining: float = 0.0


func _init(_icon: Texture2D = null, _required_ingredients: Array[Ingredient] = [], _price: float = 0.0, _creation_time: int = 0, _time_limit: int = 0):
	icon = _icon
	required_ingredients = _required_ingredients
	price = _price
	creation_time = creation_time
	time_limit = _time_limit


# Bewertet die Bestellung, indem erfüllte mit benötigten Zutaten (inkl. Multiplizitäten) abgeglichen werden.
# Ermittelt matches, missing und wrong; berechnet base = matches/|required| und penalty = (missing+wrong)/|required|.
# Ergebnis ist base - penalty, auf den Bereich [-1.0, 1.0] beschränkt; leere Anforderungsliste liefert 0.0.
func evaluate_ingredients_fulfilled() -> float:
	if required_ingredients.is_empty():
		return 0.0

	var req_counts := {}
	for r in required_ingredients:
		req_counts[r] = (req_counts.get(r, 0) as int) + 1

	var matches := 0
	var wrong := 0

	for f in fulfilled_ingredients:
		if req_counts.has(f) and req_counts[f] > 0:
			matches += 1
			req_counts[f] -= 1
		else:
			wrong += 1

	var missing := 0
	for v in req_counts.values():
		missing += v

	var denom := float(required_ingredients.size())
	var base := float(matches) / denom
	var penalty := float(missing + wrong) / denom
	return clamp(base - penalty, -1.0, 1.0)

	
func evaluate_freshness() -> float:
	#TODO
	return 1
	
	
func _evaluate_time_left(current_time: int) -> float:
	var elapsed: int = current_time - self.creation_time
	
	# negative Zeiten abfangen
	if elapsed < 0:
		elapsed = 0
	
	# ungültiges time_limit absichern
	if time_limit <= 0:
		return 0.0
	
	# wenn limit überschritten, 0 zurückgeben
	if elapsed > time_limit:
		return 0.0
	
	# normalisierter Wert zwischen 0 und 1
	return float(elapsed) / float(time_limit)
