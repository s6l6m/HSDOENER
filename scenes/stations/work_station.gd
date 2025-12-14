@tool
extends Node2D
class_name WorkStation

signal player_entered_station(player, station)
signal player_exited_station(player, station)

enum Direction { DOWN, UP, LEFT, RIGHT }

var _initialized := false

@export var direction: Direction = Direction.UP:
	set(value):
		if direction == value:
			return
		direction = value
		if _initialized: 
			update_direction()

var sprite_up: Texture2D = load("res://assets/workstations/workstation_up.png")
var sprite_down: Texture2D = load("res://assets/workstations/workstation_down.png")
var sprite_left: Texture2D = load("res://assets/workstations/workstation_left.png")
var sprite_right: Texture2D= load("res://assets/workstations/workstation_right.png")

@onready var rotatable : Node2D = $Rotatable
@onready var table_sprite: Sprite2D = $Rotatable/Sprite2D
@onready var collisionBoxLarge: CollisionShape2D = $Rotatable/Collision/CollisionShape2D
@onready var collisionBoxSmall: CollisionShape2D = $Rotatable/CollisionSmall/CollisionShape2D
@onready var interactionArea: CollisionShape2D = $Rotatable/InteractionArea/CollisionShape2D
@onready var content: Sprite2D = $Rotatable/Content

var stored_pickable: PickableResource

enum StationType {
	WORKSTATION,
	CUTTINGSTATION,
	DONERSTATION,
	INGREDIENTSTATION,
	TRASHSTATION,
	PLATESTATION
}

@export var station_type: StationType = StationType.WORKSTATION

func _ready() -> void:
	_initialized = true
	add_to_group("stations")
	update_direction()


func interact(player: Player):
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

func interact_b(_player: Player):
	print("Nothing to do")

func update_visual():
	if stored_pickable == null:
		content.visible = false
		return

	content.texture = stored_pickable.icon
	#content.modulate = stored_pickable.get_icon_tint()
	content.visible = true

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		player_entered_station.emit(body, self)


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("players"):
		player_exited_station.emit(body, self)


func update_direction() -> void:

	collisionBoxLarge.disabled = true
	collisionBoxSmall.disabled = true

	match direction:
		Direction.UP:
			collisionBoxLarge.disabled = false
			if station_type == StationType.DONERSTATION:
				content.position = Vector2(0, -59)
				content.rotation_degrees = 0
			else:
				content.position = Vector2(0, -40)
				content.rotation_degrees = 0
			rotatable.rotation_degrees = 0
			table_sprite.texture = sprite_up
			interactionArea.position = Vector2(0, -6)

		Direction.RIGHT:
			collisionBoxSmall.disabled = false
			if station_type == StationType.DONERSTATION:
				content.position = Vector2(-32, -55)
				content.rotation_degrees = -90
			else:
				content.position = Vector2(-14, -55)
				content.rotation_degrees = 0
			rotatable.rotation_degrees = 90
			table_sprite.texture = sprite_right
			collisionBoxSmall.position = Vector2(15, -57)
			interactionArea.position = Vector2(-15, -21)

		Direction.DOWN:
			collisionBoxSmall.disabled = false
			if station_type == StationType.DONERSTATION:
				content.position = Vector2(0, -20)
				content.rotation_degrees = -180
			else:
				content.position = Vector2(0, -40)
				content.rotation_degrees = 0
			rotatable.rotation_degrees = 180
			table_sprite.texture = sprite_down
			collisionBoxSmall.position = Vector2(0, -42)
			interactionArea.position = Vector2(0, -6)

		Direction.LEFT:
			collisionBoxSmall.disabled = false
			if station_type == StationType.DONERSTATION:
				content.position = Vector2(32, -55)
				content.rotation_degrees = -270
			else:
				content.position = Vector2(14, -55)
				content.rotation_degrees = 0
			rotatable.rotation_degrees = 270
			table_sprite.texture = sprite_left
			collisionBoxSmall.position = Vector2(-15, -57)
			interactionArea.position = Vector2(15, -21)
