class_name ItemData
extends Resource

## Pure data definition for items.
## This resource must not contain per-instance gameplay state (that lives on ItemEntity nodes).
## `item_id` is the stable identifier used for matching (orders/scoring/etc.).
@export var item_id: StringName
@export var name: String = ""
@export var icon: Texture2D
