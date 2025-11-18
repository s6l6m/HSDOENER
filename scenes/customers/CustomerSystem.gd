class_name CustomerSystem
extends Node2D

## CustomerSystem - Blackbox für alle Customer-Verwaltung
## Verantwortlich für: Spawning, Movement, Queue-Management
## Kennt KEINE Order-Validierung

# Signals werden an Manager weitergeleitet
signal customer_served(customer: Customer, prepared_ingredients: Array)
signal customer_timeout(customer: Customer)
signal customer_left_scene(customer: Customer)

# Referenz auf die Customer-Szene
@export var customer_scene: PackedScene

# Liste der Queue-Positionen (tatsächliche Node-Referenzen)
var queue_position_nodes: Array[Node] = []

# Ausgangspunkt für Kunden, die gehen (tatsächliche Node-Referenz)
var exit_node: Node = null

# Intern gespeicherte Kunden
var customers: Array = []

# Spawn-Konfiguration
var spawn_position: Vector2 = Vector2(0, 0)
var spawn_x_offset: float = 50.0

## PUBLIC API: Spawnt einen neuen Kunden mit Order-ID
## Parameters:
##   - order_id: Die ID der Bestellung (vom OrderSystem)
##   - order_display_name: Anzeigename für UI
## Returns: Customer - Die gespawnte Customer-Instanz
func spawn_customer(order_id: String, order_display_name: String) -> Customer:
	if customers.size() >= queue_position_nodes.size():
		push_warning("[CustomerSystem] Cannot spawn - queue full!")
		return null

	var new_customer = customer_scene.instantiate() as Customer

	# Setze Order-Daten (KEINE Validierung!)
	new_customer.order_id = order_id
	new_customer.order_display_name = order_display_name

	# Spawn-Position berechnen (versetzt nach rechts)
	new_customer.global_position = spawn_position + Vector2(customers.size() * spawn_x_offset, 0)

	add_child(new_customer)

	# Zielposition für Warteschlange
	var queue_index = customers.size()
	var target_pos = queue_position_nodes[queue_index].global_position
	new_customer.move_to(target_pos)

	customers.append(new_customer)

	# Signale verbinden (Weiterleitung an Manager)
	new_customer.customer_served.connect(_on_customer_served)
	new_customer.customer_timeout.connect(_on_customer_timeout)
	new_customer.customer_arrived_exit.connect(_on_customer_arrived_exit)

	print("[CustomerSystem] 👤 Spawned customer #%d with order_id: %s" % [customers.size(), order_id])

	# Starte Geduld-Timer nach kurzer Verzögerung
	_start_waiting_delayed(new_customer)

	return new_customer

## Startet den Geduld-Timer nach kurzer Verzögerung (damit Kunde erst ankommt)
func _start_waiting_delayed(customer: Customer):
	await get_tree().create_timer(1.0).timeout
	if customer and is_instance_valid(customer):
		customer.start_waiting()

## PUBLIC API: Bewegt einen Kunden zum Ausgang
## Parameters:
##   - customer: Der zu bewegende Kunde
func move_customer_to_exit(customer: Customer):
	if not is_instance_valid(customer):
		push_warning("[CustomerSystem] Cannot move invalid customer to exit")
		return

	if exit_node:
		var exit_pos = exit_node.global_position
		customer.move_to_exit(exit_pos)  # Verwende move_to_exit statt move_to
	else:
		push_warning("[CustomerSystem] No exit node set!")

	# Entferne aus Queue
	customers.erase(customer)

	# Restliche Kunden rücken nach
	_update_queue_positions()

## PUBLIC API: Gibt alle aktiven Kunden zurück
## Returns: Array - Liste aller Kunden in der Queue
func get_customers() -> Array:
	return customers.duplicate()

## PUBLIC API: Gibt die Anzahl der Kunden in der Queue zurück
## Returns: int
func get_customer_count() -> int:
	return customers.size()

## PUBLIC API: Gibt den ersten Kunden in der Queue zurück (oder null)
## Returns: Customer oder null
func get_first_customer() -> Customer:
	if customers.size() > 0:
		return customers[0]
	return null

## INTERNAL: Signal-Weiterleitung - Customer wurde serviert
func _on_customer_served(customer: Customer, prepared_ingredients: Array):
	print("[CustomerSystem] 📤 Forwarding served signal to Manager")
	emit_signal("customer_served", customer, prepared_ingredients)

## INTERNAL: Signal-Weiterleitung - Customer Timeout
func _on_customer_timeout(customer: Customer):
	print("[CustomerSystem] 📤 Forwarding timeout signal to Manager")
	emit_signal("customer_timeout", customer)

## INTERNAL: Signal-Weiterleitung - Customer am Exit angekommen
func _on_customer_arrived_exit(customer: Customer):
	print("[CustomerSystem] 👋 Customer arrived at exit, removing from scene")
	emit_signal("customer_left_scene", customer)
	customer.queue_free()

## INTERNAL: Aktualisiert Queue-Positionen (Kunden rücken nach)
func _update_queue_positions():
	for i in range(customers.size()):
		if i < queue_position_nodes.size():
			var target_pos = queue_position_nodes[i].global_position
			if customers[i].target_position != target_pos:
				customers[i].move_to(target_pos)

	print("[CustomerSystem] 🔄 Updated queue positions, %d customers remaining" % customers.size())
