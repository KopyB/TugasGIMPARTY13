extends Area2D

signal enemy_died

var enemyship: Sprite2D = null
var collision_shape_2d: CollisionShape2D = null
var cannon: Sprite2D = null
var is_game_over = false

# TIPE MUSUH
enum Type {GUNBOAT, BOMBER, RBOMBER, PARROT, TORPEDO_SHARK, SIREN, RSIREN}
@export var enemy_type = Type.GUNBOAT
@onready var pathfollow := get_parent() as PathFollow2D
@onready var dummy_root = get_parent().get_parent()
@onready var shadow_path = dummy_root.get_node("shadowpath/parrotshadowpath")



# STATISTIK MUSUH NORMAL
var speed = 100
var health = 2
var shoot_timer = 0.0
var shoot_interval = 2.0 # Default Gunboat (2 detik)

var is_paralyzed = false

# --- SHARK VARIABLE ---
var shark_timer = 0.0
var shark_lock_duration = randf_range(5.0, 6.0) # Locks on randomly
var is_shark_charging = false
var shark_charge_direction = Vector2.ZERO
var shark_charge_speed = randf_range(1000.0, 1300.0)
var torpedoshark: AnimatedSprite2D = null
var shark_dash_count = 0

# --- SIREN VARIABLE ---
var is_diving = false
var is_screaming = false
var siren: AnimatedSprite2D = null

# LOAD ASSET 
var powerup_scene = preload("res://scenes/power_up.tscn")
var bullet_scene = preload("res://scenes/bulletenemy.tscn")
var barrel_scene = preload("res://scenes/barrelbomb.tscn")
var explosion_scene = preload("res://scenes/explosion.tscn")
var bomber_barrel = preload("res://assets/art/BomberWithBarrel.png")
var bomber_noBarrel = preload("res://assets/art/BomberNoBarrel.png")
var gun_boat = preload("res://assets/art/pirate gunboat base.png")
var floating_text_scene = preload("res://scenes/FloatingText.tscn")

@onready var taunt: AudioStreamPlayer2D = $parrot_taunt
@onready var pdeath: AudioStreamPlayer2D = $parrot_hurt
@onready var skrem : AudioStreamPlayer2D = $siren/scream
@onready var cannonsfx: AudioStreamPlayer2D = $cannon/cannonsfx
@onready var trails: AnimatedSprite2D = $trails
@onready var parrot_whistle: AudioStreamPlayer2D = $parrot_whistle

var player = null 

