extends Node2D
class_name CounterSlot

signal player_entered_slot(player, slot)
signal player_exited_slot(player, slot)


@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_area_customer: Area2D = $InteractionAreaCustomer
@onready var content: Sprite2D = $Content

var stored_plate: Plate = null
var active_customer: Customer = null


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
			update_visual()
		return

	# Fall 2: Slot ist leer → Spieler kann Plate ablegen
	if held != null and held is Plate:
		stored_plate = held
		player.dropPickable()
		update_visual()
		print(stored_plate.hasIngredients())
		stored_plate.printIngredients()


func update_visual() -> void:
	if stored_plate == null:
		content.visible = false
		return

	content.visible = true
	content.texture = stored_plate.icon

# hier logik für teller abgeben, order abschliessen
func interact_b(player: Player) -> void:
	print(active_customer.order)
	if active_customer and stored_plate.hasIngredients():
		print(active_customer.order)
		active_customer.order.fulfilled_ingredients = stored_plate.ingredients.duplicate()
		print(active_customer.order.evaluate_ingredients_fulfilled())
		player.emit("customer_left")

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		player_entered_slot.emit(body, self)


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("players"):
		player_exited_slot.emit(body, self)
		


func _on_interaction_area_customer_body_entered(body: Node2D) -> void:
	print(active_customer.order)
	if body.is_in_group("customers"):
		print("customer entered counter zone")
		active_customer = body as Customer


func _on_interaction_area_customer_body_exited(body: Node2D) -> void:
	if body.is_in_group("customers"):
		print("customer exited counter zone")
		active_customer = null
