extends Node
class_name CustomerManager

# Referenz auf die Customer-Szene
@export var customer_scene: PackedScene

# Liste der Queue-Positionen (Position2D Nodes)
@export var queue_points: Array[NodePath]

# Ausgangspunkt für Kunden, die gehen
@export var exit_point: NodePath

@export var spawn_point: NodePath

@export var order_manager: OrderManager

@export var camera: MultiTargetCamera

# Referenz zum aktuellen Level (wird von GameManager gesetzt)
var current_level: Level

# Intern gespeicherte Kunden
var customers: Array[Customer] = []

# Timer für automatisches Spawning
var spawn_timer: Timer

# Kunde spawnen und in Warteschlange einreihen
func spawn_customer(difficulty: Level.Difficulty):
	if customers.size() >= queue_points.size():
		print("Queue full")
		return

	var new_customer: Customer = customer_scene.instantiate()

	# Alle Kunden spawnen am selben Punkt
	var spawn_pos = get_node(spawn_point).global_position
	new_customer.global_position = spawn_pos

	add_child(new_customer)

	# Zielposition für Warteschlange (optional)
	var target_pos = get_node(queue_points[customers.size()]).global_position
	new_customer.move_to(target_pos)

	customers.append(new_customer)

	# --- Bestellung erzeugen ---
	new_customer.order = order_manager.create_doner_order(new_customer, difficulty)

	# Signale
	new_customer.customer_left.connect(_on_customer_left)
	new_customer.customer_arrived_exit.connect(_remove_customer_from_scene)


# Kunde verlässt Warteschlange
func _on_customer_left(customer: Customer):
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
func new_customer_move_to_exit(customer: Customer):
	var exit_pos = get_node(exit_point).global_position
	customer.move_to(exit_pos)

# Kunde ist am Ausgang angekommen, kann gelöscht werden
func _remove_customer_from_scene(customer: Customer):
	customer.queue_free()

# =====================================================
# Automatisches Spawning mit schwierigkeitsgrad-spezifischen Parametern
# =====================================================

## Gibt die Spawn-Parameter basierend auf dem Schwierigkeitsgrad zurück
func get_spawn_params_for_difficulty(difficulty: Level.Difficulty) -> Dictionary:
	match difficulty:
		Level.Difficulty.EASY:
			return {
				"interval_min": 15.0,  # Sekunden zwischen Spawns (Minimum)
				"interval_max": 25.0,  # Sekunden zwischen Spawns (Maximum)
				"max_customers": queue_points.size()  # Maximale Anzahl gleichzeitiger Kunden
			}
		Level.Difficulty.MEDIUM:
			return {
				"interval_min": 10.0,
				"interval_max": 18.0,
				"max_customers": queue_points.size()
			}
		Level.Difficulty.HARD:
			return {
				"interval_min": 6.0,
				"interval_max": 12.0,
				"max_customers": queue_points.size()
			}
		_:
			# Fallback zu EASY
			return {
				"interval_min": 15.0,
				"interval_max": 25.0,
				"max_customers": queue_points.size()
			}

## Startet das automatische Spawning basierend auf dem Schwierigkeitsgrad
func start_auto_spawning(level: Level) -> void:
	current_level = level
	stop_auto_spawning()  # Stoppe eventuell laufenden Timer
	
	if not current_level:
		print("CustomerManager: Kein Level gesetzt, kann nicht spawnen")
		return
	
	var params = get_spawn_params_for_difficulty(current_level.difficulty)
	
	# Timer erstellen
	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	spawn_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	
	# Ersten Spawn sofort starten (optional) oder nach erstem Intervall
	_schedule_next_spawn(params)

## Stoppt das automatische Spawning
func stop_auto_spawning() -> void:
	if spawn_timer:
		spawn_timer.queue_free()
		spawn_timer = null

## Plant den nächsten Spawn mit zufälligem Intervall
func _schedule_next_spawn(params: Dictionary) -> void:
	if not spawn_timer:
		return
	
	var interval = randf_range(params.interval_min, params.interval_max)
	spawn_timer.wait_time = interval
	spawn_timer.start()

## Wird aufgerufen, wenn der Spawn-Timer abläuft
func _on_spawn_timer_timeout() -> void:
	if not current_level:
		return
	
	var params = get_spawn_params_for_difficulty(current_level.difficulty)
	
	# Prüfe ob noch Platz in der Queue ist
	if customers.size() >= params.max_customers:
		# Queue voll, versuche es später erneut
		_schedule_next_spawn(params)
		return
	
	# Spawne neuen Kunden
	spawn_customer(current_level.difficulty)
	
	# Plane nächsten Spawn
	_schedule_next_spawn(params)
