extends Node
class_name OrderManager

signal order_added(order: Order)
signal order_completed(order: Order)
signal order_removed(order: Order)

@onready var doner_generator: DonerGenerator = $"doener-generator"

var orders: Array[Order] = []

func complete_order(order: Order) -> void:
	if order in orders:
		emit_signal("order_completed", order)
		remove_order(order)

func remove_order(order: Order) -> void:
	if order in orders:
		orders.erase(order)
		emit_signal("order_removed", order)

func create_doner_order(customer: Node) -> Order:
	var ingredients := doner_generator.generate_doner()

	var order := Order.new(
		preload("res://assets/food/items/warp-item.png"),
		ingredients,
	)

	order.customer = customer
	order.is_complete.connect(complete_order)
	orders.append(order)

	emit_signal("order_added", order)
	return order
