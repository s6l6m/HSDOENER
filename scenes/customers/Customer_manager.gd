extends Node2D

# Referenz auf die Customer-Szene
@export var customer_scene: PackedScene

# Liste der Queue-Positionen (Position2D Nodes)
@export var queue_points: Array[NodePath]

# Ausgangspunkt für Kunden, die gehen
@export var exit_point: NodePath

# Intern gespeicherte Kunden
var customers: Array = []

func _process(_delta):
	# Test-Input: Kunde per Tastendruck spawnen
	if Input.is_action_just_pressed("spawn_customer"):
		spawn_customer()


# Kunde spawnen und in Warteschlange einreihen
func spawn_customer():
	if customers.size() >= queue_points.size():
		print("Queue full")
		return

	var new_customer = customer_scene.instantiate()
	
	# Basis-Spawnpunkt (ganz links)
	var base_pos = Vector2(200, 0)  # beliebige sichtbare Startposition
	
	# Abstand zwischen Kunden in X-Richtung
	var x_offset = 50
	
	# Jeder neue Kunde wird nach rechts versetzt gespawnt
	new_customer.global_position = base_pos + Vector2(customers.size() * x_offset, 0)
	
	add_child(new_customer)

	print("Customer spawned at:", new_customer.global_position)
	
	# Zielposition für Warteschlange (optional)
	var target_pos = get_node(queue_points[customers.size()]).global_position
	new_customer.move_to(target_pos)

	customers.append(new_customer)
	
	# Signale
	new_customer.connect("customer_left", Callable(self, "_on_customer_left"))
	new_customer.connect("customer_arrived_exit", Callable(self, "_remove_customer_from_scene"))



# Kunde verlässt Warteschlange
func _on_customer_left(customer):
	# Kunde verlässt die Queue und läuft zum Ausgang
	new_customer_move_to_exit(customer)
	
	# Restliche Kunden rücken nach
	customers.erase(customer)
	_update_queue_positions()

# Kunden bewegen sich animiert nach vorne
func _update_queue_positions():
	for i in range(customers.size()):
		var target_pos = get_node(queue_points[i]).global_position
		if customers[i].target_position != target_pos:
			customers[i].move_to(target_pos)

# Bewegung Richtung Ausgang starten
func new_customer_move_to_exit(customer):
	var exit_pos = get_node(exit_point).global_position
	customer.move_to(exit_pos)

# Kunde ist am Ausgang angekommen, kann gelöscht werden
func _remove_customer_from_scene(customer):
	customer.queue_free()
