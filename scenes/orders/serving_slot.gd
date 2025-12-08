extends Node2D
class_name ServingSlot

@onready var interaction_zone: Area2D = $InteractionZone
@onready var customer_position: Marker2D = $CustomerPosition
@onready var plate_position: Marker2D = $PlatePosition
@onready var counter_texture: Sprite2D = $CounterTexture
@onready var order_color: Sprite2D = $OrderColor

#var plate: Teller = null
var customer: Customer = null
var order: Order:
	get:
		return customer.order if customer else null
