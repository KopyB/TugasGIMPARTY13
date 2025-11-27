extends CanvasLayer

@onready var anim_sprite = $CenterContainer/AnimatedSprite2D
@onready var scream_sfx = $AudioStreamPlayer
@onready var background = $ColorRect

func _ready():
	hide()
	add_to_group("jumpscare_manager")

func play_jumpscare():
	if visible: return 
	show() 
	
	anim_sprite.frame = 0 
	anim_sprite.play("scare") 
	
	await anim_sprite.animation_finished
	await get_tree().create_timer(0.1).timeout
	hide()
