extends Area2D

enum Type {BONES, SHIPWRECK}
var current_type = Type.BONES
var hp = 3
var speed = 150 

var enemy_scene = preload("res://scenes/dummy.tscn")

func setup_obstacle(type):
	current_type = type
	
	if current_type == Type.BONES:
		modulate = Color.GRAY 
		hp = 3
		
		# --- PERBAIKAN DI SINI ---
		# Jangan selalu spawn musuh (kasih chance 30% saja)
		# Dan spawn CUMA 1 musuh, jangan 3.
		if randf() <= 0.3:
			call_deferred("spawn_minions", 1)
		
	elif current_type == Type.SHIPWRECK:
		modulate = Color.SADDLE_BROWN
		hp = 5
		scale = Vector2(1.2, 1.2)
		
		# Shipwreck lebih jarang lagi (20% chance)
		if randf() <= 0.2:
			call_deferred("spawn_minions", 1)

func spawn_minions(count):
	for i in range(count):
		var enemy = enemy_scene.instantiate()
		enemy.enemy_type = 0 # Gunboat
		
		# Beri jarak acak agar tidak menumpuk pas di tengah batu
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
