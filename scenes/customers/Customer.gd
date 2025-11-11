extends CharacterBody2D

signal customer_timeout(customer)
signal customer_served(customer, order_correct: bool)
signal customer_arrived_exit(customer)

@export var speed: float = 100.0
@export var patience_time: float = 15.0  # Zeit in Sekunden bis Kunde ungeduldig wird

var order: DoenerOrder  # Bestellung des Kunden
var target_position: Vector2
var is_moving = false
var is_waiting = false  # Wartet in Warteschlange
var patience_timer: float = 0.0

@onready var progress_bar: ProgressBar = $TimerBar
@onready var order_label: Label = $OrderLabel

func _ready():
	# Zeige Bestellung an wenn vorhanden
	if order and order_label:
		order_label.text = order.order_name
		order_label.visible = false  # Erst sichtbar beim Warten

func move_to(pos: Vector2):
	target_position = pos
	is_moving = true

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
	"""Wird aufgerufen wenn Spieler dem Kunden ein Döner serviert"""
	is_waiting = false
	
	# Verstecke UI
	if progress_bar:
		progress_bar.visible = false
	if order_label:
		order_label.visible = false
	
	# Prüfe ob Bestellung korrekt ist
	var correct = false
	if order:
		correct = order.matches(prepared_ingredients)
		
		if correct:
			print("✅ Customer happy! Correct order: ", order.order_name)
		else:
			print("❌ Customer sad! Wrong order for: ", order.order_name)
	else:
		print("⚠️ Customer has no order!")
	
	emit_signal("customer_served", self, correct)

func _process(delta):
	# Bewegungs-Logik
	if is_moving:
		var direction = (target_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		
		if global_position.distance_to(target_position) < 5:
			is_moving = false
			velocity = Vector2.ZERO

			# Wenn Kunde sein Ziel erreicht hat (z. B. Exit)
			var exit_pos = get_parent().get_node(get_parent().exit_point).global_position
			if target_position == exit_pos:
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
			print("⏰ Customer timeout! Order was: ", order.order_name if order else "Unknown")
			emit_signal("customer_timeout", self)
