extends Node2D
class_name CounterSlot

# =====================================================
# Signals
# =====================================================
signal player_entered_slot(player: Player, slot: CounterSlot)
signal player_exited_slot(player: Player, slot: CounterSlot)

# =====================================================
# Nodes
# =====================================================
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_area_customer: Area2D = $InteractionAreaCustomer
@onready var content: Sprite2D = $Content
@onready var order_color: Sprite2D = $OrderColor

# =====================================================
# Config
# =====================================================
@export var order_manager: OrderManager

# =====================================================
# State
# =====================================================
var stored_plate: Plate
var active_customer: Customer
var customers_in_area: Array[Customer] = []

# =====================================================
# Lifecycle
# =====================================================
func _ready() -> void:
	add_to_group("counterslots")
	update_visual()

# =====================================================
# Interaction (A)
# Pick up / place plate
# =====================================================
func interact(player: Player) -> void:
	# 1️⃣ Take plate from counter
	if stored_plate:
		if player.pickUpPickable(stored_plate):
			stored_plate = null
			update_visual()
		return

	# 2️⃣ Place plate on counter
	if player.isHoldingPlate():
		stored_plate = player.dropPickable()
		stored_plate.printIngredients()
		update_visual()

# =====================================================
# Interaction (B)
# Serve customer
# =====================================================
func interact_b(_player: Player) -> void:
	if not active_customer or not stored_plate or not stored_plate.hasIngredients():
		return

	active_customer.order.fulfilled_ingredients = stored_plate.ingredients.duplicate()
	order_manager.complete_order(active_customer.order)
	stored_plate = null

	update_visual()

# =====================================================
# Visuals
# =====================================================
func update_visual() -> void:
	content.visible = stored_plate != null
	if stored_plate:
		content.texture = stored_plate.icon

	order_color.visible = active_customer != null
	if active_customer:
		order_color.self_modulate = active_customer.color

# =====================================================
# Player Detection
# =====================================================
func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body is Player:
		player_entered_slot.emit(body, self)

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body is Player:
		player_exited_slot.emit(body, self)

# =====================================================
# Customer Detection
# =====================================================
func _on_interaction_area_customer_body_entered(body: Node2D) -> void:
	if body is not Customer:
		return

	customers_in_area.append(body)
	active_customer = customers_in_area.back()
	update_visual()

func _on_interaction_area_customer_body_exited(body: Node2D) -> void:
	if body is not Customer:
		return

	customers_in_area.erase(body)
	active_customer = customers_in_area.back() if customers_in_area else null
	update_visual()
