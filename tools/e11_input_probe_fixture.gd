extends Control

signal navigate_requested(screen_id: String, payload: Dictionary)

var cancel_received := false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		cancel_received = true
		navigate_requested.emit("fixture_back", {})
		get_viewport().set_input_as_handled()
