extends Control

@export var state: Label
@export var resume_button: Button
@onready var scorelabel: Label = $VBoxContainer/scorelabel
@onready var timer: Timer = $Timer
@onready var pause_buttons: VBoxContainer = $VBoxContainer
@onready var settings_panel: Panel = $Settings 
@onready var config = ConfigFile.new()

var fstoggle
var shake_setting
var volume
var sfx

var score: int = 0
var is_gameover : bool = false
#signal end_screen_toggled(type: int)

const MAP_TYPE_STRING = {0: "YOU DIED!", 1: "PAUSED"}

func paused():
	get_tree().paused = true
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
func resume():
	get_tree().paused = false
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _ready() -> void:
	timer.timeout.connect(_on_score_timer_timeout)
	update_score_display()
	hide()
	add_to_group("ui_manager")
	
	
	if settings_panel: 
		settings_panel.hide()
	is_gameover = false 

	load_current_settings()

func load_current_settings():
	var load_err = config.load("user://settings.cfg")
	if load_err == OK:
		fstoggle = config.get_value("video", "fullscreen", false)
		
		if has_node("Settings/VBoxContainer/fulltoggle"):
			$Settings/VBoxContainer/fulltoggle.button_pressed = fstoggle
			
		shake_setting = config.get_value("video", "screenshake", true)
		if has_node("Settings/VBoxContainer/ShakeToggle"):
			$Settings/VBoxContainer/ShakeToggle.button_pressed = shake_setting
			
		volume = config.get_value("audio", "volume", 1.0)
		if has_node("Settings/VBoxContainer/Labelmusic/MusicControl"):
			$Settings/VBoxContainer/Labelmusic/MusicControl.value = volume
			
		sfx = config.get_value("audio", "sfx", 1.0)
		if has_node("Settings/VBoxContainer/labelSFX/SFXControl"):
			$Settings/VBoxContainer/labelSFX/SFXControl.value = sfx
			
func _on_settings_pressed(): 
	pause_buttons.hide()   
	settings_panel.show()    
	load_current_settings()   

func _on_settings_back_pressed(): 
	settings_panel.hide()
	pause_buttons.show()

func _on_apply_pressed(): 
	if has_node("Settings/VBoxContainer/fulltoggle"):
		fstoggle = $Settings/VBoxContainer/fulltoggle.button_pressed
		if fstoggle: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	if has_node("Settings/VBoxContainer/ShakeToggle"):
		shake_setting = $Settings/VBoxContainer/ShakeToggle.button_pressed
		cameraeffects.is_screenshake_enabled = shake_setting
		
	if has_node("Settings/VBoxContainer/Labelmusic/MusicControl"):
		volume = $Settings/VBoxContainer/Labelmusic/MusicControl.value
		AudioServer.set_bus_volume_db(0, linear_to_db(volume)) 
		
	if has_node("Settings/VBoxContainer/labelSFX/SFXControl"):
		sfx = $Settings/VBoxContainer/labelSFX/SFXControl.value
		AudioServer.set_bus_volume_db(1, linear_to_db(sfx)) 

	config.set_value("video", "fullscreen", fstoggle)
	config.set_value("video", "screenshake", shake_setting)
	config.set_value("audio", "volume", volume)
	config.set_value("audio", "sfx", sfx)
	
	var err = config.save("user://settings.cfg")
	if err == OK:
		print("Settings saved from Pause Menu")
	
	_on_settings_back_pressed()

func _on_resume_pressed() -> void:
	resume()
	
func _on_restart_pressed() -> void:
	resume()
	Powerupview.reset_desc()
	Powerupview.reset_icon()
	Transition.reload_scene()
	#get_tree().reload_current_scene()

func _on_exit_pressed() -> void:
	resume()
	Powerupview.reset_desc()
	Powerupview.reset_icon()
	Transition.load_scene("res://scenes/main_menu.tscn")
	#get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	
func _process(delta: float) -> void:
	if is_gameover:
		return
	if Input.is_action_just_pressed("escape"):
		if not get_tree().paused:
			toggled_handler(1) 
		else:
			if settings_panel and settings_panel.visible:
				_on_settings_back_pressed()
			else:
				resume()
	

func toggled_handler(type: int) -> void:
	state.text = MAP_TYPE_STRING[type]
	var settings = $VBoxContainer/SETTINGS
	if type == 0:
		is_gameover = true
		resume_button.hide()
		settings.hide()
		scorelabel.show()
		check_and_save_highscore(score)
	else:
		resume_button.show()
		settings.show()
		scorelabel.hide()
	paused()
	
func check_and_save_highscore(current_score: int):
	var save_config = ConfigFile.new()
	var err = save_config.load("user://savegame.cfg")
	var old_highscore = 0
	
	if err == OK:
		old_highscore = save_config.get_value("game", "highscore", 0)

	if current_score > old_highscore:
		print("NEW HIGH SCORE! Saving...")
		save_config.set_value("game", "highscore", current_score)
		save_config.save("user://savegame.cfg")
		
		# Change text if high score
		scorelabel.text = "NEW HIGH SCORE: " + str(current_score)
		scorelabel.modulate = Color(1, 0.84, 0) # Warna Emas
		
		var settings_config = ConfigFile.new()
		var err_settings = settings_config.load("user://settings.cfg")
		var uploader_name = "Captain" 
		
		if err_settings == OK:
			uploader_name = settings_config.get_value("player", "name", "Captain")
		
		var time_str = Powerupview.get_formatted_time()
		
		var my_metadata = {
			"time_survived": time_str
		}
		
		print("Uploading score: ", current_score, " | Time: ", time_str)
		SilentWolf.Scores.save_score(uploader_name, current_score, "main", my_metadata)
		 
func _on_score_timer_timeout():
	score += 1
	update_score_display()

func update_score_display():
	scorelabel.text = "Score: " + str(score)

	# You can add other functions to increase score from game events if needed
func increase_score(amount: int):
	score += amount
	if score < 0:
		score = 0
	update_score_display()
