extends Node
class_name ScoreManager

signal order_evaluated(order: Order, score_delta: int)

func evaluate_order(order: Order, current_time: int):
	# Teilbewertungen aus der Order holen
	var ingredients_score := order.evaluate_ingredients_fulfilled()   # [-1..1]
	var freshness_score := order.evaluate_freshness()                # z.B. [0..1]
	var time_score := order._evaluate_time_left(current_time)         # [0..1]

	# Kombinierter Score 50 prozent machen ingredients aus, rest frische und zeit
	var combined_score := (
		ingredients_score * 0.5 +
		freshness_score   * 0 +
		time_score        * 0
	)

	# Coins-Änderung berechnen (Score * Preis)
	var coin_delta_float := combined_score * order.price
	var coin_delta := int(round(coin_delta_float))

	print("[ScoreManager] Order bewerten:",
		" ingredients_score=", ingredients_score,
		" time_score=", time_score,
		" combined=", combined_score,
		" price=", order.price,
		" coin_delta=", coin_delta)

	order_evaluated.emit(order, coin_delta)
