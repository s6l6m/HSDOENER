extends Node2D
class_name CounterSlot

signal player_entered_slot(player, slot)
signal player_exited_slot(player, slot)


@onready var interaction_area: Area2D = $InteractionArea
@onready var content: Sprite2D = $Content

var stored_plate: Plate = null


func _ready() -> void:
	add_to_group("counterslots")
	update_visual()


func interact(player: Player) -> void:
	var held := player.getHeldPickable()

	# Fall 1: Slot hat schon eine Plate → Spieler kann sie aufnehmen
	if stored_plate != null:
		if held == null and player.pickUpPickable(stored_plate):
			stored_plate = null
			update_visual()
		return

	# Fall 2: Slot ist leer → Spieler kann Plate ablegen
	if held != null and held is Plate:
		stored_plate = held
		player.dropPickable()
		update_visual()


func update_visual() -> void:
	if stored_plate == null:
		content.visible = false
		return

	content.visible = true
	content.texture = stored_plate.icon


func _on_interaction_area_body_entered(body: Node2D) -> void:
	print("test")
	if body.is_in_group("players"):
		player_entered_slot.emit(body, self)


func _on_interaction_area_body_exited(body: Node2D) -> void:
	print("test2")
	if body.is_in_group("players"):
		player_exited_slot.emit(body, self)
