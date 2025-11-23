extends CharacterBody2D

var target_position : Vector2
# VARIABEL MOVEMENT
var rotation_speed = 2
var rotation_direction = 0
var normal_speed = 300.0
var current_speed = normal_speed
var is_dead = false
var is_dizzy = false
var dizzy_timer = 0.0

# VARIABEL STATUS POWER-UP
var has_shield = false
var is_multishot_active = false
var is_artillery_active = false # Tembakan cepat/banyak
var is_kraken_active = false
var has_second_wind = false
var laser_scene = preload("res://scenes/LaserBeam.tscn")
var active_laser_node = null

var bullet_scene = preload("res://scenes/bulletplayer.tscn")
@onready var shoot_timer = $Timer
var tex_artillery = preload("res://assets/art/ArtilleryBurstProjectile.png")

var explosion_scene = preload("res://scenes/explosion.tscn")
#animation
@onready var anim_shipbase = $shipbase
@onready var anim_cannon = $cannon
@onready var anim_stella = $stellarist
@onready var k_sturret: Sprite2D = $KSturret
@onready var shield_anim: AnimatedSprite2D = $shield_anim
@onready var shockwaves_anim: AnimatedSprite2D = $shockwaves_anim

@onready var skill_timer = $SkillDurationTimer

func _ready():
	add_to_group("player")
	anim_shipbase.add_to_group("player_anims")
	anim_cannon.add_to_group("player_anims")
	anim_stella.add_to_group("player_anims")
	for node in get_tree().get_nodes_in_group("player_anims"):
		node.show()
	target_position = global_position # Store initial position as center
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	k_sturret.hide()
	shield_anim.hide()
	shockwaves_anim.hide()
# --- FUNGSI MENERIMA DAMAGE & MATI ---
# Pastikan logika mati Anda ada di fungsi ini
func take_damage_player():
	# --- LOGIKA SHIELD DI SINI ---
	if has_shield:
		has_shield = false
		shield_anim.show()
		shield_anim.play_backwards()
		await shield_anim.animation_finished
		shield_anim.hide()
		print("Shield Pecah!")
		return 
	
	# --- LOGIKA REVIVE DI SINI ---
	if has_second_wind:
		trigger_shockwave() # Ledakkan semua musuh
		has_second_wind = false # Pakai nyawa cadangannya
		print("SECOND WIND ACTIVATED! Player bangkit kembali!")
		return 

	# Jika tidak ada shield & tidak ada second wind -> MATI
	die()

func die():
	is_dead = true
	print("Player Mati - Memulai Sequence Game Over")
	reset_all_skills()
	get_tree().call_group("enemy_projectiles", "queue_free")
	# Matikan visual kapal agar terlihat 'hancur'
	for node in get_tree().get_nodes_in_group("player_anims"):
		node.visible = false
	set_physics_process(false) # Matikan pergerakan
	
	# Panggil UI Manager lewat Group
	# Angka 0 artinya tipe "YOU DIED!" (sesuai dictionary di pause_menu.gd)
	get_tree().call_group("ui_manager", "toggled_handler", 0)
	
# Fungsi utama yang dipanggil oleh bola PowerUp
func apply_powerup(type):
	# PowerUp.gd harus bisa diakses, atau kita pakai angka integer 0-3
	# 0: SHIELD, 1: MULTISHOT, 2: ARTILLERY, 3: SPEED
	
	print("Dapat PowerUp Tipe: ", type)
	
	match type:
		0: # SHIELD
			activate_shield()
		1: # MULTISHOT
			activate_multishot()
		2: # ARTILLERY BURST
			activate_artillery()
		3: # SPEED
			activate_speed()
		4: # KRAKEN SLAYER
			activate_kraken()      
		5: # SECOND WIND
			activate_second_wind() 
		6: # ADMIRAL WILL
			activate_admiral()

# --- LOGIKA 1: SHIELD ---
func activate_shield():
	has_shield = true
	shield_anim.play("shieldup")
	print("Shield Aktif!")

# --- LOGIKA 2: MULTISHOT (Sudah Anda punya) ---
func activate_multishot():
	is_multishot_active = true
	
	# Ganti create_timer dengan skill_timer
	skill_timer.start(7.0)
	await skill_timer.timeout
	
	is_multishot_active = false

