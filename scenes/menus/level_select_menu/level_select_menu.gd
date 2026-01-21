extends Control

## Loads a simple ItemList node within a margin container. SceneLister updates
## the available scenes in the directory provided. Activating a level will update
## the GameState's current_level, and emit a signal. The main menu node will trigger
## a load action from that signal.

signal level_selected

@onready var level_buttons_container: ItemList = %LevelButtonsContainer
@onready var scene_lister: SceneLister = $SceneLister
@onready var difficulty_buttons_container: ItemList = %DifficultyButtonsContainer


var level_paths : Array[String]
var difficulty_values: Array[int] = []
var selected_level_index := -1
var selected_difficulty_index := -1

func _ready() -> void:
	add_levels_to_container()
	add_difficulty_to_container()

## A fresh level list is propgated into the ItemList, and the file names are cleaned
func add_levels_to_container() -> void:
	level_buttons_container.clear()
	level_paths.clear()
	assert(scene_lister.files)
	for file_path in scene_lister.files:
		var file_name : String = file_path.get_file()  # e.g., "level_1.tscn"
		file_name = file_name.trim_suffix(".tscn")  # Remove the ".tscn" extension
		file_name = file_name.replace("_", " ")  # Replace underscores with spaces
		file_name = file_name.capitalize()  # Convert to proper case
		var button_name := str(file_name)
		level_buttons_container.add_item(button_name)
		level_paths.append(file_path)

func add_difficulty_to_container() -> void:
	difficulty_buttons_container.clear()
	difficulty_values.clear()
	const DIFFICULTY_LABELS := {
		Level.Difficulty.EASY: "Einfach",
		Level.Difficulty.MEDIUM: "Mittel",
		Level.Difficulty.HARD: "Schwer"
	}
	
	for value in Level.Difficulty.values():
		difficulty_values.append(value)
		difficulty_buttons_container.add_item(DIFFICULTY_LABELS[value])

func _on_level_buttons_container_item_activated(index: int) -> void:
	selected_level_index = index
	GameState.set_current_level(level_paths[index])
	_update_start_button_state()

func _on_difficulty_buttons_container_item_activated(index: int) -> void:
	selected_difficulty_index = index
	GameState.set_game_difficulty(difficulty_values[index])
	_update_start_button_state()

func _update_start_button_state() -> void:
	%StartButton.disabled = not _is_ready_to_start()

func _is_ready_to_start() -> bool:
	return selected_level_index >= 0 and selected_difficulty_index >= 0

func _on_start_button_pressed() -> void:
	level_selected.emit()
