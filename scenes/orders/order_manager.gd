extends Node
class_name OrderManager

signal order_added(order: Order, callback_time_finished: Callable)
signal order_completed(order: Order)

@onready var doener_generator: DonerGenerator = %DoenerGenerator
@onready var orders_container: OrdersContainer = %OrdersContainer
@onready var time_manager: TimeManager = %TimeManager

var orders: Array[Order] = []

func _ready() -> void:
	order_added.connect(orders_container.on_add_order)
	order_completed.connect(orders_container.on_remove_order)

func complete_order(order: Order) -> void:
	if order in orders:
		order.customer.leave_queue()
		orders.erase(order)

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
