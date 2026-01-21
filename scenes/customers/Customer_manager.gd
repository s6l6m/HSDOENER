## Verwaltung der Kunden
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

@export var customer_skins: Array[SpriteFrames] 

var current_skin_index = 0

# Referenz zum aktuellen Level (wird von GameManager gesetzt)
var current_level: Level

# Intern gespeicherte Kunden
var customers: Array[Customer] = []

# Timer für automatisches Spawning
var spawn_timer: Timer

# Benutze die Enums direkt als Keys
var difficulty_weights = {
	Level.Difficulty.EASY: {
		Level.Difficulty.EASY: 60,
		Level.Difficulty.MEDIUM: 30,
		Level.Difficulty.HARD: 10
	},
	Level.Difficulty.MEDIUM: {
		Level.Difficulty.EASY: 20,
		Level.Difficulty.MEDIUM: 50,
		Level.Difficulty.HARD: 30
	},
	Level.Difficulty.HARD: {
		Level.Difficulty.EASY: 10,
		Level.Difficulty.MEDIUM: 40,
		Level.Difficulty.HARD: 50
	}
}

func get_weighted_order_difficulty(current_game_diff: Level.Difficulty) -> Level.Difficulty:
	# Sicherheitsscheck: Existiert der Schwierigkeitsgrad im Dictionary?
	if not difficulty_weights.has(current_game_diff):
		push_error("Schwierigkeitsgrad nicht im Dictionary gefunden: ", current_game_diff)
		return Level.Difficulty.EASY
	
	var weights = difficulty_weights[current_game_diff]
	var roll = randi() % 100
	var cumulative_weight = 0
	
	# Wir iterieren über die Keys des inneren Dictionaries
	for order_diff in weights.keys():
		cumulative_weight += weights[order_diff]
		if roll < cumulative_weight:
			return order_diff as Level.Difficulty # Casten zur Sicherheit
			
	return Level.Difficulty.EASY
	
## Kunde spawnen und Bestellung zuweisen
func spawn_customer(game_difficulty: Level.Difficulty):
	# 1. Prüfen, ob noch Platz in der Schlange ist
	if customers.size() >= queue_points.size():
		return

	# 2. Instanziieren
	var new_customer: Customer = customer_scene.instantiate()
	
	# 3. Skin-Logik (Rotation)
	# Sicherheitscheck, falls du vergessen hast, Skins im Inspektor zuzuweisen
	if customer_skins.size() > 0:
		var skin_to_use = customer_skins[current_skin_index]
		
		# Ruft die Methode im Customer.gd auf, um SpriteFrames zu tauschen
		if new_customer.has_method("set_skin_frames"):
			new_customer.set_skin_frames(skin_to_use)
		
		# Index erhöhen und per Modulo (%) zurücksetzen, wenn Ende erreicht
		current_skin_index = (current_skin_index + 1) % customer_skins.size()
	
	# 4. Positionierung (Spawn Punkt)
	var spawn_pos = get_node(spawn_point).global_position
	new_customer.global_position = spawn_pos
	
	# 5. Zur Szene hinzufügen (WICHTIG: Nur EINMAL aufrufen)
	add_child(new_customer)

	# 6. Bewegung zur Warteschlange
	# customers.size() ist hier der Index für den nächsten freien Slot (0, 1, 2...)
	var target_pos = get_node(queue_points[customers.size()]).global_position
	new_customer.move_to(target_pos)
	
	# 7. In lokale Liste aufnehmen und Sound abspielen
	customers.append(new_customer)
	AudioPlayerManager.play(AudioPlayerManager.AudioID.CUSTOMER_ENTER)

	# 8. --- Bestellung generieren (Gewichtet) ---
	var calculated_order_diff = get_weighted_order_difficulty(game_difficulty)
	new_customer.order = order_manager.create_doner_order(new_customer, calculated_order_diff)

	# 9. Debugging Output
	var diff_name = Level.Difficulty.keys()[calculated_order_diff]
	print("[CustomerManager]: Customer gespawnt | Skin: %d | Diff: %s | Start: %s | Limit: %s" % [
			current_skin_index, # Zeigt an, welcher Skin (Index) genutzt wurde (bevor er erhöht wurde -1 rechnen oder einfach so lassen als debug info)
			diff_name,
			str(new_customer.order.creation_time), 
			str(new_customer.order.time_limit)
		])
	
	# 10. Signale verbinden
	new_customer.customer_left.connect(_on_customer_left)
	new_customer.customer_arrived_exit.connect(_remove_customer_from_scene)


# Kunde verlässt Warteschlange
func _on_customer_left(customer: Customer):
	
	if customer.order and customer.order in order_manager.orders:
		print("[CustomerManager] Kunde geht ohne Teller, Order wird negativ bewertet:")
		order_manager.order_completed.emit(customer.order)
		order_manager.orders.erase(customer.order)
		
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

## Gibt die Spawn-Parameter basierend auf dem Schwierigkeitsgrad zurück
func get_spawn_params_for_difficulty(difficulty: Level.Difficulty) -> Dictionary:
	match difficulty:
		Level.Difficulty.EASY:
			return {
				"interval_min": 16.0,  # Sekunden zwischen Spawns (Minimum)
				"interval_max": 20.0,  # Sekunden zwischen Spawns (Maximum)
				"max_customers": queue_points.size()  # Maximale Anzahl gleichzeitiger Kunden
			}
		Level.Difficulty.MEDIUM:
			return {
				"interval_min": 14.0,
				"interval_max": 18.0,
				"max_customers": queue_points.size()
			}
		Level.Difficulty.HARD:
			return {
				"interval_min": 12.0,
				"interval_max": 16.0,
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
