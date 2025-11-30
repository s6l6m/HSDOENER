extends Node
class_name ScoreManager

# --- Signale ---
signal score_changed(new_score)
signal order_evaluated(order, score_delta)

# --- Daten ---
var total_score: int = 0


# --- Score erhöhen ---
func add_score(amount: int) -> void:
	# TODO
	pass


# --- Score senken ---
func subtract_score(amount: int) -> void:
	# TODO
	pass


# --- Bestellung bewerten ---
func evaluate_order(order: Order) -> int:
	var score := 0

	# Kopie erstellen, damit wir nicht am Original herumbasteln
	var required := order.required_ingredients.duplicate()
	var fulfilled := order.fulfilled_ingredients.duplicate()

	# KORREKTE ZUTATEN
	for ing in fulfilled:
		if ing in required:
			score += 5
			required.erase(ing) # Verhindert Doppelwertung
		else:
			score -= 5

	# FEHLENDE ZUTATEN
	score -= required.size() * 5

	total_score += score

	return score



# --- Setzt score hart
func set_score(value: int) -> void:
	# TODO: direkt setzen + Signal senden
	pass


# --- Für Neustart / Game Reset ---
func reset_score() -> void:
	# TODO
	pass
