extends Area2D

enum Type {BONESA, BONESB, BONESC, SHIPWRECKA, SHIPWRECKB, SHIPWRECKC}
var current_type = Type.BONESA
var hp = 2
var speed = 150 


var enemy_scene = preload("res://scenes/dummy.tscn")
var explosion_scene = preload("res://scenes/explosion.tscn")
var floating_text_scene = preload("res://scenes/FloatingText.tscn")

# --- FIX: Tambahkan variabel ini ---
var is_maze_obstacle = false 

func setup_obstacle(type):
	add_to_group("obstacles")
	current_type = type
	var shipwreck = $shipwreck
	var bone = $bone
	
	if current_type == Type.BONESA:
		shipwreck.hide()
		bone.show()
		bone.play("boneA")
		hp = 3
		
	elif current_type == Type.BONESB:
		shipwreck.hide()
		bone.show()
		bone.play("boneB")
		hp = 3
	
	elif current_type == Type.BONESC:
		shipwreck.hide()
		bone.show()
		bone.play("boneC")
		hp = 3
		
	elif current_type == Type.SHIPWRECKA:
		shipwreck.show()
		bone.hide()
		shipwreck.play("shipA")
		hp = 5
		scale = Vector2(1.2, 1.2)
		
	elif current_type == Type.SHIPWRECKB:
		shipwreck.show()
		bone.hide()
		shipwreck.play("shipB")
		hp = 5
		scale = Vector2(1.2, 1.2)

	elif current_type == Type.SHIPWRECKC:
		shipwreck.show()
		bone.hide()
		shipwreck.play("shipC")
		hp = 5
		scale = Vector2(1.2, 1.2)
		
	if not is_maze_obstacle:
		# KASUS A: Jika Tipe BONES (Chance 30%)
		if current_type == Type.BONESA or Type.BONESB or Type.BONESC:
			if randf() <= 0.3:
				call_deferred("spawn_minions", 1)
		
		# KASUS B: Jika Tipe KAPAL KARAM (Chance 20%)
		else:
			if randf() <= 0.2:
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
		get_tree().call_group("ui_manager", "increase_score", 1)
		var txt = floating_text_scene.instantiate()
		txt.global_position = global_position
		get_tree().current_scene.add_child(txt)
		txt.start_animation("+1 Object", Color(0.423, 0.541, 0.564, 1))
		explode()

func _on_body_entered(body):
	if body.has_method("take_damage_player"):
		body.take_damage_player()
		explode()

func explode():
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	
	if current_type == Type.BONESA or current_type == Type.BONESB or current_type == Type.BONESC:
		explosion.is_bone = true
	else:
		explosion.is_bone = false
	
	get_tree().current_scene.add_child(explosion)
	queue_free()
