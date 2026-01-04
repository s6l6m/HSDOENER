@tool
extends Node2D
class_name WorkStation

signal player_entered_station(player, station)
signal player_exited_station(player, station)

enum Direction { DOWN, UP, LEFT, RIGHT }

var _initialized := false
var audio_player: AudioStreamPlayer

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

@onready var rotatable: Node2D = $Rotatable
@onready var table_sprite: Sprite2D = $Rotatable/Sprite2D
@onready var collisionBoxLarge := get_node_or_null(^"Rotatable/Collision/CollisionShape2D") as CollisionShape2D
@onready var collisionBoxSmall := get_node_or_null(^"Rotatable/CollisionSmall/CollisionShape2D") as CollisionShape2D
@onready var interactionArea := get_node_or_null(^"Rotatable/InteractionArea/CollisionShape2D") as CollisionShape2D
@onready var content: Sprite2D = $Rotatable/Content

var stored_item: ItemEntity

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
	## Default station interaction:
	## - If both sides have items, try combining Ingredient <-> Döner.
	## - Else transfer items between station slot and player.
	var held := player.get_held_item()

	if stored_item != null and held != null:
		# Combine ingredient into doner (either direction).
		if stored_item is DonerEntity and held is IngredientEntity:
			if (stored_item as DonerEntity).add_ingredient(held as IngredientEntity):
				player.drop_item()
				update_visual()
			return
		if held is DonerEntity and stored_item is IngredientEntity:
			if (held as DonerEntity).add_ingredient(stored_item as IngredientEntity):
				stored_item = null
				update_visual()
			return

	if stored_item != null:
		if player.pick_up_item(stored_item):
			AudioPlayerManager.play(AudioPlayerManager.AudioID.PLATE_TAKE if stored_item is DonerEntity else AudioPlayerManager.AudioID.PLAYER_GRAB)
			stored_item = null
			update_visual()
		return

	if held != null:
		stored_item = player.drop_item()
		if stored_item:
			AudioPlayerManager.play(AudioPlayerManager.AudioID.PLATE_PLACE if stored_item is DonerEntity else AudioPlayerManager.AudioID.PLAYER_PUT)
			stored_item.attach_to(content)
		update_visual()

func interact_b(_player: Player):
	print("Nothing to do")

func update_visual():
	content.texture = null
	content.visible = stored_item != null

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		player_entered_station.emit(body, self)


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("players"):
		player_exited_station.emit(body, self)


func update_direction() -> void:

	if collisionBoxLarge != null:
		collisionBoxLarge.disabled = true
	if collisionBoxSmall != null:
		collisionBoxSmall.disabled = true

	match direction:
		Direction.UP:
			if collisionBoxLarge != null:
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
			if collisionBoxSmall != null:
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
			if collisionBoxSmall != null:
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
			if collisionBoxSmall != null:
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
