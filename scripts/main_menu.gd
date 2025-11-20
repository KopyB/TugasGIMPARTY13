extends Control

@onready var mainbuttons: VBoxContainer = $mainbuttons
@onready var settings: Panel = $Settings
@onready var config = ConfigFile.new()
var fstoggle
var volume

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mainbuttons.visible = true
	settings.visible = false
	
	var load_err = config.load("user://settings.cfg")
	if load_err == OK:
		# Apply loaded settings
		fstoggle = config.get_value("video", "fullscreen")
		$Settings/VBoxContainer/fulltoggle._on_toggled(fstoggle)
		$Settings/VBoxContainer/fulltoggle.button_pressed = fstoggle
		volume = config.get_value("audio", "volume")
		$Settings/VBoxContainer/Labelmusic/MusicControl._on_value_changed(volume)
		$Settings/VBoxContainer/Labelmusic/MusicControl.value = volume
	else:
		print("No config found. Using default settings.")
	

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

func _on_apply_pressed() -> void:
	fstoggle = $Settings/VBoxContainer/fulltoggle.button_pressed
	$Settings/VBoxContainer/fulltoggle._on_toggled(fstoggle)
	print(fstoggle)
	
	volume = $Settings/VBoxContainer/Labelmusic/MusicControl.value
	$Settings/VBoxContainer/Labelmusic/MusicControl._on_value_changed(volume)
	print(volume)

	# Example settings—replace with your own controls
	config.set_value("video", "fullscreen", fstoggle)
	config.set_value("audio", "volume", volume)

	# Save file
	var err = config.save("user://settings.cfg")
	if err != OK:
		print("Failed to save config!")

	# Go back to main layout
	_ready()
