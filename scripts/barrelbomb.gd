extends Area2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var barrel: Sprite2D = $barrel

var explosion_scene = preload("res://scenes/explosion.tscn")

var fall_speed = randi_range(160,200)
var damage = 1

func _ready():
	add_to_group("enemy_projectiles")
	
func _process(delta):
	position.y += fall_speed * delta

func _on_body_entered(body):
	if body.has_method("take_damage_player"):
		body.take_damage_player()
		meledak()

# Logika Kena Tembak 
func take_damage(amount):
	meledak()

func meledak():
	barrel.hide()
	collision_shape_2d.disabled = true
	exploded()
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func exploded():
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	explosion.is_barrel_explosion = true
	get_tree().current_scene.add_child(explosion)
	queue_free()
