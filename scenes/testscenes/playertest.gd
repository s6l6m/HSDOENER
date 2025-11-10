extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Camera2D.add_target($Player1)
	$Camera2D.add_target($Player2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
