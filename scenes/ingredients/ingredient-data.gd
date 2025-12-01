class_name Ingredient
extends PickableResource

@export var preparation_time: float = 0.0
@export var is_prepared: bool = false
@export var cut_icon: Texture2D

@export var rot_time_total: float = 10.0     # Sekunden bis komplett verdorben
@export var rot_amount: float = 0.0          # 0 = frisch, 1 = verdorben

var is_in_workstation: bool = false          # wird von Workstation gesetzt

func _process(delta: float) -> void:
	if not is_in_workstation:
		update_rot(delta)


func update_rot(delta: float) -> void:
	if rot_amount >= 1.0:
		rot_amount = 1.0
		return

	rot_amount += delta / rot_time_total
	rot_amount = clamp(rot_amount, 0.0, 1.0)

func get_icon_tint() -> Color:
	var fresh = Color(1,1,1)
	var rot = Color(0.4, 0.25, 0.1)
	return fresh.lerp(rot, rot_amount)

func put_into_workstation() -> void:
	is_in_workstation = true

func remove_from_workstation() -> void:
	is_in_workstation = false

 
