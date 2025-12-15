@tool
extends WorkStation
class_name PlateStation

var doner_entity_scene := preload("res://scenes/items/doner_entity.tscn")

func interact(player: Player):
	var doner := doner_entity_scene.instantiate() as DonerEntity
	doner.show_plate_visual = true
	var picked := player.pick_up_item(doner)
	if not picked and is_instance_valid(doner) and not doner.is_inside_tree():
		doner.free()
