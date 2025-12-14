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

func _process(_delta):
	# Test-Input: Kunde per Tastendruck spawnen
	if Input.is_action_just_pressed("spawn_customer"):
		customer_manager.spawn_customer()

func _update_time_left(play_time: int = 0):
	var time_left: int = current_level.round_time - play_time
	if time_left <= 0:
		current_level._on_level_lost()
	timer_widget._on_play_time_changed(time_left)

func _update_coins(coins: int):
	coin_widget.update_coins(coins)
