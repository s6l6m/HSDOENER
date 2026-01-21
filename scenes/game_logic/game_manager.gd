## Hauptspiellogik
## verbindet die einzelnen Manager
class_name GameManager
extends Node

@export_category("Managers")
## Manager für Zeit-Tracking
@export var time_manager: TimeManager
## Manager für Order-Verwaltung
@export var order_manager: OrderManager
## Manager für Kunden-Spawning
@export var customer_manager: CustomerManager
## Manager für Score-Berechnung
@export var score_manager: ScoreManager

@export_category("Widgets")
## Widget für Timer-Anzeige
@export var timer_widget: TimerWidget
## Widget für Münzen-Anzeige
@export var coin_widget: CoinWidget

## Referenz zum aktuellen Level
@onready var current_level: Level = $".."

## Initialisiert Widgets und verbindet Signale
func _ready() -> void:
	_init_widgets()
	
	# Connect signals
	time_manager.play_time_changed.connect(_update_time_left)
	order_manager.order_completed.connect(_on_order_completed)
	score_manager.order_evaluated.connect(_on_order_evaluated)
	
	# Starte automatisches Spawning basierend auf Schwierigkeitsgrad
	customer_manager.start_auto_spawning(current_level)

## Verarbeitet Test-Input für Kunden-Spawning
func _process(_delta):
	# Test-Input: Kunde per Tastendruck spawnen
	if Input.is_action_just_pressed("spawn_customer"):
		customer_manager.spawn_customer(current_level.difficulty)
 
## Initialisiert UI-Widgets mit Startwerten
func _init_widgets() -> void:
	_update_time_left()
	coin_widget.update_coins(current_level.level_state.coins if current_level.level_state else 0)
	coin_widget.update_coins_goal(current_level.target_coins)
	
## Aktualisiert verbleibende Zeit und stoppt Spawning bei Zeitablauf
func _update_time_left(play_time: int = 0) -> void:
	var time_left: int = current_level.round_time - play_time
	if time_left <= 0:
		# Stoppe automatisches Spawning wenn Zeit abgelaufen
		customer_manager.stop_auto_spawning()
		current_level._on_level_time_up()
	timer_widget._on_play_time_changed(time_left)

## Wird aufgerufen, wenn eine Order abgeschlossen ist; startet Bewertung
func _on_order_completed(order: Order):
	print("[GameManager] order_completed erhalten:", order)
	score_manager.evaluate_order(order, time_manager.play_time)

## Wird aufgerufen, wenn Order bewertet ist; aktualisiert Coins und prüft Level-Ziel
func _on_order_evaluated(_order: Order, coin_delta: int):
	AudioPlayerManager.play(AudioPlayerManager.AudioID.COIN_UP if coin_delta > 0 else AudioPlayerManager.AudioID.COIN_DOWN)
	var new_coin_count := current_level.add_coins(coin_delta)
	print("[GameManager] order_evaluated coin_delta=", coin_delta, " coins_total=", new_coin_count)
	coin_widget.update_coins(new_coin_count, coin_widget.PulseMode.GREEN if coin_delta > 0 else coin_widget.PulseMode.RED)
	if current_level._target_coins_reached():
		current_level._on_level_won()
