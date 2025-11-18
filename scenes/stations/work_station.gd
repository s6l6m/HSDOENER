@tool
extends Node2D
class_name WorkStation

enum Direction { DOWN, UP, LEFT, RIGHT }

@export var direction: Direction = Direction.UP:
	set(value):
		if direction == value:
			return
		direction = value
		update_direction()

var sprite_up: Texture2D = load("res://assets/workstations/workstation_up.png")
var sprite_down: Texture2D = load("res://assets/workstations/workstation_down.png")
var sprite_left: Texture2D = load("res://assets/workstations/workstation_down.png")
var sprite_right: Texture2D = load("res://assets/workstations/workstation_down.png")

@onready var table_sprite := $Sprite2D
@onready var CollisionBoxLarge := $Collision/CollisionShape2D
@onready var CollisionBoxSmall := $CollisionSmall/CollisionShape2D

@export var station_type = "workstation"
@onready var content = $Content

func _ready():
	update_direction()

func interact(player):
	if(content.visible):
		if(player.pickUp(content.texture)):
			content.visible = false
			content.texture = null
	else:
		if(player.heldItem.texture):
			content.texture = player.heldItem.texture
			content.visible = true
			player.layDown()
			print("Laying down item:", player.heldItem)
		else:
			print("Interacting with base station:", self.name)


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		body.enter_station(self)


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("players"):
		body.exit_station(self)

func update_direction():
	if not is_instance_valid(table_sprite):
		return
		
	
	CollisionBoxLarge.disabled = true
	CollisionBoxSmall.disabled = true
	
	match direction:
		Direction.UP:
			CollisionBoxLarge.disabled = false
			rotation_degrees = 0
			table_sprite.texture = sprite_up
		Direction.RIGHT:
			CollisionBoxSmall.disabled = false
			rotation_degrees = 90
			table_sprite.texture = sprite_right
		Direction.DOWN:
			CollisionBoxSmall.disabled = false
			rotation_degrees = 180
			table_sprite.texture = sprite_down
		Direction.LEFT:
			CollisionBoxSmall.disabled = false
			rotation_degrees = 270
			table_sprite.texture = sprite_left
