extends Control

## Widget zur Anzeige der aktuellen Bestellungs-Queue
## Zeigt die ersten N Kunden und deren Bestellungen an

@export var max_displayed_orders: int = 5
@export var show_position_numbers: bool = true

@onready var order_list: VBoxContainer = $PanelContainer/VBoxContainer/OrderList

var displayed_orders: Array = []

func _ready():
	# Initial clear
	clear_queue()

func update_queue(customers: Array):
	"""Aktualisiert die Queue-Anzeige mit aktuellen Kunden"""
	# Clear old labels
	clear_queue()
	
	# Add new labels for each customer (max limit)
	var display_count = min(max_displayed_orders, customers.size())
	
	for i in range(display_count):
		var customer = customers[i]
		var label = Label.new()
		
		# Format: "1. Döner Standard" oder nur "Döner Standard"
		var order_name = "???"
		if customer.order:
			order_name = customer.order.order_name
		
		if show_position_numbers:
			label.text = "%d. %s" % [i + 1, order_name]
		else:
			label.text = order_name
		
		# Styling
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.add_theme_font_size_override("font_size", 14)
		
		# Color coding basierend auf Geduld (optional)
		if customer.is_waiting:
			var patience_percentage = customer.patience_timer / customer.patience_time
			if patience_percentage < 0.3:
				label.add_theme_color_override("font_color", Color.RED)
			elif patience_percentage < 0.6:
				label.add_theme_color_override("font_color", Color.YELLOW)
		
		order_list.add_child(label)
		displayed_orders.append(label)

func clear_queue():
	"""Entfernt alle Order-Labels"""
	for child in order_list.get_children():
		child.queue_free()
	displayed_orders.clear()

func get_queue_size() -> int:
	"""Gibt die Anzahl der angezeigten Orders zurück"""
	return displayed_orders.size()
