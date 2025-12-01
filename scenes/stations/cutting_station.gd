@tool
extends WorkStation
class_name CuttingStation

var stored_ingredient: Ingredient
@onready var food: Sprite2D = $Food

func interact(player):
	# for now only pick up/lay down
	var held = player.getHeldPickable()
	if stored_ingredient != null:
		if player.pickUpPickable(stored_ingredient):
			if stored_ingredient is Ingredient:
				stored_ingredient.remove_from_workstation()
			stored_ingredient = null
			update_visual()
		return
		
	if held != null:
		stored_ingredient = held
		if stored_ingredient is Ingredient:
			stored_ingredient.put_into_workstation()
		player.dropPickable()
		update_visual()

func update_visual():
	if stored_ingredient == null:
		food.visible = false
		return
	food.texture = stored_ingredient.icon
	food.modulate = stored_ingredient.get_icon_tint()
	food.visible = true
