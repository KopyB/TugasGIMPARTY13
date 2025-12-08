extends Area2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var barrel: Sprite2D = $barrel

var explosion_scene = preload("res://scenes/explosion.tscn")
var is_already_exploded = false
var fall_speed = randi_range(160,200)
var damage = 1
var is_fast_mode = false

func _ready():
	add_to_group("enemy_projectiles")
	if is_fast_mode:
		fall_speed *= 1.8
		if barrel:
			var tween = create_tween().set_loops()
			tween.tween_property(barrel, "modulate", Color(1, 0.5, 0.5), 0.2)
			tween.tween_property(barrel, "modulate", Color.WHITE, 0.2)
		
		# Timer Meledak
		get_tree().create_timer(randf_range(1.0, 1.5), false).timeout.connect(_on_auto_explode)
	
func _process(delta):
	position.y += fall_speed * delta
	
func enable_fast_mode():
	is_fast_mode = true

func _on_auto_explode():
	if is_instance_valid(self) and not is_already_exploded:
		meledak()

func _on_body_entered(body):
	if body.has_method("take_damage_player"):
		body.take_damage_player()
		meledak()

# Logika Kena Tembak 
func take_damage(amount):
	meledak()

func meledak():
	if is_already_exploded:
		return
	is_already_exploded = true
	barrel.hide()
	collision_shape_2d.set_deferred("disabled", true)
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
