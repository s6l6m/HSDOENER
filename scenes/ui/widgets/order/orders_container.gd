extends HBoxContainer
class_name OrdersContainer

@export var order_widget: PackedScene

var orders: Array[Order]

func on_add_order(order: Order, callback_time_finished: Callable):
	var scene: OrderWidget = order_widget.instantiate()
	scene.order = order
	scene.time_finished.connect(callback_time_finished)
	add_child(scene)
