extends Control
class_name CoinWidget

@onready var coin_label: Label = %CoinLabel

func update_coins(coins: int):
	coin_label.text = str(coins)
