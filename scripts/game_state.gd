class_name GameState
extends Resource

const STATE_NAME : String = "GameState"
const FILE_PATH = "res://scripts/game_state.gd"

@export var level_states: Dictionary = {}

@export var current_level_path: String
@export var continue_level_path: String

@export var total_games_played: int
@export var total_games_lost: int
@export var total_games_won: int

@export var play_time: int
@export var total_time: int
@export var total_coins: int

@export var character_selections: Dictionary = {}
@export var character_database: CharacterDatabase
@export var last_device_used: Dictionary = {
	Player.PlayerNumber.ONE: InputEventHelper.DEVICE_GENERIC,
	Player.PlayerNumber.TWO: InputEventHelper.DEVICE_GENERIC,
}
@export var difficulty: Level.Difficulty = Level.Difficulty.EASY

signal game_reset

static func get_level_state(level_state_key : String) -> LevelState:
	if not has_game_state(): 
		return
	var game_state := get_or_create_state()
	if level_state_key.is_empty() : return
	if level_state_key in game_state.level_states:
		return game_state.level_states[level_state_key] 
	else:
		var new_level_state := LevelState.new()
		game_state.level_states[level_state_key] = new_level_state
		GlobalState.save()
		return new_level_state

static func has_game_state() -> bool:
	return GlobalState.has_state(STATE_NAME)

static func get_or_create_state() -> GameState:
	return GlobalState.get_or_create_state(STATE_NAME, FILE_PATH)

static func get_current_level_path() -> String:
	if not has_game_state(): 
		return ""
	var game_state := get_or_create_state()
	return game_state.current_level_path

static func get_levels_reached() -> int:
	if not has_game_state(): 
		return 0
	var game_state := get_or_create_state()
	return game_state.level_states.size()

static func level_reached(level_path : String) -> void:
	var game_state := get_or_create_state()
	game_state.current_level_path = level_path
	game_state.continue_level_path = level_path
	get_level_state(level_path)
	GlobalState.save()

static func set_current_level(level_path : String) -> void:
	var game_state := get_or_create_state()
	game_state.current_level_path = level_path
	GlobalState.save()

static func set_game_difficulty(level_difficulty) -> void:
	var game_state := get_or_create_state()
	game_state.difficulty = level_difficulty
	GlobalState.save()

static func start_game() -> void:
	var game_state := get_or_create_state()
	game_state.total_games_played += 1
	GlobalState.save()

static func continue_game() -> void:
	var game_state := get_or_create_state()
	game_state.current_level_path = game_state.continue_level_path
	GlobalState.save()

static func increase_games_lost() -> void:
	var game_state := get_or_create_state()
	game_state.total_games_lost += 1
	GlobalState.save()

static func increase_games_won() -> void:
	var game_state := get_or_create_state()
	game_state.total_games_won += 1
	GlobalState.save()

static func add_coins(coins: int) -> void:
	var game_state := get_or_create_state()
	game_state.total_coins += coins
	GlobalState.save()

static func reset() -> void:
	var game_state := get_or_create_state()
	game_state.level_states = {}
	game_state.current_level_path = ""
	game_state.continue_level_path = ""
	game_state.play_time = 0
	game_state.total_time = 0
	game_state.total_coins = 0
	game_state.total_games_played = 0
	game_state.total_games_lost = 0
	game_state.total_games_won = 0
	game_state.last_device_used = {
		Player.PlayerNumber.ONE: InputEventHelper.DEVICE_GENERIC,
		Player.PlayerNumber.TWO: InputEventHelper.DEVICE_GENERIC,
	}
	game_state.difficulty = Level.Difficulty.EASY
	GlobalState.save()
	game_state.game_reset.emit()
