extends Node
class_name TutorialManager
## A script to add into a level or game scene to display tutorial windows.

## A list of tutorial scenes to open, one after the other.
@export var tutorial_scenes : Array[PackedScene]
## If true, open the tutorials when the scene becomes ready.
@export var auto_open : bool = false
## Delay before opening the tutorials when the scene becomes ready.
@export var auto_open_delay : float = 0.25

@onready var scene_root := get_tree().current_scene

func open_tutorials() -> void:
	var initial_focus : Control = get_viewport().gui_get_focus_owner()
	for tutorial_scene in tutorial_scenes:
		var tutorial_menu: OverlaidWindow = tutorial_scene.instantiate()
		scene_root.add_child.call_deferred(tutorial_menu)
		await tutorial_menu.closed
		if is_inside_tree() and initial_focus:
			initial_focus.grab_focus()

func _ready() -> void:
	if auto_open:
		if auto_open_delay > 0.0:
			await get_tree().create_timer(auto_open_delay, false).timeout
		open_tutorials.call_deferred()
