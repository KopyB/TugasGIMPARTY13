extends Area2D

var speed = 800
var direction = Vector2.ZERO 
var explosion_scene = preload("res://scenes/explosion.tscn")

func _ready():
	add_to_group("enemy_projectiles")
	
func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	print("Peluru Musuh nabrak: ", body.name)
	# Cek collision 
	if body.has_method("take_damage_player"):
		
		body.take_damage_player()
		queue_free()
	else: 
		pass

func meledak():
	hide()
	exploded()
	queue_free()
	
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
	
func exploded():
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)
