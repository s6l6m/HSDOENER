extends Node2D

## Signal für Happiness-System (später mit UI verbinden)
signal happiness_changed(delta: int)  # +1 für richtig, -1 für falsch/timeout

# Referenz auf die Customer-Szene
@export var customer_scene: PackedScene

# Vordefinierte Bestellungen die Kunden haben können
@export var available_orders: Array[DoenerOrder] = []

# Liste der Queue-Positionen (Position2D Nodes)
@export var queue_points: Array[NodePath]

# Ausgangspunkt für Kunden, die gehen
@export var exit_point: NodePath

# Intern gespeicherte Kunden
var customers: Array = []

# Statistiken
var total_happy: int = 0
var total_sad: int = 0

func _ready():
	# Lade Standard-Bestellungen wenn keine definiert
	if available_orders.size() == 0:
		print("⚠️ No orders defined! Loading presets...")
		_load_preset_orders()

func _load_preset_orders():
	"""Lädt vordefinierte Bestellungen aus dem presets Ordner"""
	var preset_paths = [
		"res://scenes/orders/presets/doener_standard.tres",
		"res://scenes/orders/presets/doener_ohne_zwiebel.tres",
		"res://scenes/orders/presets/doener_scharf.tres",
		"res://scenes/orders/presets/doener_mit_kaese.tres",
		"res://scenes/orders/presets/doener_vegan.tres"
	]
	
	for path in preset_paths:
		var order = load(path) as DoenerOrder
		if order:
			available_orders.append(order)
			print("✅ Loaded order: ", order.order_name)

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

# Kunde spawnen und in Warteschlange einreihen
func spawn_customer():
	if customers.size() >= queue_points.size():
		print("Queue full")
		return

	var new_customer = customer_scene.instantiate()
	
	# Zufällige Bestellung zuweisen
	if available_orders.size() > 0:
		new_customer.order = available_orders.pick_random()
		print("🍖 New customer wants: ", new_customer.order.order_name)
	else:
		print("⚠️ No orders available!")
	
	# Basis-Spawnpunkt (ganz links)
	var base_pos = Vector2(0, 0)  # beliebige sichtbare Startposition
	
	# Abstand zwischen Kunden in X-Richtung
	var x_offset = 50
	
	# Jeder neue Kunde wird nach rechts versetzt gespawnt
	new_customer.global_position = base_pos + Vector2(customers.size() * x_offset, 0)
	
	add_child(new_customer)
	
	# Zielposition für Warteschlange
	var target_pos = get_node(queue_points[customers.size()]).global_position
	new_customer.move_to(target_pos)

	customers.append(new_customer)
	
	# Signale verbinden
	new_customer.connect("customer_served", Callable(self, "_on_customer_served"))
	new_customer.connect("customer_timeout", Callable(self, "_on_customer_timeout"))
	new_customer.connect("customer_arrived_exit", Callable(self, "_remove_customer_from_scene"))
	
	# Starte Geduld-Timer nach kurzer Verzögerung (damit Kunde erst ankommt)
	await get_tree().create_timer(1.0).timeout
	if new_customer and is_instance_valid(new_customer):
		new_customer.start_waiting()

# Kunde wurde bedient (korrekt oder falsch)
func _on_customer_served(customer, order_correct: bool):
	if order_correct:
		print("✅ Customer served correctly! Happy++")
		total_happy += 1
		emit_signal("happiness_changed", 1)
	else:
		print("❌ Wrong order served! Sad++")
		total_sad += 1
		emit_signal("happiness_changed", -1)
	
	_remove_customer_from_queue(customer)
	_print_stats()

# Kunde hat Geduld verloren (Timer abgelaufen)
func _on_customer_timeout(customer):
	print("⏰ Customer left unhappy (timeout)! Sad++")
	total_sad += 1
	emit_signal("happiness_changed", -1)
	_remove_customer_from_queue(customer)
	_print_stats()

# Entfernt Kunden aus Queue und lässt andere nachrücken
func _remove_customer_from_queue(customer):
	# Kunde läuft zum Ausgang
	var exit_pos = get_node(exit_point).global_position
	customer.move_to(exit_pos)
	
	# Aus Queue entfernen
	customers.erase(customer)
	
	# Restliche Kunden rücken nach
	_update_queue_positions()

# Kunden bewegen sich animiert nach vorne
func _update_queue_positions():
	for i in range(customers.size()):
		var target_pos = get_node(queue_points[i]).global_position
		if customers[i].target_position != target_pos:
			customers[i].move_to(target_pos)

# Kunde ist am Ausgang angekommen, kann gelöscht werden
func _remove_customer_from_scene(customer):
	customer.queue_free()

# Debug: Statistiken ausgeben
func _print_stats():
	print("📊 Stats - Happy: %d | Sad: %d | Total: %d" % [total_happy, total_sad, total_happy + total_sad])

# ========== TEST-FUNKTIONEN (später durch Koch-System ersetzen) ==========

func serve_first_customer_correct():
	"""TEST: Serviert dem ersten Kunden die RICHTIGE Bestellung"""
	if customers.size() > 0:
		var first_customer = customers[0]
		if first_customer.is_waiting and first_customer.order:
			# Simuliere korrekte Bestellung (alle required_ingredients)
			var correct_ingredients = first_customer.order.required_ingredients.duplicate()
			first_customer.serve(correct_ingredients)

func serve_first_customer_wrong():
	"""TEST: Serviert dem ersten Kunden eine FALSCHE Bestellung"""
	if customers.size() > 0:
		var first_customer = customers[0]
		if first_customer.is_waiting:
			# Simuliere falsche Bestellung (leeres Array)
			var wrong_ingredients: Array = []
			first_customer.serve(wrong_ingredients)

# Wird später vom Koch-System aufgerufen
func serve_customer_with_ingredients(prepared_ingredients: Array):
	"""Öffentliche API für Koch-System: Serviert dem ersten Kunden"""
	if customers.size() > 0:
		var first_customer = customers[0]
		if first_customer.is_waiting:
			first_customer.serve(prepared_ingredients)