func _ready():
	add_to_group("enemies") 
	player = get_tree().get_first_node_in_group("player")
	
	if has_node("enemyship"):
		enemyship = $enemyship
		
	if has_node("CollisionShape2D"):
		collision_shape_2d = $CollisionShape2D
		
	if has_node("cannon"):
		cannon = $cannon
		
	if has_node("torpedoshark"):
		torpedoshark = $torpedoshark
		torpedoshark.hide() # Aman, karena sudah dicek ada atau tidak
		$trails.hide()
		
	if has_node("parrot_taunt"):
		taunt = $parrot_taunt
		
	if has_node("parrot_hurt"):
		pdeath = $parrot_hurt
	
	if has_node("siren"):
		siren = $siren
		siren.hide()
		
	# Setup awal berdasarkan tipe
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
		
	if collision_shape_2d and collision_shape_2d.shape:
		collision_shape_2d.shape = collision_shape_2d.shape.duplicate()
	
	if collision_shape_2d:
		collision_shape_2d.disabled = false
	
	# TIPE 0: GUNBOAT
	if enemy_type == Type.GUNBOAT:
		if enemyship:
			enemyship.texture = gun_boat
			enemyship.position.x = -5.0
			enemyship.scale = Vector2(0.6, 0.6)
			$trails.show()
			$trails.position = Vector2(1.0, 21.0)
			$trails.scale = Vector2(0.3,0.3)
			$trails.play("trailvert_up")
			
		if cannon:
			cannon.show()
		
		# Set Hitbox Gunboat 
		if collision_shape_2d and collision_shape_2d.shape is RectangleShape2D:
			collision_shape_2d.shape.size = Vector2(284.0, 116.0)
		
		shoot_interval = randf_range(2.0, 3.0)
		rotation_degrees = 180 # Hadap Bawah
		
	# TIPE 1: BOMBER 
	elif enemy_type == Type.BOMBER:
		if cannon: cannon.hide()
		
		if enemyship:
			enemyship.rotation = -PI/2
			enemyship.scale = Vector2(0.15, 0.15)
			$trails.show()
			$trails.position = Vector2(9.0, -16.0)
			$trails.rotation = PI/2
			$trails.scale = Vector2(0.33,0.33)
			$trails.play("trailhorz_left")
		
		# Set Hitbox Bomber (Lebih Besar)
		if collision_shape_2d and collision_shape_2d.shape is RectangleShape2D:
			collision_shape_2d.shape.size = Vector2(280.0, 145.0) 

		shoot_interval = randf_range(0.8, 1.0) 
		speed = randf_range(210, 275)
		rotation_degrees = 90 # Hadap Kanan
		
	# TIPE 2: RBOMBER (Bomber dari Kanan)
	elif enemy_type == Type.RBOMBER:
		if cannon: cannon.hide()
		
		if enemyship:
			enemyship.texture = bomber_barrel
			enemyship.rotation = -PI/2 
			enemyship.scale = Vector2(0.15, -0.15) 
			$trails.show()
			$trails.position = Vector2(-9.0, -16.0)
			$trails.rotation = PI/2
			$trails.scale = Vector2(0.33,0.33)
			$trails.play("trailhorz_left")
			
		# Set Hitbox RBomber (Sama kayak Bomber)
		if collision_shape_2d and collision_shape_2d.shape is RectangleShape2D:
			collision_shape_2d.shape.size = Vector2(280.0, 145.0)
			
		shoot_interval = randf_range(0.8, 1.0) 
		speed = randf_range(210, 275) 
		rotation_degrees = -90 

	# TIPE 3: PARROT 
	elif enemy_type == Type.PARROT:
		health = 1
		add_to_group("parrots")
		print("Parrot spawned")

	# TIPE 4: TORPEDO SHARK 
	elif enemy_type == Type.TORPEDO_SHARK:
		health = 2
		speed = 65 # Speed awal (aiming phase)
		# Hitbox Shark 
		if collision_shape_2d and collision_shape_2d.shape is RectangleShape2D:
			collision_shape_2d.shape.size = Vector2(100.0, 50.0)
		if cannon:
			cannon.hide()
		if enemyship:
			enemyship.hide()
		if torpedoshark:
			torpedoshark.show()

	# TIPE 5: SIREN 
	elif enemy_type == Type.SIREN:
		if cannon: cannon.hide()
		if enemyship:
			enemyship.hide()
		if siren:
			siren.show()
			siren.play("swim")
			siren.flip_h = false
			
		rotation_degrees = 0
		speed = randi_range(140, 160)
	
	# TIPE 6: RSIREN 
	elif enemy_type == Type.RSIREN:
		if cannon: cannon.hide()
		if enemyship:
			enemyship.hide()
		if siren:
			siren.show()
			siren.play("swim")
			siren.flip_h = true
			
		rotation_degrees = 0
		speed = randi_range(140, 160)
	
	if GameData.is_hard_mode:
		apply_hard_mode_stats()

func apply_hard_mode_stats():
	var hp_multiplier = 1.5     # Multiply?: 1.5 (darah alot)
	var speed_multiplier = 1.5  # Multiply?: 1.5 (lebih cepat)
	var shoot_multiplier = 1.1  # Multiply?: 1.1 (fire rate lebih cepat)
	var shark_detection_reducer = 1.5 # Reduce?: 1.5 (faster shark lock duration)
	
	health = int(health * hp_multiplier)
	
	if enemy_type != Type.TORPEDO_SHARK:
		speed = speed * speed_multiplier
	else:
		shark_charge_speed = shark_charge_speed * speed_multiplier
		shark_lock_duration = shark_lock_duration - shark_detection_reducer

	shoot_interval = shoot_interval / shoot_multiplier

func cease_fire():
	is_game_over = true
	shoot_timer = 0
	
	if enemy_type == Type.TORPEDO_SHARK:
		is_shark_charging = false
		shark_charge_speed = 0	
		
