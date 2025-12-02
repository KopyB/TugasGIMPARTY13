extends AnimatedSprite2D

@onready var explosion: AnimatedSprite2D = $"."
@onready var boomsfx: AudioStreamPlayer2D = $boomsfx
@onready var bonesfx: AudioStreamPlayer2D = $bone_boom
var is_bone = false

var explosion_type = "normal" 
var is_barrel_explosion = false  
var blast_radius = 200.0          

func _ready() -> void:
	if is_barrel_explosion:
		check_blast_damage()
	if is_bone:
		exploded_bone()
	else:
		exploded()

func check_blast_damage():
	var player = get_tree().get_first_node_in_group("player")
	
	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		
		if distance <= blast_radius:
			print("Player terkena ledakan Barrel!")
			if player.has_method("take_damage_player"):
				player.take_damage_player()

func exploded():
	cameraeffects.shake(12.0, 0.25)
	explosion.show()
	boomsfx.play()
	explosion.play("boom")
	await explosion.animation_finished
	explosion.hide()
	await boomsfx.finished
	queue_free()

func exploded_bone():
	cameraeffects.shake(12.0, 0.25)
	explosion.show()
	bonesfx.play()
	explosion.play("boombone")
	await explosion.animation_finished
	explosion.hide()
	await boomsfx.finished
	queue_free()
