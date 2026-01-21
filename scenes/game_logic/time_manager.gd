extends Node
class_name TimeManager

var play_time : int
var total_time : int

signal play_time_changed(new_value)
signal total_time_changed(new_value)

func _add_timers() -> void:
	var play_timer := Timer.new()
	play_timer.one_shot = false
	play_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	play_timer.timeout.connect(func():
		play_time += 1
		play_time_changed.emit(play_time)
	)
	add_child(play_timer)
	play_timer.start(1)

	var total_timer := Timer.new()
	total_timer.one_shot = false
	total_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	total_timer.timeout.connect(func():
		total_time += 1
		total_time_changed.emit(total_time)
	)
	add_child(total_timer)
	total_timer.start(1)

func _enter_tree() -> void:
	_add_timers()
	var game_state := GameState.get_or_create_state()
	game_state.game_reset.connect(_on_reset_game)

func _on_reset_game() -> void:
	play_time = 0
	total_time = 0

func _exit_tree() -> void:
	var game_state := GameState.get_or_create_state()
	game_state.play_time += play_time
	game_state.total_time += total_time
	GlobalState.save()
	
static func format_time(time: float) -> String:
	if time < 0:
		return "00:00"

	var hours: int = floor(time / 3600.0)
	var minutes: int = floor((time - hours * 3600.0) / 60.0)
	var seconds: int = floor(time - hours * 3600.0 - minutes * 60.0)

	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, seconds]
	else:
		return "%02d:%02d" % [minutes, seconds]