func _process(delta):
	if is_game_over:
		return
		
	if is_paralyzed:
		if trails and is_instance_valid(trails):
			trails.hide()
		if enemy_type == Type.GUNBOAT:
			position.y += speed/2 * delta
		elif enemy_type == Type.BOMBER or enemy_type == Type.RBOMBER or enemy_type == Type.SIREN or enemy_type == Type.RSIREN or enemy_type == Type.TORPEDO_SHARK:
			position.y += speed * delta
		return
	
		
	if enemy_type == Type.GUNBOAT:
		position.y += speed * delta
		
	elif enemy_type == Type.BOMBER:
		position.x += speed * delta
		if shoot_timer >= shoot_interval/2:
			enemyship.texture = bomber_barrel
		else:
			enemyship.texture = bomber_noBarrel
	
	elif enemy_type == Type.RBOMBER:
		position.x -= speed * delta
		if shoot_timer >= shoot_interval/2:
			enemyship.texture = bomber_barrel
		else:
			enemyship.texture = bomber_noBarrel
	
	elif enemy_type == Type.TORPEDO_SHARK:
		handle_shark_behavior(delta)

	elif enemy_type == Type.SIREN:
		if not is_screaming:	
			position.x += speed * delta
		
	elif enemy_type == Type.RSIREN:
		if not is_screaming:
			position.x -= speed * delta
	
	if enemy_type != Type.TORPEDO_SHARK and enemy_type != Type.SIREN and enemy_type != Type.RSIREN:
		shoot_timer += delta
		if shoot_timer >= shoot_interval:
			shoot_timer = 0
			perform_attack()
			
	check_despawn()

# --- FUNGSI DESPAWN ---
func check_despawn():
	var viewport_width = get_viewport_rect().size.x
	var viewport_height = get_viewport_rect().size.y

	if (position.x > viewport_width + 20 or position.y > viewport_height + 100) and not (enemy_type == Type.RBOMBER or enemy_type == Type.RSIREN):
		queue_free()

	elif enemy_type == Type.RBOMBER or enemy_type == Type.RSIREN:
		if position.x < -20 or position.y > viewport_height + 100:
			queue_free()

# --- FUNGSI PARALYZED ---
func set_paralyzed(status):
	is_paralyzed = status
	if enemy_type == Type.PARROT:
		pathfollow.is_paralyzed = status
		shadow_path.is_paralyzed = status
	if is_paralyzed:
		modulate = Color(0.5, 0.5, 0.5, 1) 
		if enemy_type == Type.TORPEDO_SHARK and torpedoshark:
			torpedoshark.pause()
		elif (enemy_type == Type.SIREN or enemy_type == Type.RSIREN) and siren:
			siren.pause()
	else:
		modulate = Color.WHITE
		# Resume Animasi Hiu
		if enemy_type == Type.TORPEDO_SHARK and torpedoshark:
			torpedoshark.play() # Lanjut mainkan animasi terakhir
			
		# Resume Animasi Siren
		elif (enemy_type == Type.SIREN or enemy_type == Type.RSIREN) and siren:
			siren.play() 
	
	if status == false and enemy_type == Type.BOMBER or enemy_type == Type.RBOMBER or enemy_type == Type.GUNBOAT:
			$trails.show()
			 
# --- FUNGSI SERANGAN ---
func perform_attack():
	if enemy_type == Type.GUNBOAT:
		fire_gunboat()
	elif enemy_type == Type.BOMBER or enemy_type == Type.RBOMBER:
		drop_barrel()
		

func fire_gunboat():
	if is_instance_valid(player):
		
		# Jika Y Musuh > Y Player, artinya Musuh ada DI BAWAH (di belakang) Player.
		# Beri toleransi sedikit (50 pixel)
		if global_position.y >= player.global_position.y - 50:
			return 
		spawn_enemy_bullet(0)
		
		if GameData.is_hard_mode:   
			if randf() <= 0.60:
				spawn_enemy_bullet(-15)  
				spawn_enemy_bullet(15)   
		
		cannonsfx.play()
		
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		
		var dir = (player.global_position - global_position).normalized()
		bullet.direction = dir
		bullet.look_at(player.global_position)
		
		get_tree().current_scene.add_child(bullet)
		cannonsfx.play()
		await cannonsfx.finished
		
func spawn_enemy_bullet(angle_offset):
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	
	bullet.look_at(player.global_position)
	bullet.rotation_degrees += angle_offset
	bullet.direction = Vector2.RIGHT.rotated(bullet.rotation)
	
	get_tree().current_scene.add_child(bullet)
			
func drop_barrel():
	var barrel = barrel_scene.instantiate()
	barrel.global_position = global_position
	
	if GameData.is_hard_mode:
		if randf() <= 0.40:
			barrel.enable_fast_mode()
			
	get_tree().current_scene.call_deferred("add_child", barrel)
	$splashsfx.play()
	# Opsional: Ubah sprite musuh jadi "kosong" sebentar (Visual Direction)
	# $Sprite2D.texture = load("res://assets/bomber_empty.png")

# --- KAMIKAZE ---
func _on_body_entered(body):
	if body.has_method("take_damage_player"):
		body.take_damage_player()
		die() 
		
