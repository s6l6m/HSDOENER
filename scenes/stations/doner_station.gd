@tool
extends WorkStation
class_name DonerStation

@export var burn_time := 10.0
var burn_timer := burn_time
var burn_level := 0
var timer_running := true

var ingredient_entity_scene := preload("res://scenes/items/ingredient_entity.tscn")
var meat_resource := preload("res://scenes/ingredients/fleisch.tres")
var burnt_meat_resource := preload("res://scenes/ingredients/fleisch-angebrannt.tres")

func _process(delta: float) -> void:
	if not timer_running:
		return
	if burn_timer <= 0:
		burn_level = 1
		update_texture()
		timer_running = false
	else:
		burn_timer -= delta

func interact(player: Player):
	var entity := ingredient_entity_scene.instantiate() as IngredientEntity
	entity.ingredient = burnt_meat_resource if burn_level == 1 else meat_resource
	var picked := player.pick_up_item(entity)
	if not picked and is_instance_valid(entity) and not entity.is_inside_tree():
		entity.free()

func interact_b(_player: Player):
	burn_level = 0
	update_texture()
	burn_timer = burn_time
	if(not timer_running):
		timer_running = true

func update_texture():
	var textures = [
		preload("res://assets/workstations/content/Doner_default.png"),
		preload("res://assets/workstations/content/Doner_burnt.png"),
	]
	content.texture = textures[burn_level]
