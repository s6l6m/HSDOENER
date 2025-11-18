extends Node

## Verbindet das OrderQueueWidget mit dem CustomerManager
## Muss als Child des Widgets hinzugefügt werden

@export var customer_manager_path: NodePath
@export var widget: Control

func _ready():
	# Warte einen Frame damit alle Nodes bereit sind
	await get_tree().process_frame
	
	if customer_manager_path.is_empty():
		push_warning("OrderQueueConnector: customer_manager_path not set!")
		return
	
	var manager = get_node_or_null(customer_manager_path)
	if not manager:
		push_error("OrderQueueConnector: Could not find CustomerManager at path: %s" % customer_manager_path)
		return
	
	if not widget:
		widget = get_parent() as Control
		if not widget:
			push_error("OrderQueueConnector: No widget assigned and parent is not a Control!")
			return
	
	# Connect signal
	if manager.has_signal("queue_updated"):
		manager.connect("queue_updated", _on_queue_updated)
		print("✅ OrderQueueWidget connected to CustomerManager")
	else:
		push_error("OrderQueueConnector: CustomerManager has no 'queue_updated' signal!")

func _on_queue_updated(queue_data: Array):
	if widget and widget.has_method("update_queue"):
		widget.update_queue(queue_data)
