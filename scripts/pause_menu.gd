extends Control

func paused():
	get_tree().paused = true
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
func resume():
	get_tree().paused = false
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()

func _on_resume_pressed() -> void:
	resume()
	
func _on_restart_pressed() -> void:
	resume()
	get_tree().reload_current_scene()

func _on_exit_pressed() -> void:
	resume()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("escape") and not get_tree().paused:
		paused()
	elif Input.is_action_just_pressed("escape") and get_tree().paused:
		resume()
