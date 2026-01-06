class_name LevelState
extends Resource

@export var tutorial_read : bool = false
@export var coins: int = 0

func reset_level() -> void:
	self.coins = 0
