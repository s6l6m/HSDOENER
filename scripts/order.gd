class_name Order
extends Resource

@export var id: int
var customer: Node = null     # <--- Kein @export hier!
@export var items: Array[String] = []
@export var is_completed: bool = false
