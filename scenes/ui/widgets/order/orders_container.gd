extends HBoxContainer
class_name OrdersContainer

@export var orders: Array[Order]
@export var order_widget: PackedScene
@export var order_manager: OrderManager

func _ready() -> void:
	order_manager.order_added.connect(on_add_order)

func on_add_order(order: Order):
	var scene: OrderWidget = order_widget.instantiate()
	scene.order = order
	scene.order_wait_time = order.time_limit
	scene.dish = order.icon
	var ingredients_textures: Array[Texture2D] = []
	for ingredient in order.required_ingredients:
		ingredients_textures.append(ingredient.icon)
	scene.ingredients = ingredients_textures
	scene.time_finished.connect(order_manager.remove_order)
	add_child(scene)
