extends Node
class_name ScoreManager

# --- Signale ---
signal score_changed(new_score: int)
signal order_evaluated(order: Order, score_delta: int)

# --- Daten ---
var coins: int = 0


func update_coins(delta: int) -> void:
	coins += delta
	emit_signal("score_changed", coins)


func evaluate_order(order: Order, current_time: int):
	# Teilbewertungen aus der Order holen
	var ingredients_score := order.evaluate_ingredients_fulfilled()   # [-1..1]
	var freshness_score := order.evaluate_freshness()                # z.B. [0..1]
	var time_score := order._evaluate_time_left(current_time)         # [0..1]

	# Kombinierter Score 50 prozent machen ingredients aus, rest frische und zeit
	var combined_score := (
		ingredients_score * 0.5 +
		freshness_score   * 0.25 +
		time_score        * 0.25
	)
	# Coins-Änderung berechnen (Score * Preis)
	var coin_delta_float := combined_score * order.price
	var coin_delta := int(round(coin_delta_float))

	# Globalen Coin-Counter updaten
	update_coins(coin_delta)

	# Event nach außen melden
	emit_signal("order_evaluated", order, coin_delta)
