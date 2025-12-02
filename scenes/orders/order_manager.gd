extends Node
class_name OrderManager

enum Difficulty {
	EASY,
	MEDIUM,
	HARD
}

signal order_added(order: Order, callback_time_finished: Callable)
signal order_completed(order: Order)
signal order_removed(order: Order)

@onready var doener_generator: DonerGenerator = %DoenerGenerator
@onready var orders_container: OrdersContainer = %OrdersContainer

var orders: Array[Order] = []

func _ready() -> void:
	self.order_added.connect(orders_container.on_add_order)

func complete_order(order: Order) -> void:
	if order in orders:
		emit_signal("order_completed", order)
		remove_order(order)

func remove_order(order: Order) -> void:
	order.customer.customer_left.emit(order.customer)
	orders.erase(order)
	emit_signal("order_removed", order)

func create_doner_order(customer: Customer, difficulty: Difficulty ) -> Order:
	var ingredients : Array[Ingredient]
	var price: int
	var time_limit: int

	match difficulty:
		Difficulty.EASY:
			ingredients = doener_generator.generate_small_doner()
			price = randi_range(3, 10)
			time_limit = randi_range(15, 20)
		Difficulty.MEDIUM:
			ingredients = doener_generator.generate_mid_doner()
			price = randi_range(5, 15)
			time_limit = randi_range(20, 40)
		Difficulty.HARD:
			ingredients = doener_generator.generate_big_doner()
			price = randi_range(15, 25)
			time_limit = randi_range(30, 60)
	
	var order := Order.new(
		preload("res://assets/food/items/warp-item.png"),
		ingredients,
		price,
		%TimeManager.play_time,
		time_limit,
	)

	order.customer = customer
	orders.append(order)
	
	
	emit_signal("order_added", order, remove_order)
	return order
