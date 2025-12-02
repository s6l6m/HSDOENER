extends HBoxContainer
class_name OrdersContainer

@export var order_widget: PackedScene

var orders: Array[Order]

func on_add_order(order: Order, callback_time_finished: Callable):
	var scene: OrderWidget = order_widget.instantiate()
	scene.order = order
	scene.order_wait_time = order.time_limit
	scene.dish = order.icon
	var ingredients_textures: Array[Texture2D] = []
	for ingredient in order.required_ingredients:
		ingredients_textures.append(ingredient.icon)
	scene.ingredients = ingredients_textures
	scene.time_finished.connect(callback_time_finished)
	add_child(scene)
