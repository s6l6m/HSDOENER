class_name Order
extends Resource

@export var required_ingredients: Array[Ingredient] = []
var fulfilled_ingredients: Array[Ingredient] = []
## Gespeicherte Frische-Daten der erfüllten Zutaten (Dictionary-Array)
var fulfilled_freshness_data: Array[Dictionary] = []
@export var creation_time: int = 0
@export var price: int = 0
@export var time_limit: int = 0

var customer: Customer
var time_remaining: float = 0.0

func _init(_required_ingredients: Array[Ingredient] = [], _price: int = 0, _creation_time: int = 0, _time_limit: int = 0):
	required_ingredients = _required_ingredients
	price = _price
	creation_time = _creation_time
	time_limit = _time_limit

# Bewertet die Bestellung, indem erfüllte mit benötigten Zutaten (inkl. Multiplizitäten) abgeglichen werden.
# Ermittelt matches, missing und wrong; berechnet base = matches/|required| und penalty = (missing+wrong)/|required|.
# Ergebnis ist base - penalty, auf den Bereich [-1.0, 1.0] beschränkt; leere Anforderungsliste liefert 0.0.
func evaluate_ingredients_fulfilled() -> float:
	if required_ingredients.is_empty():
		return 0.0

	# Count required ingredient IDs (supports multiplicities).
	var req_counts := {}
	for r in required_ingredients:
		var id := r.item_id
		req_counts[id] = (req_counts.get(id, 0) as int) + 1

	var matches := 0
	var wrong := 0

	for f in fulfilled_ingredients:
		if f == null:
			continue
		var f_id := f.item_id
		if req_counts.has(f_id) and req_counts[f_id] > 0:
			matches += 1
			req_counts[f_id] -= 1
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
	if fulfilled_freshness_data.is_empty():
		print("[Order] Keine Freshness-Daten, Frische: 1.0")
		return 1.0
	
	var total_freshness := 0.0
	var vegetable_count := 0
	
	for data in fulfilled_freshness_data:
		print("[Order] Prüfe Data: ingredient: ", data.ingredient.name if data.ingredient else "null", " is_vegetable: ", data.is_vegetable)
		## Berechne Frische nur für Gemüse basierend auf gespeicherten Daten
		if data.is_vegetable:
			var elapsed_sec: float = (Time.get_ticks_msec() - data.creation_time) / 1000.0
			var freshness: float = clamp(1.0 - (elapsed_sec / 60.0), 0.0, 1.0)  # freshness_duration = 60.0
			print("[Order] Gemüse Frische berechnet: elapsed=", elapsed_sec, "s, freshness=", freshness)
			total_freshness += freshness
			vegetable_count += 1
	
	if vegetable_count == 0:
		print("[Order] Keine Gemüse, Frische: 1.0")
		return 1.0  # Wenn keine Gemüse, volle Frische
	
	var avg_freshness := total_freshness / vegetable_count
	print("[Order] Frische evaluiert: ", vegetable_count, " Gemüse, Durchschnitt: ", avg_freshness)
	return avg_freshness
	
	
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
	return 1.0 - (float(elapsed) / float(time_limit))

func printIngredients():
	for i in fulfilled_ingredients:
		if i != null:
			print(i.name)
