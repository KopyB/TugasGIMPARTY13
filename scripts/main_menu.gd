extends Control

@onready var mainbuttons: VBoxContainer = $mainbuttons
@onready var settings: Panel = $Settings
@onready var extras_panel: Panel = $Extras
@onready var index_panel: Panel = $Index
@onready var achievements_panel: Panel = $Achievements
@onready var achieve_list: VBoxContainer = $Achievements/ScrollContainer/AchieveList
@onready var credits : Panel = $Credits
@onready var leaderboard : Panel = $LeaderboardPanel
@onready var config = ConfigFile.new()
@onready var animation_player: AnimationPlayer = $animationstella/AnimationPlayer
@onready var buttonclick: AudioStreamPlayer = $buttonclick
@onready var high_score_label: Label = $HighScoreLabel
@onready var leaderboard_panel = $LeaderboardPanel 
@onready var score_list_container = $LeaderboardPanel/ScrollContainer/ScoreList
@onready var name_input: LineEdit = $Settings/VBoxContainer/PLAYERLABEL/NameInput
@onready var difficulty_panel: Panel = $DifficultyPanel
@onready var hard_button: Button = $DifficultyPanel/VBoxContainer/HARD
@onready var delete_confirm_panel: Panel = $DeleteConfirm

var starting_game: bool = false

var fstoggle
var shake_setting
var volume
var sfx
var player_name = "Captain"

