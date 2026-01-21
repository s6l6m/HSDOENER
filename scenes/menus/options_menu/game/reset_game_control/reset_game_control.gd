extends HBoxContainer

const RESET_STRING := "Spiel zurücksetzen:"
const CONFIRM_STRING := "Spiel zurücksetzen:"

signal reset_confirmed

func _on_cancel_button_pressed():
	%CancelButton.hide()
	%ConfirmButton.hide()
	%ResetButton.show()
	%ResetLabel.text = RESET_STRING

func _on_reset_button_pressed():
	%CancelButton.show()
	%ConfirmButton.show()
	%ResetButton.hide()
	%ResetLabel.text = CONFIRM_STRING

func _on_confirm_button_pressed():
	reset_confirmed.emit()
	get_tree().paused = false
	SceneLoader.reload_current_scene()
