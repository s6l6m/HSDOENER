class_name ItemEntity
extends Node2D

## World instance of an item. Carries per-instance state and references the shared `ItemData`.
@export var data: ItemData

func get_item_id() -> StringName:
	return data.item_id if data else &""

func attach_to(anchor: Node) -> void:
	## Reparents the item under an anchor node (player hand, workstation slot, etc.)
	## and resets its local transform.
	if not anchor:
		return
	if get_parent():
		reparent(anchor)
	else:
		anchor.add_child(self)
	position = Vector2.ZERO
	rotation = 0.0
	scale = Vector2.ONE
