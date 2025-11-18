extends Control

@onready var timer_bar = %TimerProgress
@onready var ingredients_container: HBoxContainer = %IngredientsContainer
@onready var dish_icon: TextureRect = %DishIcon

@export var order_wait_time := 20.0
@export var dish: Texture
@export var ingredients: Array[Texture] = []
@export var ingredient_scene: PackedScene

var time_left: float = 0.0
var timer_running: bool = false

signal time_updated(value: float)
signal time_finished()

func _ready():
	time_left = order_wait_time
	timer_running = true
	
	dish_icon.texture = dish
	
	for child in ingredients_container.get_children():
		child.queue_free()

	for ingredient_texture in ingredients:
		var ingredient_instance = ingredient_scene.instantiate()
		ingredient_instance.icon = ingredient_texture
		ingredients_container.add_child(ingredient_instance)

func _process(delta: float) -> void:
	if not timer_running:
		return

	time_left -= delta
	if time_left < 0:
		time_left = 0
	timer_bar.update_progress(time_left, order_wait_time)

	emit_signal("time_updated", time_left)

	if time_left <= 0 and timer_running:
		timer_running = false
		emit_signal("time_finished")
		_on_timer_finished()

func _on_timer_finished() -> void:
	queue_free()
