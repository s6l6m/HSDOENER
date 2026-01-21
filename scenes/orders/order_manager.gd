extends Node
class_name OrderManager

## Signal, wenn eine neue Order hinzugefügt wird (mit Callback für Zeitablauf)
signal order_added(order: Order, callback_time_finished: Callable)
## Signal, wenn eine Order abgeschlossen ist
signal order_completed(order: Order)

## Referenz zum Döner-Generator für Zutaten-Erstellung
@onready var doener_generator: DonerGenerator = %DoenerGenerator
## Referenz zum Orders-Container für UI-Verwaltung
@onready var orders_container: OrdersContainer = %OrdersContainer
## Referenz zum Time-Manager für Zeit-Tracking
@onready var time_manager: TimeManager = %TimeManager

## Array aller aktiven Orders
var orders: Array[Order] = []

## Initialisiert Verbindungen für Signale
func _ready() -> void:
	order_added.connect(orders_container.on_add_order)
	order_completed.connect(orders_container.on_remove_order)

## Schließt eine Order ab und entfernt sie aus der Liste
func complete_order(order: Order) -> void:
	if order in orders:
		order.customer.leave_queue()
		orders.erase(order)

## Erstellt eine neue Döner-Order basierend auf Schwierigkeit und Kunde
func create_doner_order(customer: Customer, difficulty: Level.Difficulty) -> Order:
	var ingredients : Array[Ingredient]
	var price: int
	var time_limit: int

	price = 0
	time_limit = 0
	match difficulty:
		Level.Difficulty.EASY:
			ingredients = doener_generator.generate_small_doner()
			for i in ingredients:
				price += 1
				time_limit += 12
		Level.Difficulty.MEDIUM:
			ingredients = doener_generator.generate_mid_doner()
			for i in ingredients:
				price += 1
				time_limit += 10
		Level.Difficulty.HARD:
			ingredients = doener_generator.generate_big_doner()
			for i in ingredients:
				price += 1
				time_limit += 8
	
	var order := Order.new(
		ingredients,
		price,
		time_manager.play_time,
		time_limit,
	)
	
	order.customer = customer
	orders.append(order)
	
	order_added.emit(order, complete_order)
	return order
