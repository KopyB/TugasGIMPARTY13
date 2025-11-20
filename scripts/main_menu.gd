extends Control

@onready var mainbuttons: VBoxContainer = $mainbuttons
@onready var settings: Panel = $Settings

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mainbuttons.visible = true
	settings.visible = false
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_settings_pressed() -> void:
	mainbuttons.visible = false
	settings.visible = true

func _on_back_pressed() -> void:
	_ready()