# --- LOGIKA 3: ARTILLERY (Burst/Fast Fire) ---
func activate_artillery():
	is_artillery_active = true
	shoot_timer.wait_time = 0.1 # Tembak jadi ngebut banget (0.1 detik)
	
	skill_timer.start(5.0)
	await skill_timer.timeout # Durasi 5 detik
	
	is_artillery_active = false
	shoot_timer.wait_time = 0.2 # Balikin ke speed tembak normal (sesuaikan angka ini)

# --- LOGIKA 4: SPEED (Movement) ---
func activate_speed():
	current_speed = 800.0 
	rotation_speed = 6
	
	skill_timer.start(5.0)
	await skill_timer.timeout # Durasi 5 detik
	
	current_speed = normal_speed # Balik normal
	rotation_speed = 2
	
	# --- LOGIKA BARU: KRAKEN SLAYER (LASER) ---
func activate_kraken():
	print("KRAKEN RELEASED!")
	is_kraken_active = true 
	anim_cannon.hide()
	
	# Spawn Laser
	# Kita tunggu sebentar (animasi charge) pakai timer juga
	skill_timer.start(0.5)
	await skill_timer.timeout 
	
	if active_laser_node == null:
		active_laser_node = laser_scene.instantiate()
		call_deferred("add_child", active_laser_node)
		active_laser_node.position = Vector2(0, -50) 
		k_sturret.show()
	
	# --- PERBAIKAN DURASI ---
	# Gunakan Node Timer, bukan get_tree().create_timer
	# Saat game dipause, timer ini akan berhenti menghitung.
	skill_timer.start(6.0) # Durasi Laser 6 detik
	await skill_timer.timeout
	
	# Clear Laser
	if active_laser_node != null:
		active_laser_node.queue_free()
		active_laser_node = null
		print("Kraken selesai.")
		k_sturret.hide()
	
	is_kraken_active = false
	anim_cannon.show()
	
# --- LOGIKA BARU: SECOND WIND (REVIVE) ---
func activate_second_wind():
	has_second_wind = true
	print("Second Wind Ready! (Nyawa cadangan aktif)")
	# Opsional: Tambahkan visual effect (misal aura putih)

func activate_admiral():
	print("ADMIRAL'S WILL ACTIVATED! Musuh Terhenti!")
	
	# 1. Efek Visual: Flash Layar Kuning
	modulate = Color(3, 3, 0, 1) # Terang banget (Kuning)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.5)
	
	# 2. Panggil grup "enemies" untuk stop bergerak
	# Pastikan di dummy.gd sudah ada add_to_group("enemies")
	get_tree().call_group("enemies", "set_paralyzed", true)
	
	# 3. Tunggu 5 Detik
	skill_timer.start(5.0)
	await skill_timer.timeout
	
	# 4. Kembalikan musuh jadi normal
	print("Admiral's Will berakhir.")
	get_tree().call_group("enemies", "set_paralyzed", false)

func apply_dizziness(duration):
	if is_dead:
		return
	
	print("PLAYER KENA MENTAL! PUSING!")
	is_dizzy = true
	dizzy_timer = duration


func trigger_shockwave():
	# Efek visual (opsional, misal flash layar)
	modulate = Color(10, 10, 10, 1) # Flash putih terang
	shockwaves_anim.play("shocking")
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.5) # Fade balik ke normal
	
	# LOGIKA MEMBUNUH SEMUA MUSUH
	# Kita panggil grup "enemies" yang sudah kita buat di Langkah 1
	get_tree().call_group("enemies", "take_damage", 9999)
	await shockwaves_anim.animation_finished
	shockwaves_anim.hide()

