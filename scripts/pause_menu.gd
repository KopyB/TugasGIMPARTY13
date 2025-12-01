extends Control

@export var state: Label
@export var resume_button: Button
@onready var scorelabel: Label = $VBoxContainer/scorelabel
@onready var timer: Timer = $Timer
var score: int = 0
var is_gameover = false
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
	
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("escape") and not get_tree().paused:
		toggled_handler(1) #masukin var baru buat klo mati atau tidak
	elif Input.is_action_just_pressed("escape") and get_tree().paused:
		resume()
	
func toggled_handler(type: int) -> void:
	state.text = MAP_TYPE_STRING[type]
	if type == 0:
		is_gameover = true
		resume_button.hide()
		scorelabel.show()
		check_and_save_highscore(score)
	else:
		resume_button.show()
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
		
		print("Uploading score as: ", uploader_name)
		SilentWolf.Scores.save_score(uploader_name, current_score, "main")
		 
func _on_score_timer_timeout():
	score += 1
	update_score_display()

func update_score_display():
	scorelabel.text = "Score: " + str(score)

	# You can add other functions to increase score from game events if needed
func increase_score(amount: int):
	score += amount
	update_score_display()
