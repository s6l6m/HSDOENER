@tool
extends GridContainer

@onready var coins_value_label: Label = %CoinsValueLabel
@onready var games_played_value_label: Label = %GamesPlayedValueLabel
@onready var playtime_value_label: Label = %PlaytimeValueLabel
@onready var rounds_won_value_label: Label = %RoundsWonValueLabel
@onready var rounds_not_completed_value_label: Label = %RoundsNotCompletedValueLabel
@onready var rounds_lost_value_label: Label = %RoundsLostValueLabel

func _ready() -> void:
	var game_state := GameState.get_or_create_state()
	coins_value_label.text = str(game_state.total_coins)
	playtime_value_label.text = TimeManager.format_time(game_state.play_time)
	games_played_value_label.text = str(game_state.total_games_played)
	rounds_won_value_label.text = str(game_state.total_games_won)
	rounds_not_completed_value_label.text = str(game_state.total_games_played - game_state.total_games_won - game_state.total_games_lost)
	rounds_lost_value_label.text = str(game_state.total_games_lost)