func _physics_process(delta: float) -> void:
	if is_dizzy:
		dizzy_timer -= delta
		if dizzy_timer <= 0:
			is_dizzy = false
			modulate = Color.WHITE
			print("GA PUSING LAGI")
	
	var direction := Input.get_axis("Left", "Right") # (kuganti biar bisa WASD - kaiser)
	
	if is_dizzy:
		direction = -direction
	
	if direction:
		velocity.x = direction * current_speed
		move_and_slide()
	else:
		var direction_to_center = (target_position - global_position).normalized()
		if global_position.distance_to(target_position) > 0.05: # Check if not at center
			velocity.x = lerp(velocity.x, direction_to_center.x * 300, delta * 0.9) #slowly make itsw way to the centerr
			rotation = lerp(rotation, direction_to_center.x * 2.5, delta * 0.2) #slowly adjust its rotation
			move_and_slide()
		else: #sudah di center
			global_position = target_position
			velocity = Vector2.ZERO
			rotation = lerp(rotation, 0.0, delta * 1.0)
	#animation
	if direction < 0:
		for node in get_tree().get_nodes_in_group("player_anims"):
				node.play("left")
		k_sturret.position.x = -15.0
	elif direction > 0:
		for node in get_tree().get_nodes_in_group("player_anims"):
				node.play("right")
		k_sturret.position.x = +15.0
	else:
		for node in get_tree().get_nodes_in_group("player_anims"):
				node.play("idle")
		k_sturret.position.x = 0


	# if is_dizzy == true:
	# 	if Input.is_action_pressed("Left"):
	# 		_animation_player.play("left")
	# 		k_sturret.position.x = 15.0
	# 	elif Input.is_action_pressed("Right"):
	# 		_animation_player.play("right")
	# 		k_sturret.position.x = -15.0
	# 	else:
	# 		_animation_player.play("idle")
	# elif is_dizzy == false:
	# 	if Input.is_action_pressed("Left"):
	# 		_animation_player.play("left")
	# 		k_sturret.position.x = -15.0
	# 	elif Input.is_action_pressed("Right"):
	# 		_animation_player.play("right")
	# 		k_sturret.position.x = 15.0
	# 	else:
	# 		_animation_player.play("idle")
	
	# rotasi kapal
	rotation_direction = Input.get_axis("Left", "Right") # (kuganti biar bisa WASD - kaiser)
	
	if is_dizzy:
		rotation_direction = -rotation_direction
	
	var rot = rotation
	if velocity.x != 0:
		rot += rotation_direction * rotation_speed * delta
		var rotation_minmax = clamp(rot, -PI/8, PI/8) #max dan min rotasi
		rotation = rotation_minmax

	#move_and_slide()
	
func spawn_bullet(angle_in_degrees):
	var bullet = bullet_scene.instantiate()
	
	# Set posisi awal
	bullet.global_position = $FiringPosition.global_position
	
	# Set rotasi peluru (konversi derajat ke radian karena Godot pakai radian)
	bullet.rotation_degrees = rotation_degrees + angle_in_degrees
	
	# Ganti texture
	if is_artillery_active:
		# Kita cari node Sprite2D di dalam scene peluru
		# NOTE: Pastikan nama node sprite di scene bulletplayer.tscn adalah "Sprite2D"
		var sprite = bullet.get_node_or_null("Sprite2D")
		
		if sprite:
			sprite.texture = tex_artillery
			# Opsional: Ubah skala jika gambar artillery terlalu besar/kecil
			# sprite.scale = Vector2(1.5, 1.5)
			
	# Tambahkan ke Main Scene
	get_parent().add_child(bullet)
	
func reset_all_skills():
	print("Membersihkan semua skill aktif...")
	
	# ... (Reset skill lain yg sudah ada) ...
	is_kraken_active = false
	is_multishot_active = false
	is_artillery_active = false
	has_shield = false
	has_second_wind = false
	
	if has_node("SkillDurationTimer"):
		$SkillDurationTimer.stop()

	if shoot_timer:
		shoot_timer.wait_time = 0.2 
	
	current_speed = normal_speed
	rotation_speed = 2 

	if active_laser_node != null and is_instance_valid(active_laser_node):
		active_laser_node.queue_free()
		active_laser_node = null

	is_dizzy = false
	dizzy_timer = 0.0
	modulate = Color.WHITE

	get_tree().call_group("enemies", "set_paralyzed", false)

func _on_timer_timeout() -> void: # Timer
	# Pasang gatekeeping peluru
	if is_kraken_active:
		return
		
	if is_multishot_active:
		# Tembak 3 peluru (Kiri, Tengah, Kanan)
		spawn_bullet(-15) # -15 derajat
		spawn_bullet(0)   # Lurus
		spawn_bullet(15)  # +15 derajat
	elif is_artillery_active:
		# Artillery mungkin menembak lurus tapi banyak/cepat
		spawn_bullet(0)
	else:
		# Tembak 1 peluru normal
		spawn_bullet(0)
		
	
func exploded():
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)
	
