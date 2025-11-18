class_name Customer
extends CharacterBody2D

signal customer_timeout(customer)
signal customer_served(customer, prepared_ingredients: Array)
signal customer_arrived_exit(customer)

@export var speed: float = 100.0
@export var patience_time: float = 15.0  # Zeit in Sekunden bis Kunde ungeduldig wird

var order_id: String = ""  # ID der Bestellung (verwaltet vom OrderSystem)
var order_display_name: String = "???"  # Anzeigename (wird vom Manager gesetzt)
var target_position: Vector2
var is_moving = false
var is_waiting = false  # Wartet in Warteschlange
var is_exiting = false  # Ist auf dem Weg zum Exit
var patience_timer: float = 0.0

@onready var progress_bar: ProgressBar = $TimerBar
@onready var order_label: Label = $OrderLabel

func _ready():
	# Zeige Bestellung an wenn vorhanden
	if order_id != "" and order_label:
		order_label.text = order_display_name
		order_label.visible = false  # Erst sichtbar beim Warten

func move_to(pos: Vector2):
	target_position = pos
	is_moving = true

func move_to_exit(pos: Vector2):
	"""Bewegt Customer zum Exit (setzt is_exiting flag)"""
	target_position = pos
	is_moving = true
	is_exiting = true

func start_waiting():
	"""Startet den Geduld-Timer wenn Kunde in Queue angekommen ist"""
	is_waiting = true
	patience_timer = patience_time
	
	if progress_bar:
		progress_bar.visible = true
		progress_bar.value = 100
		progress_bar.modulate = Color.GREEN
	
	if order_label:
		order_label.visible = true

func serve(prepared_ingredients: Array):
	"""Wird aufgerufen wenn Spieler dem Kunden ein Döner serviert
	Customer validiert NICHT - gibt nur Ingredients weiter an Manager"""
	is_waiting = false

	# Verstecke UI
	if progress_bar:
		progress_bar.visible = false
	if order_label:
		order_label.visible = false

	# Gebe Ingredients an Manager weiter (KEINE Validierung hier!)
	print("[Customer] 🍽️ Served with ingredients, order_id: ", order_id)
	emit_signal("customer_served", self, prepared_ingredients)

func _process(delta):
	# Bewegungs-Logik
	if is_moving:
		var direction = (target_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

		if global_position.distance_to(target_position) < 5:
			is_moving = false
			velocity = Vector2.ZERO

			# Wenn Kunde am Exit angekommen ist
			if is_exiting:
				emit_signal("customer_arrived_exit", self)
	
	# Geduld-Timer mit Farb-Feedback
	if is_waiting:
		patience_timer -= delta
		
		# Update Progress Bar
		if progress_bar:
			var percentage = patience_timer / patience_time
			progress_bar.value = percentage * 100
			
			# Farb-Änderung basierend auf verbleibender Zeit
			if percentage > 0.6:  # > 60% = Grün
				progress_bar.modulate = Color.GREEN
			elif percentage > 0.3:  # 30-60% = Gelb
				progress_bar.modulate = Color.YELLOW
			else:  # < 30% = Rot
				progress_bar.modulate = Color.RED
		
		if patience_timer <= 0:
			# Zeit abgelaufen - Kunde verlässt unzufrieden
			is_waiting = false
			if progress_bar:
				progress_bar.visible = false
			if order_label:
				order_label.visible = false
			print("[Customer] ⏰ Timeout! order_id: ", order_id, " (", order_display_name, ")")
			emit_signal("customer_timeout", self)
