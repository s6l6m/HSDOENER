extends Node
class_name Level

signal level_lost
signal level_won
signal level_won_and_changed(level_path : String)

@export_category("Next level (optional)")
@export_file("*.tscn") var next_level_path : String

enum Difficulty { EASY, MEDIUM, HARD }

@export_category("Level Settings")
@export var round_time: int = 30
@export var target_coins: int = 150
@export var difficulty: Difficulty

@onready var tutorial_manager: TutorialManager = %TutorialManager

var level_state: LevelState

func open_tutorials() -> void:
	tutorial_manager.open_tutorials()
	level_state.tutorial_read = true
	GlobalState.save()

func _ready() -> void:
	level_state = GameState.get_level_state(scene_file_path)
	if not level_state.tutorial_read:
		open_tutorials()

func _on_tutorial_button_pressed() -> void:
	open_tutorials()
