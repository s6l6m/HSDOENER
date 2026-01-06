extends Control
class_name CoinWidget

@onready var coin_label: Label = %CoinLabel

func update_coins(coins: int):
	if not is_node_ready():
		await ready
	coin_label.text = str(coins)
