extends Control

@onready var mainbuttons: VBoxContainer = $mainbuttons
@onready var settings: Panel = $Settings
@onready var credits : Panel = $Credits
@onready var leaderboard : Panel = $LeaderboardPanel
@onready var animation_player: AnimationPlayer = $animationstella/AnimationPlayer
@onready var buttonclick: AudioStreamPlayer = $buttonclick
@onready var high_score_label: Label = $HighScoreLabel
@onready var leaderboard_panel = $LeaderboardPanel 
@onready var score_list_container = $LeaderboardPanel/ScrollContainer/ScoreList
@onready var name_input: LineEdit = $Settings/VBoxContainer/PLAYERLABEL/NameInput

@onready var fullscreen_toggle: CheckButton = $Settings/VBoxContainer/fulltoggle
@onready var shake_setting: CheckButton = $Settings/VBoxContainer/ShakeToggle
@onready var music_slider: HSlider = $Settings/VBoxContainer/Labelmusic/MusicControl
@onready var sfx_slider: HSlider = $Settings/VBoxContainer/labelSFX/SFXControl

var config = ConfigFile.new()
var player_name = "Captain"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# mainbuttons.visible = true
	# settings.visible = false
	# credits.visible = false
	# leaderboard.visible = false
	# Powerupview.stop_timer_score()
	# $base/AnimatedSprite2D.play("base")
	# $LeaderboardPanel/Back.pressed.connect(_on_leaderboard_close_pressed)
	
	SilentWolf.configure({
		"api_key": "XUaM20pqhU255gp5amSnY74JmRRU5NeD2lop7Xbp",
		"game_id": "RogueWaves",
		"log_level": 1
	})

	_switch_menu(mainbuttons)
	Powerupview.stop_timer_score()
	$base/AnimatedSprite2D.play("base")

	load_settings()
	load_highscore()
	
func _switch_menu(target_menu: Control) -> void:
	mainbuttons.visible = false
	settings.visible = false
	credits.visible = false
	leaderboard_panel.visible = false

	if target_menu:
		target_menu.visible = true

	high_score_label.visible = (target_menu == mainbuttons)

func load_settings() -> void:
	var err = config.load("user://settings.cfg")

	if err == OK:
		var fstoggle = config.get_value("video", "fullscreen", false)
		fullscreen_toggle.set_pressed_no_signal(fstoggle)

		var volume = config.get_value("audio", "volume")
		music_slider.value = volume

		var sfx = config.get_value("audio", "sfx")
		sfx_slider.value = sfx

		var shake = config.get_value("video", "screenshake", true)
		shake_setting.set_pressed_no_signal(shake)
		cameraeffects.is_screenshake_enabled = shake

		player_name = config.get_value("player", "name", "Captain")
	else:
		print("No config found. Using defaults.")
		cameraeffects.is_screenshake_enabled = true
		player_name = "Guest" + str(randi_range(1, 100000))

	if name_input:
		name_input.text = player_name

func save_settings() -> void:
	config.set_value("video", "fullscreen", fullscreen_toggle.button_pressed)
	config.set_value("video", "screenshake", shake_setting.button_pressed)
	config.set_value("audio", "volume", music_slider.value)
	config.set_value("audio", "sfx", sfx_slider.value)

	player_name = name_input.text.strip_edges()
	if player_name == "":
		player_name = "Captain"
		name_input.text = player_name
	config.set_value("player", "name", player_name)

	config.save("user://settings.cfg")
	print("Settings Saved")


func load_highscore():
	var save_config = ConfigFile.new()
	var err = save_config.load("user://savegame.cfg")
	var best_score = 0
	
	if err == OK:
		best_score = save_config.get_value("game", "highscore", 0)
	
	if high_score_label:
		high_score_label.text = "HIGH SCORE: " + str(best_score)
		
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
	buttonclick.play()
	_switch_menu(settings)

func _on_credits_pressed() -> void:
	buttonclick.play()
	_switch_menu(credits)
	
func _on_back_pressed() -> void:
	buttonclick.play()
	_switch_menu(mainbuttons)

func _on_apply_pressed() -> void:
	buttonclick.play()
	
	fullscreen_toggle._on_toggled(fullscreen_toggle.button_pressed)
	cameraeffects.is_screenshake_enabled = shake_setting.button_pressed
	music_slider._on_value_changed(music_slider.value)
	sfx_slider._on_value_changed(sfx_slider.value)

	save_settings()
	_switch_menu(mainbuttons)

func _on_leaderboard_pressed() -> void:
	# 1. Show the panel & Hide buttons
	mainbuttons.visible = false
	leaderboard_panel.visible = true # Show the new panel
	buttonclick.play()
	
	# 2. Clear previous list (to avoid duplicates)
	for child in score_list_container.get_children():
		child.queue_free()
		
	# 3. Add a "Loading..." text temporarily
	var loading_label = Label.new()
	loading_label.text = "Loading Scores..."
	score_list_container.add_child(loading_label)
	
	print("Fetching data...")
	
	# 4. Fetch Data
	var result = await SilentWolf.Scores.get_scores(10, "main").sw_get_scores_complete
	
	# 5. Clear "Loading..."
	if is_instance_valid(loading_label):
		loading_label.queue_free()
	
	# 6. Populate List
	var rank = 1
	for score_data in result.scores:
		var row_label = Label.new()
		row_label.text = str(rank) + ". " + str(score_data.player_name) + " : " + str(score_data.score)
		
		# Optional: Styling
		row_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		score_list_container.add_child(row_label)
		rank += 1
		
		
func _on_leaderboard_close_pressed():
	leaderboard_panel.visible = false
	mainbuttons.visible = true
	buttonclick.play()

func _on_exit_pressed() -> void:
	get_tree().quit()