extends HBoxContainer
class_name OrdersContainer

@export var orders: Array[Order]
@export var order_widget: PackedScene

@onready var order_manager: OrderManager = %OrderManager

func _ready() -> void:
	if order_manager:
		order_manager.order_added.connect(on_add_order)
	else:
		push_error("OrderManager not found!")

func on_add_order(order: Order):
	if order_widget.can_instantiate():
		var scene: OrderWidget = order_widget.instantiate()
		scene.order_wait_time = randi_range(10, 60) # TODO: Change Values to match gameplay
		scene.dish = order.icon
		var ingredients_textures: Array[Texture2D] = []
		for ingredient in order.required_ingredients:
			ingredients_textures.append(ingredient.icon)
		scene.ingredients = ingredients_textures
		scene.time_finished.connect(order_manager.remove_order)
		add_child(scene)
