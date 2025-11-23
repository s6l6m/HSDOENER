class_name Order
extends Resource

@export var id: int
var customer: Node = null     # <--- Kein @export hier!
@export var ingredients: Array[Ingredient] = []
@export var is_completed: bool = false
