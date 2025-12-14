@tool
extends WorkStation
class_name DonerStation

@export var burn_time := 10.0
var burn_timer := burn_time
var burn_level := 0
var timer_running := true

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
	if not player.isHoldingPlate():
		print("Du brauchst einen Teller!")

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
