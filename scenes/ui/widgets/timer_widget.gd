extends Control
class_name TimerWidget

@export var time_left_warning: int = 10

var warning_tween: Tween

func _on_play_time_changed(time_left: int) -> void:
	%TimeLabel.text = _format_time(time_left)

	if time_left <= 0:
		_freeze_red()
	elif time_left <= time_left_warning:
		_start_warning_pulse()
	else:
		_stop_warning_pulse()


func _start_warning_pulse() -> void:
	# Don’t restart if the tween is already running
	if warning_tween and warning_tween.is_running():
		return

	warning_tween = create_tween().set_loops()  # loop the pulse
	warning_tween.tween_property(
		%TimeLabel, "modulate", Color(1, 0.2, 0.2), 0.5
	)
	warning_tween.tween_property(
		%TimeLabel, "modulate", Color(1, 1, 1), 0.5
	)


func _stop_warning_pulse() -> void:
	if warning_tween:
		warning_tween.kill()
		warning_tween = null
	%TimeLabel.modulate = Color(1, 1, 1)  # reset to white


func _freeze_red() -> void:
	# Stop pulsing and stay red
	_stop_warning_pulse()
	%TimeLabel.modulate = Color(1, 0, 0)


func _format_time(time_left: float) -> String:
	if time_left < 0:
		return "00:00"

	var hours: int = floor(time_left / 3600.0)
	var minutes: int = floor((time_left - hours * 3600.0) / 60.0)
	var seconds: int = floor(time_left - hours * 3600.0 - minutes * 60.0)

	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, seconds]
	else:
		return "%02d:%02d" % [minutes, seconds]
