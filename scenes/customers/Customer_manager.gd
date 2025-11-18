extends Node2D

## CustomerManager - Orchestrator für Order- und Customer-Systeme
## Koordiniert die beiden Blackboxes: OrderSystem + CustomerSystem
## Emittiert Signals für UI und Gameplay

## Signal für Happiness-System
signal happiness_changed(delta: int)  # +1 für richtig, -1 für falsch/timeout

## Signal für Queue UI Display
signal queue_updated(queue_data: Array)

# ========== SYSTEM-KOMPONENTEN ==========

var order_system: OrderSystem
var customer_system: CustomerSystem

# ========== EXPORT-VARIABLEN (für Scene-Setup) ==========

# Referenz auf die Customer-Szene
@export var customer_scene: PackedScene

# Liste der Queue-Positionen (Position2D Nodes)
@export var queue_points: Array[NodePath]

# Ausgangspunkt für Kunden, die gehen
@export var exit_point: NodePath

# ========== STATISTIKEN ==========

var total_happy: int = 0
var total_sad: int = 0

func _ready():
	# Initialisiere OrderSystem
	order_system = OrderSystem.new()
	add_child(order_system)
	print("[CustomerManager] ✅ OrderSystem initialized")

	# Initialisiere CustomerSystem
	customer_system = CustomerSystem.new()
	customer_system.customer_scene = customer_scene

	# Konvertiere NodePaths zu tatsächlichen Node-Referenzen
	for queue_path in queue_points:
		var queue_node = get_node(queue_path)
		if queue_node:
			customer_system.queue_position_nodes.append(queue_node)
		else:
			push_error("[CustomerManager] Could not find queue position at: %s" % queue_path)

	# Exit Node setzen
	if not exit_point.is_empty():
		customer_system.exit_node = get_node(exit_point)
		if not customer_system.exit_node:
			push_error("[CustomerManager] Could not find exit point at: %s" % exit_point)

	add_child(customer_system)
	print("[CustomerManager] ✅ CustomerSystem initialized with %d queue positions" % customer_system.queue_position_nodes.size())

	# Verbinde CustomerSystem Signals
	customer_system.customer_served.connect(_on_customer_served)
	customer_system.customer_timeout.connect(_on_customer_timeout)
	customer_system.customer_left_scene.connect(_on_customer_left_scene)

func _process(_delta):
	# Test-Input: Kunde per Tastendruck spawnen
	if Input.is_action_just_pressed("spawn_customer"):
		spawn_customer()

	# TEST: Taste H = Richtige Bestellung servieren
	if Input.is_action_just_pressed("serve_correct"):
		serve_first_customer_correct()

	# TEST: Taste J = Falsche Bestellung servieren
	if Input.is_action_just_pressed("serve_wrong"):
		serve_first_customer_wrong()

# ========== PUBLIC API ==========

## Spawnt einen neuen Kunden mit zufälliger Bestellung
func spawn_customer():
	if customer_system.get_customer_count() >= queue_points.size():
		print("[CustomerManager] ⚠️ Queue full!")
		return

	# 1. Erstelle zufällige Bestellung (OrderSystem)
	var order_id = order_system.create_random_order()
	if order_id == "":
		push_error("[CustomerManager] Failed to create order!")
		return

	# 2. Hole Display-Name (OrderSystem)
	var order_display_name = order_system.get_order_display_name(order_id)

	# 3. Spawne Customer (CustomerSystem)
	var customer = customer_system.spawn_customer(order_id, order_display_name)
	if not customer:
		push_error("[CustomerManager] Failed to spawn customer!")
		# Cleanup Order
		order_system.release_order(order_id)
		return

	print("[CustomerManager] 🎯 Spawned customer with order: %s" % order_display_name)

	# 4. Notify UI
	_emit_queue_update()

