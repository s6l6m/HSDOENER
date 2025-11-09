extends Node2D

@export var time_node: Node
@onready var time_display: Label = $PanelContainer/HBoxContainer/TimeDisplay

func _ready() -> void:
	if time_display == null:
		push_error("time_display node is not found!")
		return

	if time_node == null:
		push_error("time_node export is not assigned!")
		return
	_on_play_time_changed(time_node.play_time)
	time_node.play_time_changed.connect(_on_play_time_changed)

func _on_play_time_changed(value: int) -> void:
	time_display.text = _format_time(value)

func _format_time(total_seconds: float) -> String:
	var hours: int = floor(total_seconds / 3600.0)
	var minutes: int = floor((total_seconds - hours * 3600.0) / 60.0)
	var seconds: int = floor(total_seconds - hours * 3600.0 - minutes * 60.0)
	return "%02d:%02d:%02d" % [hours, minutes, seconds]