# --- FUNGSI KHUSUS BEHAVIOUR SHARK ---
func handle_shark_behavior(delta):
	if not is_shark_charging:
		# FASE 1: LOCKING ON (5 Detik)
		shark_timer += delta
		
		if is_instance_valid(player):
			# Selalu menatap player (Lock on visual)
			look_at(player.global_position)
		
		# Bergerak maju pelan-pelan 
		position += Vector2.RIGHT.rotated(rotation) * speed * delta
		
		#animation
		if torpedoshark:
			torpedoshark.play("scout")
		
		# Cek waktu lock habis
		if shark_timer >= shark_lock_duration and not is_shark_charging:
			shark_dash_count = 0
			is_shark_charging = true
			#torpedoshark.play_backwards("transition")
			#await torpedoshark.animation_finished
			await torpedoshark.animation_finished
			torpedoshark.play("transition")
			#await torpedoshark.animation_finished
			start_shark_charge()
	else:
		# FASE 2: CHARGING 
		if torpedoshark:
			torpedoshark.play("swimming")
		position += shark_charge_direction * shark_charge_speed * delta
		
		if has_overlapping_bodies():
			for body in get_overlapping_bodies():
				if body.is_in_group("player"):
					_on_body_entered(body) 
					
		if GameData.is_hard_mode and shark_dash_count < 1: 
			var viewport_rect = get_viewport_rect().size
			var is_missed = false
			
			if shark_charge_direction.x > 0 and position.x > viewport_rect.x - 50:
				is_missed = true
			elif shark_charge_direction.x < 0 and position.x < 50:
				is_missed = true
			elif shark_charge_direction.y > 0 and position.y > viewport_rect.y - 50:
				is_missed = true
			elif shark_charge_direction.y < 0 and position.y < 50:
				is_missed = true
				
			if is_missed:
				if randf() <= 0.3:
					perform_double_dash()
				else:
					shark_dash_count = 99

func perform_double_dash():
	print("SHARK MISSED! PREPARING SECOND CHARGE!")
	shark_dash_count += 1
	
	is_shark_charging = false
	shark_timer = 0.0 
	shark_lock_duration = 1.0 
	
	# Reset animasi 
	if torpedoshark: torpedoshark.play("scout")
	
	var viewport = get_viewport_rect().size
	# Geser Horizontal 
	if position.x > viewport.x: position.x -= 150
	elif position.x < 0: position.x += 150
	
	# Geser Vertikal 
	if position.y > viewport.y: position.y -= 150  
	elif position.y < 0: position.y += 150         
				
func start_shark_charge():
	is_shark_charging = true
	shark_charge_direction = Vector2.RIGHT.rotated(rotation)
	$torpedoshark/sharkcharge.play()
	torpedoshark.play("swimming")
	print("SHARK CHARGING! IMMUNE ACTIVATED!")

func trigger_siren_scream():
	if is_screaming:
		return
	
	is_screaming = true
	siren.play("shot")
	print("SIREN SCREAM! PLAYER DIZZYY!")
	skrem.play()

	if is_instance_valid(player) and player.has_method("apply_dizziness"):
		player.apply_dizziness(4.0)

	await get_tree().create_timer(3.0).timeout
	siren.play("diveback")
	if not is_inside_tree(): 
		return
	siren.play("diveback")	
	await get_tree().create_timer(1.0, false).timeout
	queue_free()

# --- LOGIKA TERIMA DAMAGE & MATI ---
func take_damage(amount):
	var parrotcheck = get_tree().get_nodes_in_group("parrots").size()
	if not enemy_type == Type.PARROT:
		if parrotcheck == 0:
			if enemy_type == Type.TORPEDO_SHARK and is_shark_charging:
				if amount < 9999:
					return
			
			if enemy_type == Type.SIREN or enemy_type == Type.RSIREN:
				if is_paralyzed:
					health -= amount
					if health <= 0:
						die()
					return 
				if is_screaming:
					health -= amount
					if health <= 0:
						die()
					return
				if amount < health:
					trigger_siren_scream()
					get_tree().call_group("jumpscare_manager", "play_jumpscare")
					if GameData.is_hard_mode:
						print("HARD MODE: SIREN BLINDNESS APPLIED!")
						get_tree().call_group("visual_effect_manager", "trigger_siren_blindness", 4.0)
				health -= amount
				if health <= 0:
					die()
				return 
			health -= amount
			if health <= 0:
				die()
		else:
			taunt.play()
	else:
		health -= amount
		if health <= 0:
			pdeath.play()
			await pdeath.finished
			die()

