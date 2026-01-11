@tool
extends WorkStation
class_name TomatoStation

# =====================================================
# Resources
# =====================================================
var tomato_resource := preload("res://scenes/ingredients/tomate.tres")
var ingredient_entity_scene := preload("res://scenes/items/ingredient_entity.tscn")

# =====================================================
# Interaction
# =====================================================
func interact(player: Player):
	var held := player.get_held_item()
	# Require prepared ingredient when adding directly to a doner.
	if held is DonerEntity and tomato_resource.cut_icon != null and not tomato_resource.is_prepared:
		print("Tomate muss erst geschnitten werden.")
		return

	var entity := ingredient_entity_scene.instantiate() as IngredientEntity
	entity.ingredient = tomato_resource
	var picked := player.pick_up_item(entity)
	if not picked and is_instance_valid(entity) and not entity.is_inside_tree():
		entity.free()
	else:
		AudioPlayerManager.play(AudioPlayerManager.AudioID.PLAYER_GRAB)
