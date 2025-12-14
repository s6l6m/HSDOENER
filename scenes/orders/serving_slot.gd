extends Node2D
class_name CounterSlot

signal player_entered_slot(player, slot)
signal player_exited_slot(player, slot)

@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_area_customer: Area2D = $InteractionAreaCustomer
@onready var content: Sprite2D = $Content

@export var order_manager: OrderManager

var stored_plate: Plate = null
var active_customer: Customer = null
var customers_in_area: Array[Customer] = []

func _ready() -> void:
	add_to_group("counterslots")
	update_visual()

# logik für teller aufheben / ablegen
func interact(player: Player) -> void:
	
	var held := player.getHeldPickable()

	# Fall 1: Slot hat schon eine Plate → Spieler kann sie aufnehmen
	if stored_plate != null:
		if held == null and player.pickUpPickable(stored_plate):
			stored_plate = null

	# Fall 2: Slot ist leer → Spieler kann Plate ablegen
	if held != null and held is Plate:
		stored_plate = held
		player.dropPickable()
		print(stored_plate.hasIngredients())
		stored_plate.printIngredients()
	
	update_visual()

func interact_b(_player: Player) -> void:
	if active_customer and stored_plate and stored_plate.hasIngredients():
		active_customer.order.fulfilled_ingredients = stored_plate.ingredients.duplicate()
		print(active_customer.order.evaluate_ingredients_fulfilled())
		order_manager.complete_order(active_customer.order)
		stored_plate = null
	
	update_visual()

func update_visual() -> void:
	if stored_plate == null:
		content.visible = false
	else:
		content.visible = true
		content.texture = stored_plate.icon
	
	if active_customer:
		$OrderColor.visible = true
		$OrderColor.self_modulate = active_customer.color
	else:
		$OrderColor.visible = false

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		player_entered_slot.emit(body, self)

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("players"):
		player_exited_slot.emit(body, self)



func _on_interaction_area_customer_body_entered(body: Node2D) -> void:
	if body is Customer:
		customers_in_area.append(body)
		active_customer = customers_in_area.back() # last entered
		update_visual()

func _on_interaction_area_customer_body_exited(body: Node2D) -> void:
	if body is Customer:
		customers_in_area.erase(body)

	# Only clear if area is actually empty
	if customers_in_area.is_empty():
		active_customer = null
	else:
		active_customer = customers_in_area.back()

	update_visual()
