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
func evaluate_order(order: Order, time_left: int) -> int:
	var score: float = 0.0

	# --- 1) Richtige Zutaten prüfen ---
	for ing in order.fulfilled_ingredients:
		if ing in order.required_ingredients:
			score += 5
		else:
			score -= 5

	# --- 2) Alle fehlenden Zutaten ebenfalls bestrafen ---
	for ing in order.required_ingredients:
		if ing not in order.fulfilled_ingredients:
			score -= 5

	# --- 3) Zeitbonus hinzufügen ---
	# time_left / 120.0 ergibt einen Bonus zwischen 0.0 und 1.0 (oder mehr)
	var time_bonus := time_left / 120.0 * 10
	score += time_bonus

	# --- 4) Score auf Gesamtscore anwenden ---
	total_score += score
	emit_signal("score_changed", total_score)

	return score



# --- Setzt score hart
func set_score(value: int) -> void:
	# TODO
	pass


# --- Für Neustart / Game Reset ---
func reset_score() -> void:
	# TODO
	pass
