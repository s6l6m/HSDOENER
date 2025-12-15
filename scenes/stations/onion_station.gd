@tool
extends WorkStation
class_name OnionStation

var onion_resource := preload("res://scenes/ingredients/zwiebel.tres")
var ingredient_entity_scene := preload("res://scenes/items/ingredient_entity.tscn")

func interact(player: Player):
	var held := player.get_held_item()
	if held is DonerEntity and onion_resource.cut_icon != null and not onion_resource.is_prepared:
		print("Zwiebel muss erst geschnitten werden.")
		return
	var entity := ingredient_entity_scene.instantiate() as IngredientEntity
	entity.ingredient = onion_resource
	var picked := player.pick_up_item(entity)
	if not picked and is_instance_valid(entity) and not entity.is_inside_tree():
		entity.free()