var fonttheme : FontFile = preload("res://assets/norwester.otf")
# Data Achievement (Konfigurasi)
var achievements_data = [
	{"id": "rogue_waves","title": "Rogue Waves","desc": "Play the game for the first time","target": 1 },
	{"id": "powerup_1","title": "Starter Pack","desc": "Use a powerup crate","target": 1},
	{"id": "powerup_100","title": "Greedy Pack","desc": "Use powerup crate 100 times","target": 100},
	{"id": "powerup_1000","title": "Champion Pack","desc": "Use powerup crate 1000 times","target": 1000},
	{"id": "powerup_5000","title": "Mythical Pack","desc": "Use powerup crate 5000 times","target": 5000},
	{"id": "revive_1","title": "Immortality","desc": "Revive yourself using Second Wind","target": 1},
	{"id": "death_ray","title": "Death Ray","desc": "Eliminate 10 opponents using single Kraken Slayer","target": 1 },
	{"id": "overload_master", "title": "Need more power...", "desc": "Have every power (and debuff) at the same time", "target": 1},
	{ "id": "kill_30", "title": "Rookie", "desc": "Eliminate 30 opponents", "target": 30 },
	{ "id": "kill_150", "title": "Pro", "desc": "Eliminate 150 opponents", "target": 150 },
	{ "id": "kill_700", "title": "Hunter", "desc": "Eliminate 700 opponents", "target": 700 },
	{ "id": "kill_2000", "title": "True Hunter", "desc": "Eliminate 2000 opponents", "target": 2000 },
	{ "id": "kill_15000", "title": "Omnipotent", "desc": "Eliminate 15000 opponents", "target": 15000 },
	{ "id": "kill_80000", "title": "That's enough, brochacho", "desc": "Eliminate 80000 opponents", "target": 80000 },
	{ "id": "score_200", "title": "Good amount for starter", "desc": "Obtain 200 points", "target": 200 },
	{ "id": "score_800", "title": "Point Master", "desc": "Obtain 800 points", "target": 800 },
	{ "id": "score_1500", "title": "The Collector", "desc": "Obtain 1500 points and unlock Hard Mode", "target": 1500 },
	{ "id": "score_4000", "title": "Point Grinder", "desc": "Obtain 4000 points", "target": 4000 },
	{ "id": "score_10000", "title": "Unstoppable", "desc": "Obtain 10000 points", "target": 10000 },
	{ "id": "score_50000", "title": "TOTAL POINT DEATH", "desc": "Obtain 50000 points", "target": 50000 },
	{ "id": "dont_get_lost", "title": "Dont get lost...", "desc": "Survive obstacle maze", "target": 1 },
	{ "id": "sharkphobia", "title": "Sharkphobia", "desc": "Survive shark attack", "target": 1 },
	{ "id": "nightmare_shark", "title": "Nightmare Shark", "desc": "Survive harder version of shark attack", "target": 1 },
	{ "id": "chaos_survivor", "title": "...?", "desc": "Survive chaos shark attack", "target": 1 },
	{ "id": "challenger", "title": "Challenger", "desc": "Play Hard Mode for the first time", "target": 1 },
	{ "id": "cheater", "title": "Cheater", "desc": "Enter cheat code", "target": 1 }
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	StormFX.reset_menu()
	if not has_node("Departure"):
		var departure := preload("res://scripts/menu_departure.gd").new()
		departure.name = "Departure"
		add_child(departure)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mainbuttons.visible = true
	settings.visible = false
	credits.visible = false
	leaderboard.visible = false
	difficulty_panel.hide()
	extras_panel.hide()
	index_panel.hide()
	achievements_panel.hide()
	Powerupview.stop_timer_score()
	$base/AnimatedSprite2D.play("base")
	if not $LeaderboardPanel/Back.pressed.is_connected(_on_leaderboard_close_pressed):
		$LeaderboardPanel/Back.pressed.connect(_on_leaderboard_close_pressed)
	$mainbuttons/START.grab_focus.call_deferred()
	
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
		player_name = config.get_value("player", "name", "Captain")
		if name_input:
			name_input.text = player_name
	else:
		print("No config found. Using default settings.")
		cameraeffects.is_screenshake_enabled = true
		var def_username = "Guest" + str(randi_range(1, 100000))
		if name_input: name_input.text = def_username
	high_score_label.show()
	high_score_label.add_theme_stylebox_override("normal", theme.get_stylebox("panel", "Panel"))
	load_highscore()
	
	var current_best = 0
	if config.load("user://savegame.cfg") == OK:
		current_best = config.get_value("game", "highscore", 0)
	
	GameData.check_score_achievements(current_best)

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
	if starting_game or Transition.busy:
		return
	buttonclick.play()
	mainbuttons.visible = false
	difficulty_panel.show()
	check_hard_mode_unlock()
	$DifficultyPanel/VBoxContainer/NORMAL.grab_focus()
	
func check_hard_mode_unlock():
	var temp_config = ConfigFile.new() 
	var err = temp_config.load("user://savegame.cfg")
	var best_score = 0
	
	if err == OK:
		best_score = temp_config.get_value("game", "highscore", 0)
	
	if best_score >= 1500:
		# UNLOCKED
		hard_button.disabled = false
		hard_button.text = "HARD"
		hard_button.modulate = Color.WHITE 
		hard_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		# LOCKED
		hard_button.disabled = true
		hard_button.text = "LOCKED  1500 POINTS"
		hard_button.modulate = Color.WHITE 
		hard_button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN

func _on_normal_pressed() -> void:
	if starting_game or Transition.busy:
		return
	buttonclick.play()
	
	# Set GameData ke Normal
	GameData.is_hard_mode = false
	StormFX.begin_departure(false)
	print("Mode Selected: NORMAL")
	
	start_game_sequence()
	
func _on_hard_pressed() -> void:
	if starting_game or Transition.busy:
		return
	buttonclick.play()
	
	# Set GameData ke Hard
	GameData.is_hard_mode = true
	StormFX.begin_departure(true)
	print("Mode Selected: HARD")
	GameData.check_and_unlock("challenger", "Challenger")
	start_game_sequence()
	
func start_game_sequence():
	if starting_game or Transition.busy:
		return
	starting_game = true

	if not GameData.has_played_game:
		GameData.has_played_game = true
		GameData.save_stats()
		GameData.check_and_unlock("rogue_waves", "Rogue Waves")
	var departed: bool = await Transition.depart_from_menu(self)
	if not departed:
		StormFX.reset_menu()
	# The caller may survive a failed scene load and must remain usable.
	if is_inside_tree():
		starting_game = false

func _on_difficulty_back_pressed() -> void:
	if starting_game or Transition.busy:
		return
	buttonclick.play()
	difficulty_panel.hide()
	mainbuttons.visible = true
	$mainbuttons/START.grab_focus()

func _on_settings_pressed() -> void:
	mainbuttons.visible = false
	settings.visible = true
	buttonclick.play()
	high_score_label.hide()
	
func _on_extras_pressed() -> void:
	buttonclick.play()
	mainbuttons.visible = false     
	extras_panel.show()     
	high_score_label.hide() 

func _on_extras_back_pressed() -> void:
	buttonclick.play()
	extras_panel.hide()
	mainbuttons.visible = true
	high_score_label.show()
	
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
	
	if name_input:
		player_name = name_input.text
		
		if player_name.strip_edges() == "":
			player_name = "Captain"
			name_input.text = player_name
			
		print("Player Name Saved: ", player_name)
		
	# Example settings—replace with your own controls
	config.set_value("video", "fullscreen", fstoggle)
	config.set_value("video", "screenshake", shake_setting)
	config.set_value("audio", "volume", volume)
	config.set_value("audio", "sfx", sfx)
	config.set_value("player", "name", player_name)
	
	# Save file
	var err = config.save("user://settings.cfg")
	if err != OK:
		print("Failed to save config!")
	
	buttonclick.play()
	# Go back to main layout
	_ready()


func _on_leaderboard_pressed() -> void:
	# Show the panel & Hide buttons
	mainbuttons.visible = false
	leaderboard_panel.visible = true 
	buttonclick.play()
	
	# Clear previous list (to avoid duplicates)
	for child in score_list_container.get_children():
		child.queue_free()
		
	# Add a "Loading" text temporarily
	var loading_label = Label.new()
	loading_label.text = "Loading Scores..."
	score_list_container.add_child(loading_label)
	
	print("Fetching data...")
	
	# Fetch Data
	var result = await SilentWolf.Scores.get_scores(10, "main").sw_get_scores_complete
	
	# Clear "Loading..."
	if is_instance_valid(loading_label):
		loading_label.queue_free()
	
	# 6. Populate List
	var rank = 1
	for score_data in result.scores:
		var row_label = Label.new()
		var meta = score_data.get("metadata")
		
		if meta and "time_survived" in meta:
			var time_text = str(meta["time_survived"])
			row_label.text = str(rank) + ". " + str(score_data.player_name) + " : " + str(score_data.score) + " (" + time_text + ")"
		else:
			row_label.text = str(rank) + ". " + str(score_data.player_name) + " : " + str(score_data.score)
			
		row_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_list_container.add_child(row_label)
		rank += 1
		
func _on_leaderboard_close_pressed():
	leaderboard_panel.visible = false
	mainbuttons.visible = true
	buttonclick.play()

func _on_index_pressed() -> void:
	buttonclick.play()
	extras_panel.hide()     
	index_panel.show()    

func _on_index_back_pressed() -> void:
	buttonclick.play()
	extras_panel.show()     
	index_panel.hide() 

func _on_achievements_pressed() -> void:
	buttonclick.play()
	extras_panel.hide()
	achievements_panel.show()
	update_achievements_ui()
	
func _on_achievements_back_pressed() -> void:
	buttonclick.play()
	extras_panel.show()
	achievements_panel.hide()

func _on_credits_pressed() -> void:
	buttonclick.play()
	extras_panel.hide()
	credits.show()
	
func _on_credits_back_pressed() -> void:
	buttonclick.play()
	extras_panel.show()
	credits.hide()

func _on_delete_data_pressed() -> void:
	buttonclick.play()
	extras_panel.hide() 
	delete_confirm_panel.show()

func _on_cancel_delete__pressed() -> void:
	buttonclick.play()
	delete_confirm_panel.hide()
	extras_panel.show()

func _on_confirm_delete_pressed() -> void:
	buttonclick.play()
	GameData.reset_all_data()
	if high_score_label:
		high_score_label.text = "HIGH SCORE: 0"
	hard_button.disabled = true
	hard_button.text = "LOCKED  1500 POINTS"
	hard_button.modulate = Color.WHITE
	if name_input:
		name_input.text = "Captain"
	delete_confirm_panel.hide()
	extras_panel.show()

func update_achievements_ui():
	# clear list lama
	for child in achieve_list.get_children():
		achieve_list.remove_child(child)
		child.queue_free()
		
	var temp_config = ConfigFile.new() 
	var current_highscore = 0
	var err = temp_config.load("user://savegame.cfg")
	if err == OK:
		current_highscore = temp_config.get_value("game", "highscore", 0)
		
	var bool_ids = ["death_ray", "overload_master", 
					"dont_get_lost", "sharkphobia", "nightmare_shark", 
					"chaos_survivor", "challenger", "cheater"]	
	# loop data buat baru
	for data in achievements_data:
		var is_unlocked = false
		var current_val = 0
		
		if data["id"] == "rogue_waves":
			is_unlocked = GameData.has_played_game
			current_val = 1 if is_unlocked else 0
			
		elif "powerup" in data["id"]: 
			# cek id dengan powerup
			current_val = GameData.powerups_collected
			is_unlocked = current_val >= data["target"]
			
		elif data["id"] == "revive_1":
			current_val = GameData.revives_count
			is_unlocked = current_val >= data["target"]
			
		elif "kill_" in data["id"]:
			current_val = GameData.enemies_killed
			is_unlocked = current_val >= data["target"]
			
		elif "score_" in data["id"]:
			current_val = current_highscore
			is_unlocked = current_val >= data["target"]
		
		elif data["id"] in bool_ids:
			is_unlocked = data["id"] in GameData.unlocked_achievements
			current_val = 1 if is_unlocked else 0
			
		is_unlocked = is_unlocked or str(data["id"]) in GameData.unlocked_achievements
		var progress_text = ""
		
		if is_unlocked:
			progress_text = "Completed"
		else:
			var display_val = min(current_val, data["target"])
			progress_text = str(display_val) + " / " + str(data["target"])
		
		var item := PanelContainer.new()
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.custom_minimum_size.y = 104
		item.mouse_filter = Control.MOUSE_FILTER_PASS
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.09, 0.16, 0.20, 0.98)
		style.border_color = Color(0.88, 0.76, 0.46) if is_unlocked else Color(0.38, 0.45, 0.49)
		style.set_border_width_all(2)
		style.set_corner_radius_all(6)
		style.content_margin_left = 18
		style.content_margin_right = 18
		style.content_margin_top = 12
		style.content_margin_bottom = 12
		item.add_theme_stylebox_override("panel", style)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 18)
		item.add_child(row)
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(copy)
		var title := Label.new()
		title.text = str(data["title"])
		title.add_theme_font_size_override("font_size", 24)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(title)
		var description := Label.new()
		description.text = str(data["desc"])
		description.add_theme_font_size_override("font_size", 18)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(description)
		var progress := Label.new()
		progress.text = progress_text
		progress.custom_minimum_size.x = 175
		progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(progress)
		achieve_list.add_child(item)
