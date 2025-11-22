extends Area2D

enum Type {BONES, SHIPWRECK}
var current_type = Type.BONES
var hp = 3
var speed = 150 

var enemy_scene = preload("res://scenes/dummy.tscn")
var tex_bones = preload("res://assets/art/bonepile.png")
var tex_shipwreck = preload("res://assets/art/shipwreck.png")

# --- FIX: Tambahkan variabel ini ---
var is_maze_obstacle = false 

func setup_obstacle(type):
	current_type = type
	var sprite = $Sprite2D
	
	if current_type == Type.BONES:
		sprite.texture = tex_bones 
		modulate = Color.WHITE 
		hp = 3
		
		# --- FIX: Cek apakah ini bagian maze sebelum spawn minion ---
		if not is_maze_obstacle and randf() <= 0.3:
			call_deferred("spawn_minions", 1)
		
	elif current_type == Type.SHIPWRECK:
		sprite.texture = tex_shipwreck
		modulate = Color.WHITE
		hp = 5
		scale = Vector2(1.2, 1.2)
		
		# --- FIX: Cek apakah ini bagian maze sebelum spawn minion ---
		if not is_maze_obstacle and randf() <= 0.2:
			call_deferred("spawn_minions", 1)

func spawn_minions(count):
	for i in range(count):
		var enemy = enemy_scene.instantiate()
		enemy.enemy_type = 0 # Gunboat
		var offset_x = randf_range(-40, 40)
		var offset_y = randf_range(30, 60) 
		enemy.global_position = global_position + Vector2(offset_x, offset_y)
		get_tree().current_scene.add_child(enemy)

func _process(delta):
	position.y += speed * delta
	if position.y > get_viewport_rect().size.y + 100:
		queue_free()

func take_damage(amount):
	hp -= amount
	if hp <= 0:
		explode()

func _on_body_entered(body):
	if body.has_method("take_damage_player"):
		body.take_damage_player()
		explode()

func explode():
	queue_free()
