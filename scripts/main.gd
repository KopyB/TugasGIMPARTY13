extends Control

@onready var bgm_player: AudioStreamPlayer = $AudioStreamPlayer

var normal_music = preload("res://assets/audio/Rogue Waves.ogg") 
var hard_music = preload("res://assets/audio/miwa hardmode.ogg")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Powerupview.stop_timer_score()
	Powerupview.start_timer_score()# Replace with function body.
	$tutoriallayer/AnimationPlayer.play("tutorialfade")
	setup_and_play_music()
	
func setup_and_play_music():
	if bgm_player:
		if GameData.is_hard_mode:
			bgm_player.stream = hard_music
			bgm_player.set_target_volume(8.0) 
			
		else:
			print("Mode Normal: Memutar Musik Biasa")
			bgm_player.stream = normal_music
			bgm_player.set_target_volume(0.0)

		if bgm_player.stream:
			bgm_player.stream.loop = true
	
		bgm_player.play()
