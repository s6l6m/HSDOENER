extends Node

signal order_added(order)
signal order_completed(order)
signal order_removed(order)

@onready var doner_generator: DonerGenerator = $"doener-generator"


var orders: Array[Order] = []

func complete_order(order: Order):
	if order in orders:
		order.is_completed = true
		emit_signal("order_completed", order)

func remove_order(order: Order):
	if order in orders:
		orders.erase(order)
		emit_signal("order_removed", order)

func create_doner_order(customer: Node) -> Order:
	var ingredients := doner_generator.generate_doner()

	var order = Order.new()
	order.id = orders.size() + 1
	order.customer = customer
	order.ingredients = ingredients
	order.is_completed = false

	orders.append(order)
	emit_signal("order_added", order)
	return order
