@tool
extends Control
class_name OrderWidget

@onready var timer_bar = %TimerProgress
@onready var ingredients_container: HBoxContainer = %IngredientsContainer
@onready var dish_icon: TextureRect = %DishIcon

@export var order: Order
@export var order_wait_time: float
@export var dish: Texture2D
@export var ingredients: Array[Texture2D] = []
@export var ingredient_scene: PackedScene

var time_left: float = 0.0
var timer_running: bool = false

signal time_finished(order: Order)

func _ready():
	time_left = order_wait_time
	timer_running = true
	
	_update_dish_icon()
	_update_ingredients()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		# In editor, update visuals live
		_update_dish_icon()
		_update_ingredients()
		return

	if not timer_running:
		return

	time_left -= delta
	if time_left < 0:
		time_left = 0
	timer_bar.update_progress(time_left, order_wait_time)

	if time_left <= 0 and timer_running:
		_on_timer_finished()

func _on_timer_finished() -> void:
	timer_running = false
	time_finished.emit(order)
	queue_free()

func _update_dish_icon() -> void:
	if dish_icon:
		dish_icon.texture = dish

func _update_ingredients() -> void:
	if not ingredients_container or not ingredient_scene:
		return

	for child in ingredients_container.get_children():
		child.queue_free()

	for ingredient_texture in ingredients:
		var ingredient_instance = ingredient_scene.instantiate()
		if ingredient_instance.has_method("set_icon"):
			ingredient_instance.set_icon(ingredient_texture)
		elif "icon" in ingredient_instance:
			ingredient_instance.icon = ingredient_texture
		ingredients_container.add_child(ingredient_instance)

func _set_dish(value):
	dish = value
	if Engine.is_editor_hint():
		_update_dish_icon()

func _set_ingredients(value):
	ingredients = value
	if Engine.is_editor_hint():
		_update_ingredients()
