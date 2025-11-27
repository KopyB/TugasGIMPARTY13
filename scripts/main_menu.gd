extends Control

@onready var mainbuttons: VBoxContainer = $mainbuttons
@onready var settings: Panel = $Settings
@onready var credits : Panel = $Credits
@onready var config = ConfigFile.new()
@onready var animation_player: AnimationPlayer = $animationstella/AnimationPlayer
@onready var buttonclick: AudioStreamPlayer = $buttonclick
@onready var high_score_label: Label = $HighScoreLabel

var fstoggle
var shake_setting
var volume
var sfx

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mainbuttons.visible = true
	settings.visible = false
	credits.visible = false
	Powerupview.stop_timer_score()
	
	SilentWolf.configure({
	"api_key": "XUaM20pqhU255gp5amSnY74JmRRU5NeD2lop7Xbp",
	"game_id": "RogueWaves",
	"log_level": 1
  })
	
	var load_err = config.load("user://settings.cfg")
	if load_err == OK:
		# Apply loaded settings
		fstoggle = config.get_value("video", "fullscreen")
		$Settings/VBoxContainer/fulltoggle._on_toggled(fstoggle)
		$Settings/VBoxContainer/fulltoggle.button_pressed = fstoggle
		volume = config.get_value("audio", "volume")
		$Settings/VBoxContainer/Labelmusic/MusicControl._on_value_changed(volume)
		$Settings/VBoxContainer/Labelmusic/MusicControl.value = volume
		sfx = config.get_value("audio", "sfx")
		$Settings/VBoxContainer/labelSFX/SFXControl._on_value_changed(sfx)
		$Settings/VBoxContainer/labelSFX/SFXControl.value = sfx
		shake_setting = config.get_value("video", "screenshake", true) 
		$Settings/VBoxContainer/ShakeToggle.button_pressed = shake_setting
		cameraeffects.is_screenshake_enabled = shake_setting	
	else:
		print("No config found. Using default settings.")
		cameraeffects.is_screenshake_enabled = true
	high_score_label.show()
	load_highscore()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
	
func load_highscore():
	var save_config = ConfigFile.new()
	var err = save_config.load("user://savegame.cfg")
	
	var best_score = 0
	
	if err == OK:
		best_score = save_config.get_value("game", "highscore", 0)
	
	if high_score_label:
		high_score_label.text = "HIGH SCORE: " + str(best_score)
		
func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_start_pressed() -> void:
	#animation stella zooming
	buttonclick.play()
	$animationstella/wavestransition.play()
	animation_player.play("nyoom")
	await animation_player.animation_finished
	
	#fade in transition
	Transition.load_scene("res://scenes/main.tscn")
	#get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_settings_pressed() -> void:
	mainbuttons.visible = false
	settings.visible = true
	buttonclick.play()
	high_score_label.hide()
func _on_credits_pressed() -> void:
	mainbuttons.visible = false
	credits.visible = true
	buttonclick.play()
	high_score_label.hide()
	
func _on_back_pressed() -> void:
	_ready()
	buttonclick.play()

func _on_apply_pressed() -> void:
	fstoggle = $Settings/VBoxContainer/fulltoggle.button_pressed
	$Settings/VBoxContainer/fulltoggle._on_toggled(fstoggle)
	print(fstoggle)
	
	shake_setting = $Settings/VBoxContainer/ShakeToggle.button_pressed
	cameraeffects.is_screenshake_enabled = shake_setting
	print(shake_setting)
	
	volume = $Settings/VBoxContainer/Labelmusic/MusicControl.value
	$Settings/VBoxContainer/Labelmusic/MusicControl._on_value_changed(volume)
	print(volume)
	
	sfx = $Settings/VBoxContainer/labelSFX/SFXControl.value
	$Settings/VBoxContainer/labelSFX/SFXControl._on_value_changed(sfx)
	print(sfx)

	# Example settings—replace with your own controls
	config.set_value("video", "fullscreen", fstoggle)
	config.set_value("video", "screenshake", shake_setting)
	config.set_value("audio", "volume", volume)
	config.set_value("audio", "sfx", sfx)

	# Save file
	var err = config.save("user://settings.cfg")
	if err != OK:
		print("Failed to save config!")
	
	buttonclick.play()
	# Go back to main layout
	_ready()
