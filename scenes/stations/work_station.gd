@tool
extends Node2D
class_name WorkStation

enum Direction { DOWN, UP, LEFT, RIGHT }

var _initialized := false

@export var direction: Direction = Direction.UP:
	set(value):
		if direction == value:
			return
		direction = value
		if _initialized: 
			update_direction()

var sprite_up: Texture2D   = load("res://assets/workstations/workstation_up.png")
var sprite_down: Texture2D = load("res://assets/workstations/workstation_down.png")
var sprite_left: Texture2D = load("res://assets/workstations/workstation_left.png")
var sprite_right: Texture2D= load("res://assets/workstations/workstation_right.png")

@onready var table_sprite: Sprite2D = $Sprite2D
@onready var collisionBoxLarge: CollisionShape2D = $Collision/CollisionShape2D
@onready var collisionBoxSmall: CollisionShape2D = $CollisionSmall/CollisionShape2D
@onready var interactionArea: CollisionShape2D = $InteractionArea/CollisionShape2D
@onready var content: Sprite2D = $Content

var stored_pickable: PickableResource


@export var station_type := "workstation"


func _ready() -> void:
	_initialized = true
	update_direction()


func interact(player):
	var held = player.getHeldPickable()
	if stored_pickable != null:
		if player.pickUpPickable(stored_pickable):
			if stored_pickable is Ingredient:
				stored_pickable.remove_from_workstation()
			stored_pickable = null
			update_visual()
		return
		
	if held != null:
		stored_pickable = held
		if stored_pickable is Ingredient:
			stored_pickable.put_into_workstation()
		player.dropPickable()
		update_visual()

func update_visual():
	if stored_pickable == null:
		content.visible = false
		return

	content.texture = stored_pickable.icon
	content.modulate = stored_pickable.get_icon_tint()
	content.visible = true

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		body.enter_station(self)


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("players"):
		body.exit_station(self)


func update_direction() -> void:

	collisionBoxLarge.disabled = true
	collisionBoxSmall.disabled = true

	match direction:
		Direction.UP:
			collisionBoxLarge.disabled = false
			if station_type == "donerstation":
				content.position = Vector2(0, -39)
				content.rotation_degrees = 0
			else:
				content.position = Vector2(0, -20)
				content.rotation_degrees = 0
			rotation_degrees = 0
			table_sprite.texture = sprite_up
			interactionArea.position = Vector2(0, 0)

		Direction.RIGHT:
			collisionBoxSmall.disabled = false
			if station_type == "donerstation":
				content.position = Vector2(-50, -20)
				content.rotation_degrees = -90
			else:
				content.position = Vector2(-31, -20)
				content.rotation_degrees = 0
			rotation_degrees = 90
			table_sprite.texture = sprite_right
			collisionBoxSmall.position = Vector2(-16, -20)
			interactionArea.position = Vector2(-32, 0)

		Direction.DOWN:
			collisionBoxSmall.disabled = false
			if station_type == "donerstation":
				content.position = Vector2(0, 0)
				content.rotation_degrees = -180
			else:
				content.position = Vector2(0, -20)
				content.rotation_degrees = 0
			rotation_degrees = 180
			table_sprite.texture = sprite_down
			collisionBoxSmall.position = Vector2(0, -20)
			interactionArea.position = Vector2(0, 0)

		Direction.LEFT:
			collisionBoxSmall.disabled = false
			if station_type == "donerstation":
				content.position = Vector2(50, -20)
				content.rotation_degrees = -270
			else:
				content.position = Vector2(31, -20)
				content.rotation_degrees = 0
			rotation_degrees = 270
			table_sprite.texture = sprite_left
			collisionBoxSmall.position = Vector2(16, -20)
			interactionArea.position = Vector2(32, 0)
