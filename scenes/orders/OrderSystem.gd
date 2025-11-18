class_name OrderSystem
extends Node

## OrderSystem - Blackbox für alle Order-Logik
## Verantwortlich für: Erstellen, Validieren und Verwalten von Bestellungen
## Kennt KEINE Customer-Logik

# Vordefinierte Bestellungen die geladen werden
var available_orders: Array[DoenerOrder] = []

# Mapping: order_id -> DoenerOrder Instance
var _order_registry: Dictionary = {}

# Counter für eindeutige IDs
var _next_order_id: int = 1

func _init():
	_load_preset_orders()

## Lädt vordefinierte Bestellungen aus dem presets Ordner
func _load_preset_orders():
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
			print("[OrderSystem] ✅ Loaded order: ", order.order_name)

	if available_orders.size() == 0:
		push_error("[OrderSystem] No orders could be loaded!")

## PUBLIC API: Erstellt eine neue zufällige Bestellung
## Returns: order_id (String) - Eindeutige ID für diese Bestellung
func create_random_order() -> String:
	if available_orders.size() == 0:
		push_error("[OrderSystem] Cannot create order - no orders available!")
		return ""

	# Wähle zufälliges Order-Template
	var order_template = available_orders.pick_random()

	# Erstelle eindeutige ID
	var order_id = "order_%d" % _next_order_id
	_next_order_id += 1

	# Registriere Order (verwende Template)
	_order_registry[order_id] = order_template

	print("[OrderSystem] 📝 Created order '%s': %s" % [order_id, order_template.order_name])
	return order_id

## PUBLIC API: Validiert ob zubereitete Zutaten der Bestellung entsprechen
## Parameters:
##   - order_id: Die ID der Bestellung
##   - prepared_ingredients: Array von DoenerOrder.Ingredient Enums
## Returns: bool - true wenn korrekt, false wenn falsch
func validate_order(order_id: String, prepared_ingredients: Array) -> bool:
	if not _order_registry.has(order_id):
		push_error("[OrderSystem] Cannot validate - order_id '%s' not found!" % order_id)
		return false

	var order = _order_registry[order_id] as DoenerOrder
	var is_correct = order.matches(prepared_ingredients)

	if is_correct:
		print("[OrderSystem] ✅ Validation SUCCESS for '%s'" % order_id)
	else:
		print("[OrderSystem] ❌ Validation FAILED for '%s'" % order_id)

	return is_correct

## PUBLIC API: Gibt den Display-Namen der Bestellung zurück (für UI)
## Parameters:
##   - order_id: Die ID der Bestellung
## Returns: String - Name der Bestellung (z.B. "Döner Standard")
func get_order_display_name(order_id: String) -> String:
	if not _order_registry.has(order_id):
		push_warning("[OrderSystem] order_id '%s' not found - returning '???'" % order_id)
		return "???"

	var order = _order_registry[order_id] as DoenerOrder
	return order.order_name

## PUBLIC API: Gibt die vollständige Beschreibung der Bestellung zurück
## Parameters:
##   - order_id: Die ID der Bestellung
## Returns: String - Detaillierte Beschreibung (mit Zutaten)
func get_order_description(order_id: String) -> String:
	if not _order_registry.has(order_id):
		push_warning("[OrderSystem] order_id '%s' not found" % order_id)
		return "Unknown Order"

	var order = _order_registry[order_id] as DoenerOrder
	return order.get_order_description()

## PUBLIC API: Entfernt eine Bestellung aus dem Registry (optional, für Cleanup)
## Parameters:
##   - order_id: Die ID der zu entfernenden Bestellung
func release_order(order_id: String):
	if _order_registry.has(order_id):
		_order_registry.erase(order_id)
		print("[OrderSystem] 🗑️ Released order '%s'" % order_id)

## DEBUG: Gibt Anzahl der registrierten Orders zurück
func get_active_orders_count() -> int:
	return _order_registry.size()
