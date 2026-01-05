class_name GameManager
extends Node

@export_category("Managers")
@export var time_manager: TimeManager
@export var order_manager: OrderManager
@export var customer_manager: CustomerManager
@export var score_manager: ScoreManager

@export_category("Widgets")
@export var timer_widget: TimerWidget
@export var coin_widget: CoinWidget

@onready var current_level: Level = $".."

func _ready() -> void:
	_update_time_left()
	time_manager.play_time_changed.connect(_update_time_left)
	order_manager.order_completed.connect(_on_order_completed)
	score_manager.order_evaluated.connect(_on_order_evaluated)

func _process(_delta):
	# Test-Input: Kunde per Tastendruck spawnen
	if Input.is_action_just_pressed("spawn_customer"):
		customer_manager.spawn_customer(current_level.difficulty)

func _update_time_left(play_time: int = 0):
	var time_left: int = current_level.round_time - play_time
	if time_left <= 0:
		current_level._on_level_time_up()
	timer_widget._on_play_time_changed(time_left)

func _update_coins(coins: int):
	coin_widget.update_coins(coins)

func _on_order_completed(order: Order):
	score_manager.evaluate_order(order, time_manager.play_time)

func _on_order_evaluated(_order: Order, coin_delta: int):
	AudioPlayerManager.play(AudioPlayerManager.AudioID.COIN_UP if coin_delta > 0 else AudioPlayerManager.AudioID.COIN_DOWN)
	var new_coin_count := current_level.add_coins(coin_delta)
	_update_coins(new_coin_count)
	if current_level._target_coins_reached():
		current_level._on_level_won()
