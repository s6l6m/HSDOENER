@tool
extends Control
class_name OrderWidget

@onready var timer_bar = %TimerProgress
@onready var ingredients_container: HBoxContainer = %IngredientsContainer
@onready var dish_icon: TextureRect = %DishIcon
@onready var price_label: Label = %PriceLabel

var _order: Order
@export var order: Order:
	get:
		return _order
	set(value):
		_order = value
		if Engine.is_editor_hint():
			_load_order_editor_preview()

@export var ingredient_scene: PackedScene

var order_wait_time: float
var dish: Texture2D
var ingredients: Array[Texture2D] = []
var time_left: float = 0.0
var timer_running: bool = false

signal time_finished(order: Order)

func _ready():
	if Engine.is_editor_hint():
		_load_order_editor_preview()
		return

	_load_order_runtime()
	timer_running = true


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if not timer_running:
		return

	time_left -= delta
	time_left = max(time_left, 0.0)

	timer_bar.update_progress(time_left, order_wait_time)

	if time_left <= 0.0:
		_on_timer_finished()


func _load_order_runtime():
	if not order:
		return

	order_wait_time = order.time_limit
	time_left = order_wait_time

	dish = order.icon
	ingredients.clear()
	for ingredient in order.required_ingredients:
		ingredients.append(ingredient.icon)

	if order.customer:
		self_modulate = order.customer.color

	_update_dish_icon()
	_update_ingredients()
	_update_price_label()


func _load_order_editor_preview():
	if not order:
		dish = null
		ingredients.clear()
		time_left = 0
		timer_running = false
		order_wait_time = 0
		_update_price_label()
		return

	dish = order.icon

	ingredients.clear()
	for ingredient in order.required_ingredients:
		ingredients.append(ingredient.icon)

	_update_dish_icon()
	_update_ingredients()
	_update_price_label()

func _update_dish_icon():
	if dish_icon:
		dish_icon.texture = dish

func _update_price_label():
	if price_label:
		price_label.text = str(order.price) if order.price else "-"

func _update_ingredients():
	if not ingredients_container or not ingredient_scene:
		return

	for child in ingredients_container.get_children():
		child.queue_free()

	for ingredient_texture in ingredients:
		var instance = ingredient_scene.instantiate()
		if instance.has_method("set_icon"):
			instance.set_icon(ingredient_texture)
		elif "icon" in instance:
			instance.icon = ingredient_texture
		ingredients_container.add_child(instance)


func _on_timer_finished():
	timer_running = false
	time_finished.emit(order)
	queue_free()
