extends Node

signal order_added(order)
signal order_completed(order)
signal order_removed(order)

var orders: Array[Order] = []

func create_order(customer: Node, items: Array[String]) -> Order:
	var order = Order.new()
	order.id = orders.size() + 1
	order.customer = customer
	order.items = items
	order.is_completed = false

	orders.append(order)
	emit_signal("order_added", order)
	return order

func complete_order(order: Order):
	if order in orders:
		order.is_completed = true
		emit_signal("order_completed", order)

func remove_order(order: Order):
	if order in orders:
		orders.erase(order)
		emit_signal("order_removed", order)
