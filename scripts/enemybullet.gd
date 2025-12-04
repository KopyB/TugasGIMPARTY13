extends Area2D

var speed = 800
var direction = Vector2.ZERO 
var explosion_scene = preload("res://scenes/explosion.tscn")

func _ready():
	add_to_group("enemy_projectiles")
	area_entered.connect(_on_area_entered)
	
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

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_projectiles"):
		return

	# Cek jika nabrak Barrel
	if area.has_method("meledak") or area.has_method("take_damage"):
		print("Peluru Musuh nabrak Barrel!")
		
		if area.has_method("take_damage"):
			area.take_damage(1)
		elif area.has_method("meledak"):
			area.meledak()
			
		meledak()
	
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
