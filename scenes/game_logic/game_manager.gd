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
	
	# Starte automatisches Spawning basierend auf Schwierigkeitsgrad
	customer_manager.start_auto_spawning(current_level)

func _process(_delta):
	# Test-Input: Kunde per Tastendruck spawnen
	if Input.is_action_just_pressed("spawn_customer"):
		customer_manager.spawn_customer(current_level.difficulty)

func _update_time_left(play_time: int = 0):
	var time_left: int = current_level.round_time - play_time
	if time_left <= 0:
		# Stoppe automatisches Spawning wenn Zeit abgelaufen
		customer_manager.stop_auto_spawning()
		current_level._on_level_lost()
	timer_widget._on_play_time_changed(time_left)

func _update_coins(coins: int):
	coin_widget.update_coins(coins)

func _on_order_completed(order: Order):
	print("[GameManager] order_completed erhalten:", order)
	score_manager.evaluate_order(order, time_manager.play_time)

func _on_order_evaluated(_order: Order, coin_delta: int):
	var new_coin_count := current_level.add_coins(coin_delta)
	print("[GameManager] order_evaluated coin_delta=", coin_delta, " coins_total=", new_coin_count)
	_update_coins(new_coin_count)