func die():
	var add_points = 0
	var enemy_name = ""
	
	match enemy_type:
		Type.GUNBOAT:
			add_points = 3
			enemy_name = "Gunboat"
		Type.BOMBER, Type.RBOMBER:
			add_points = 3
			enemy_name = "Bomber"
		Type.SIREN, Type.RSIREN:   
			add_points = 4
			enemy_name = "Siren"
		Type.PARROT:
			add_points = 5
			enemy_name = "Parrot"
		Type.TORPEDO_SHARK:
			add_points = 8
			enemy_name = "Shark"
			
	if GameData.is_hard_mode:
		add_points += 10 
		enemy_name = "Buffed " + enemy_name	
			
	get_tree().call_group("ui_manager", "increase_score", add_points)
	spawn_floating_text(add_points, enemy_name)
	
	if not enemy_type == Type.PARROT:
		if enemyship and is_instance_valid(enemyship):
			enemyship.hide()
			
		if collision_shape_2d and is_instance_valid(collision_shape_2d):
			collision_shape_2d.disabled = true
		exploded()
		spawn_powerup_chance()
		enemy_died.emit()
		if enemy_type == Type.BOMBER or enemy_type == Type.RBOMBER:
			drop_barrel()
		queue_free()
		
	elif enemy_type == Type.PARROT:
		remove_from_group("parrots")
		spawn_powerup()
		print("Parrots alive: ", get_tree().get_nodes_in_group("parrots").size())
		hide()
		if collision_shape_2d:
			collision_shape_2d.set_deferred("disabled", true)
		if GameData.is_hard_mode and is_instance_valid(player):
			var target_x = player.global_position.x
			await trigger_airstrike(target_x)
			
		queue_free()
	else:
		queue_free()

func trigger_airstrike(target_x):
	var count = 10
	var viewport_height = get_viewport_rect().size.y
	var start_y = -50
	var gap = (viewport_height + 100) / count 
	
	for i in range(count):
		var explosion = explosion_scene.instantiate()
		explosion.is_barrel_explosion = true 
		
		
		explosion.global_position = Vector2(target_x, start_y + (i * gap))
		
		get_tree().current_scene.call_deferred("add_child", explosion)
		
		await get_tree().create_timer(0.1, false).timeout

func _on_area_entered(area: Area2D) -> void:
	if not is_instance_valid(area) or area == self:
		return
		
	# --- KASUS 1: MENABRAK OBSTACLE ---
	if area.is_in_group("obstacles"):
		print("💥 Tabrakan: Musuh vs Obstacle")
		
		# 1. Obstacle menerima damage (hancur)
		if area.has_method("take_damage"):
			area.take_damage(10) # Angka besar biar langsung hancur
			
		# 2. Musuh ini mati
		die()

func spawn_floating_text(points, e_name):
	var text_instance = floating_text_scene.instantiate()
	var display_text = "+" + str(points) + " " + e_name
	
	# Tentukan warna teks berdasarkan tipe (Opsional, biar keren)
	var text_color = Color.WHITE
	if points >= 15: text_color = Color(0.216, 0.137, 0.369, 1.0)
	elif points >= 12: text_color = Color(0.592, 0.0, 0.0, 1.0)  
	elif points >= 8: text_color = Color(0.619, 0.149, 0.392, 1)       
	elif points >= 5: text_color = Color(0.996, 0.909, 0.572, 1)    
	else: text_color = Color(0.478, 0.937, 1, 1)              
	
	text_instance.global_position = global_position
	text_instance.global_position.x += randf_range(-20, 20)
	
	get_tree().current_scene.add_child(text_instance)
	text_instance.start_animation(display_text, text_color)

func spawn_powerup_chance():
	if randf() <= 0.15: 
		spawn_powerup()

func spawn_powerup():
	var powerup = powerup_scene.instantiate()
	powerup.global_position = global_position
	
	var player = get_tree().current_scene.get_node("CharacterBody2D")
	
	var random_type = randi() % 7

	# reroll yahaha -kaiser
	while (
		(random_type == 0 and player.has_shield) or
		(random_type == 5 and player.has_second_wind)
	):
		random_type = randi() % 7
	
	powerup.current_type = random_type
	
	if enemy_type == Type.BOMBER or enemy_type == Type.RBOMBER:
		powerup.apply_xray_effect = true
		
	get_tree().current_scene.call_deferred("add_child", powerup)
		
func exploded():
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)
	
