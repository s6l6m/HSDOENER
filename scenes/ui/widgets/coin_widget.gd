extends Control
class_name CoinWidget

@onready var coin_label: Label = %CoinLabel
@onready var coin_goal_label: Label = %GoalCoinCountLabel

enum PulseMode { GREEN, RED, NONE }
var pulse_tween: Tween

func _is_ready() -> void:
	if not is_node_ready():
		await ready

func update_coins(coins: int, pulse_mode: PulseMode = PulseMode.NONE) -> void:
	coin_label.text = str(coins)
	match pulse_mode:
		PulseMode.GREEN:
			_pulse_color(Color.GREEN)
		PulseMode.RED:
			_pulse_color(Color.RED)

func _pulse_color(pulse_color: Color) -> void:
	var base_color := Color.WHITE

	# Kill previous tween if it exists
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()

	pulse_tween = create_tween()

	pulse_tween.tween_property(
		coin_label,
		"modulate",
		pulse_color,
		0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	pulse_tween.tween_property(
		coin_label,
		"modulate",
		base_color,
		0.75
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func update_coins_goal(_coins: int):
	coin_goal_label.text = str(_coins)
