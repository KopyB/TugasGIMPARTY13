extends Area2D

#Beri signal saat musuh mati (BOSS EXCLUSIVE)
signal enemy_died

var enemyship: Sprite2D = null
var collision_shape_2d: CollisionShape2D = null
var cannon: Sprite2D = null

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
var shark_lock_duration = randf_range(4.5, 6.0) # Locks on randomly
var is_shark_charging = false
var shark_charge_direction = Vector2.ZERO
var shark_charge_speed = randf_range(900.0, 1250.0)
var torpedoshark: AnimatedSprite2D = null

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

@onready var taunt: AudioStreamPlayer2D = $parrot_taunt
@onready var pdeath: AudioStreamPlayer2D = $parrot_hurt
@onready var skrem : AudioStreamPlayer2D = $siren/scream
@onready var cannonsfx: AudioStreamPlayer2D = $cannon/cannonsfx
@onready var trails: AnimatedSprite2D = $trails
@onready var parrot_whistle: AudioStreamPlayer2D = $parrot_whistle

var player = null # Referensi

func _ready():
	# 1. Setup Group & Player
	add_to_group("enemies") # Wajib untuk skill Admiral/Shockwave
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
		
	# 2. FIX HITBOX MENULAR (Wajib duplicate agar ukuran tiap musuh independen)
	if collision_shape_2d and collision_shape_2d.shape:
		collision_shape_2d.shape = collision_shape_2d.shape.duplicate()
	
	# 3. Aktifkan Collision (Aman dari null)
	if collision_shape_2d:
		collision_shape_2d.disabled = false
		
	# --- SETUP VISUAL & LOGIKA PER TIPE ---
	
	# TIPE 0: GUNBOAT (Musuh Standar)
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
		
		# Set Hitbox Gunboat (Ukuran Penuh)
		if collision_shape_2d and collision_shape_2d.shape is RectangleShape2D:
			collision_shape_2d.shape.size = Vector2(284.0, 116.0)
		
		shoot_interval = randf_range(2.0, 3.0)
		rotation_degrees = 180 # Hadap Bawah
		
	# TIPE 1: BOMBER (Kapal Tong)
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

		shoot_interval = randf_range(1.5, 2.0) 
		speed = randf_range(160, 200)
		rotation_degrees = 90 # Hadap Kanan
		
	# TIPE 2: RBOMBER (Bomber dari Kanan)
	elif enemy_type == Type.RBOMBER:
		if cannon: cannon.hide()
		
		if enemyship:
			enemyship.texture = bomber_barrel
			enemyship.rotation = -PI/2 
			# FIX MIRROR: Scale Y negatif agar tidak terbalik saat rotasi parent -90
			enemyship.scale = Vector2(0.15, -0.15) 
			$trails.show()
			$trails.position = Vector2(-9.0, -16.0)
			$trails.rotation = PI/2
			$trails.scale = Vector2(0.33,0.33)
			$trails.play("trailhorz_left")
			
		# Set Hitbox RBomber (Sama kayak Bomber)
		if collision_shape_2d and collision_shape_2d.shape is RectangleShape2D:
			collision_shape_2d.shape.size = Vector2(280.0, 145.0)
			
		shoot_interval = randf_range(1.5, 2.0) 
		speed = randf_range(160, 200) 
		rotation_degrees = -90 # Hadap Kiri (Mundur)

	# TIPE 3: PARROT (Burung)
	elif enemy_type == Type.PARROT:
		health = 1
		add_to_group("parrots")
		# Parrot biasanya tidak punya collision fisik yang sama, jadi kita skip setup hitbox
		print("Parrot spawned")

	# TIPE 4: TORPEDO SHARK (Hiu Penabrak)
	elif enemy_type == Type.TORPEDO_SHARK:
		health = 2
		speed = 60 # Speed awal (aiming phase)
		# Hitbox Shark (bisa pakai default atau diatur khusus)
		if collision_shape_2d and collision_shape_2d.shape is RectangleShape2D:
			collision_shape_2d.shape.size = Vector2(100.0, 50.0)
		if cannon:
			cannon.hide()
		if enemyship:
			enemyship.hide()
		if torpedoshark:
			torpedoshark.show()

	# TIPE 5: SIREN (Putri Duyung Kiri)
	elif enemy_type == Type.SIREN:
		if cannon: cannon.hide()
		if enemyship:
			enemyship.hide()
		if siren:
			siren.show()
			siren.play("swim")
			siren.flip_h = false
			
		rotation_degrees = 0
		speed = randi_range(120, 150)
	
	# TIPE 6: RSIREN (Putri Duyung Kanan)
	elif enemy_type == Type.RSIREN:
		if cannon: cannon.hide()
		if enemyship:
			enemyship.hide()
		if siren:
			siren.show()
			siren.play("swim")
			siren.flip_h = true
			
		rotation_degrees = 0
		speed = randi_range(120, 150)
		