## Serviert dem ersten Kunden mit vorbereiteten Zutaten
## Parameters:
##   - prepared_ingredients: Array von DoenerOrder.Ingredient Enums
func serve_customer_with_ingredients(prepared_ingredients: Array):
	var first_customer = customer_system.get_first_customer()
	if not first_customer:
		print("[CustomerManager] ⚠️ No customer to serve!")
		return

	if not first_customer.is_waiting:
		print("[CustomerManager] ⚠️ Customer is not waiting!")
		return

	# Customer.serve() emittiert Signal -> landet in _on_customer_served()
	first_customer.serve(prepared_ingredients)

# ========== SIGNAL HANDLERS ==========

## Wird aufgerufen wenn Customer serviert wurde
func _on_customer_served(customer: Customer, prepared_ingredients: Array):
	# 1. Validiere Bestellung (OrderSystem)
	var order_id = customer.order_id
	var is_correct = order_system.validate_order(order_id, prepared_ingredients)

	# 2. Update Statistiken und Happiness
	if is_correct:
		print("[CustomerManager] ✅ Customer happy! Correct order!")
		total_happy += 1
		emit_signal("happiness_changed", 1)
	else:
		print("[CustomerManager] ❌ Customer sad! Wrong order!")
		total_sad += 1
		emit_signal("happiness_changed", -1)

	# 3. Cleanup Order
	order_system.release_order(order_id)

	# 4. Entferne Customer (CustomerSystem)
	customer_system.move_customer_to_exit(customer)

	# 5. Stats ausgeben
	_print_stats()

	# 6. Notify UI
	_emit_queue_update()

## Wird aufgerufen wenn Customer Geduld verloren hat
func _on_customer_timeout(customer: Customer):
	print("[CustomerManager] ⏰ Customer timeout!")

	# 1. Update Statistiken und Happiness
	total_sad += 1
	emit_signal("happiness_changed", -1)

	# 2. Cleanup Order
	var order_id = customer.order_id
	order_system.release_order(order_id)

	# 3. Entferne Customer (CustomerSystem)
	customer_system.move_customer_to_exit(customer)

	# 4. Stats ausgeben
	_print_stats()

	# 5. Notify UI
	_emit_queue_update()

## Wird aufgerufen wenn Customer die Scene verlassen hat
func _on_customer_left_scene(customer: Customer):
	print("[CustomerManager] 👋 Customer left scene")
	# Keine weitere Action nötig - CustomerSystem handled cleanup

# ========== UI UPDATE ==========

## Emittiert queue_updated Signal mit formatierten Daten für UI
func _emit_queue_update():
	var queue_data = []
	var customers = customer_system.get_customers()

	for customer in customers:
		var data = {
			"order_name": customer.order_display_name,
			"patience_percentage": customer.patience_timer / customer.patience_time if customer.is_waiting else 1.0
		}
		queue_data.append(data)

	emit_signal("queue_updated", queue_data)

# ========== DEBUG / STATS ==========

func _print_stats():
	print("[CustomerManager] 📊 Stats - Happy: %d | Sad: %d | Total: %d" % [total_happy, total_sad, total_happy + total_sad])

# ========== TEST-FUNKTIONEN ==========

func serve_first_customer_correct():
	"""TEST: Serviert dem ersten Kunden die RICHTIGE Bestellung"""
	var first_customer = customer_system.get_first_customer()
	if not first_customer:
		print("[CustomerManager] No customer to serve!")
		return

	if not first_customer.is_waiting:
		print("[CustomerManager] Customer not waiting!")
		return

	# Hole korrekte Ingredients vom OrderSystem
	var order_id = first_customer.order_id
	var order = order_system._order_registry.get(order_id) as DoenerOrder
	if order:
		var correct_ingredients = order.required_ingredients.duplicate()
		serve_customer_with_ingredients(correct_ingredients)

func serve_first_customer_wrong():
	"""TEST: Serviert dem ersten Kunden eine FALSCHE Bestellung"""
	var first_customer = customer_system.get_first_customer()
	if not first_customer:
		print("[CustomerManager] No customer to serve!")
		return

	if not first_customer.is_waiting:
		print("[CustomerManager] Customer not waiting!")
		return

	# Serviere leeres Array (immer falsch)
	var wrong_ingredients: Array = []
	serve_customer_with_ingredients(wrong_ingredients)
