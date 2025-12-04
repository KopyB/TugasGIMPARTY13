extends Area2D

@onready var explosion: AnimatedSprite2D = $AnimatedSprite2D 
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var boomsfx: AudioStreamPlayer2D = $boomsfx
@onready var bonesfx: AudioStreamPlayer2D = $bone_boom
var is_bone = false

var explosion_type = "normal" 
var is_barrel_explosion = false         

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	if is_bone:
		exploded_bone()
	else:
		exploded()
		
func _on_body_entered(body: Node2D) -> void:
	if not is_barrel_explosion:
		return
		
	if body.is_in_group("player"):
		if body.has_method("take_damage_player"):
			body.take_damage_player()
			# Matikan collision setelah kena 1 kali agar tidak kena damage lagi
			collision_shape.set_deferred("disabled", true) 

func _on_area_entered(area: Area2D) -> void:
	if not is_barrel_explosion:
		return
		
	if area.is_in_group("enemy_projectiles"):
		if area.has_method("meledak"):
			area.call_deferred("meledak")
	
func exploded():
	cameraeffects.shake(12.0, 0.25)
	explosion.show()
	boomsfx.play()
	explosion.play("boom")
	await explosion.animation_finished
	collision_shape.set_deferred("disabled", true)
	explosion.hide()
	await boomsfx.finished
	queue_free()

func exploded_bone():
	cameraeffects.shake(12.0, 0.25)
	explosion.show()
	bonesfx.play()
	explosion.play("boombone")
	await explosion.animation_finished
	collision_shape.set_deferred("disabled", true)
	explosion.hide()
	await boomsfx.finished
	queue_free()