func _process(delta):
	if is_paralyzed:
		if enemy_type == Type.GUNBOAT:
			position.y += speed/2 * delta
		elif enemy_type == Type.BOMBER or enemy_type == Type.RBOMBER:
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
	if enemy_type == Type.TORPEDO_SHARK and is_shark_charging and status == true:
		return
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
			
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		
		var dir = (player.global_position - global_position).normalized()
		bullet.direction = dir
		bullet.look_at(player.global_position)
		
		get_tree().current_scene.add_child(bullet)
		cannonsfx.play()
		await cannonsfx.finished
		
func drop_barrel():
	var barrel = barrel_scene.instantiate()
	barrel.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", barrel)
	$splashsfx.play()
	# Opsional: Ubah sprite musuh jadi "kosong" sebentar (Visual Direction)
	# $Sprite2D.texture = load("res://assets/bomber_empty.png")

# --- LOGIKA TABRAKAN (KAMIKAZE) ---
func _on_body_entered(body):
	if body.has_method("take_damage_player"):
		body.take_damage_player()
		die() 
		
# --- FUNGSI KHUSUS PERILAKU SHARK ---
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
			is_shark_charging = true
			#torpedoshark.play_backwards("transition")
			#await torpedoshark.animation_finished
			await torpedoshark.animation_finished
			torpedoshark.play("transition")
			#await torpedoshark.animation_finished
			start_shark_charge()
	else:
		# FASE 2: CHARGING (Lurus terus)
		if torpedoshark:
			torpedoshark.play("swimming")
		position += shark_charge_direction * shark_charge_speed * delta
		
		if has_overlapping_bodies():
			for body in get_overlapping_bodies():
				if body.is_in_group("player"):
					_on_body_entered(body) # Panggil fungsi paksa

func start_shark_charge():
	is_shark_charging = true
	# Kunci arah saat ini (berdasarkan rotasi terakhir ke player)
	shark_charge_direction = Vector2.RIGHT.rotated(rotation)
	$torpedoshark/sharkcharge.play()
	torpedoshark.play("swimming")
	# Visual Feedback: Ubah warna jadi Merah (Tanda bahaya & Kebal)
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

	await get_tree().create_timer(5.0).timeout
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
				return # NO DAMAGE
			
			if enemy_type == Type.SIREN or enemy_type == Type.RSIREN:
				if is_paralyzed:
					health -= amount
					if health <= 0:
						die()
					return 
				else:
					trigger_siren_scream()
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
	if not enemy_type == Type.PARROT:
		# FIX CRASH: Cek validitas node enemyship sebelum hide
		if enemyship and is_instance_valid(enemyship):
			enemyship.hide()
			
		# FIX: Cek validitas collision shape juga (praktik aman)
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
		queue_free()
	else:
		queue_free()

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

func spawn_powerup_chance():
	if randf() <= 0.25: 
		spawn_powerup()

func spawn_powerup():
	var powerup = powerup_scene.instantiate()
	powerup.global_position = global_position
	
	# Random angka acak 0 sampai 6
	var random_type = randi() % 7 
	powerup.current_type = random_type
	
	get_tree().current_scene.call_deferred("add_child", powerup)
		
func exploded():
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)
	
