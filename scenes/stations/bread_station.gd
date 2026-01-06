@tool
extends WorkStation
class_name BreadStation

var bread_resource = load("res://scenes/ingredients/brot.tres")
var ingredient_entity_scene := preload("res://scenes/items/ingredient_entity.tscn")

func interact(player: Player):
	var entity := ingredient_entity_scene.instantiate() as IngredientEntity
	entity.ingredient = bread_resource
	var picked := player.pick_up_item(entity)
	if not picked and is_instance_valid(entity) and not entity.is_inside_tree():
		entity.free()
	else:
		AudioPlayerManager.play(AudioPlayerManager.AudioID.PLAYER_GRAB)
