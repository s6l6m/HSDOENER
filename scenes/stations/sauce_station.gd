@tool
extends WorkStation
class_name SauceStation

func interact(player: Player):
	var sauce_resource := preload("res://scenes/ingredients/sosse.tres")
	var ingredient_entity_scene := preload("res://scenes/items/ingredient_entity.tscn")
	var entity := ingredient_entity_scene.instantiate() as IngredientEntity
	entity.ingredient = sauce_resource
	var picked := player.pick_up_item(entity)
	if not picked and is_instance_valid(entity) and not entity.is_inside_tree():
		entity.free()

func interact_b(player: Player):
	interact(player)
