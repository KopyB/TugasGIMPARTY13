extends CharacterBody2D

var target_position : Vector2
# VARIABEL MOVEMENT
var rotation_speed = 2
var rotation_direction = 0
var normal_speed = 300.0
var current_speed = normal_speed

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

#animation
@onready var _animation_player = $AnimatedSprite2D

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

# --- LOGIKA 1: SHIELD ---
func activate_shield():
	has_shield = true
	modulate = Color(0.5, 0.5, 1, 1) # Ubah warna player jadi kebiruan (visual)
	print("Shield Aktif!")

# --- LOGIKA 2: MULTISHOT (Sudah Anda punya) ---
func activate_multishot():
	is_multishot_active = true
	await get_tree().create_timer(7.0).timeout # Durasi 7 detik
	is_multishot_active = false

# --- LOGIKA 3: ARTILLERY (Burst/Fast Fire) ---
func activate_artillery():
	is_artillery_active = true
	shoot_timer.wait_time = 0.1 # Tembak jadi ngebut banget (0.1 detik)
	
	await get_tree().create_timer(5.0).timeout # Durasi 5 detik
	
	is_artillery_active = false
	shoot_timer.wait_time = 0.2 # Balikin ke speed tembak normal (sesuaikan angka ini)

# --- LOGIKA 4: SPEED (Movement) ---
func activate_speed():
	current_speed = 800.0 
	rotation_speed = 6
	
	await get_tree().create_timer(5.0).timeout # Durasi 5 detik
	
	current_speed = normal_speed # Balik normal
	rotation_speed = 2
	
	# --- LOGIKA BARU: KRAKEN SLAYER (LASER) ---
func activate_kraken():
	print("KRAKEN RELEASED!")
	
	# Deactivate gatekeeping timer
	is_kraken_active = true 
	
	# Spawn Laser 
	if active_laser_node == null:
		active_laser_node = laser_scene.instantiate()
		add_child(active_laser_node)
		active_laser_node.position = Vector2(0, -50) 
	
	# Duration Skill (laser)
	await get_tree().create_timer(6.0).timeout
	
	# ClearLaser
	if active_laser_node != null:
		active_laser_node.queue_free()
		active_laser_node = null
		print("Kraken selesai.")
	
	# Nyalakan kembali peluru biasa
	is_kraken_active = false

# --- LOGIKA BARU: SECOND WIND (REVIVE) ---
func activate_second_wind():
	has_second_wind = true
	print("Second Wind Ready! (Nyawa cadangan aktif)")
	# Opsional: Tambahkan visual effect (misal aura putih)

# --- FUNGSI MENERIMA DAMAGE & MATI ---
# Pastikan logika mati Anda ada di fungsi ini
func take_damage_player():
	# --- LOGIKA SHIELD DI SINI ---
	if has_shield:
		has_shield = false
		modulate = Color(1, 1, 1, 1)
		print("Shield Pecah!")
		return 
	
	# --- LOGIKA REVIVE DI SINI ---
	if has_second_wind:
		trigger_shockwave() # Ledakkan semua musuh
		has_second_wind = false # Pakai nyawa cadangannya
		print("SECOND WIND ACTIVATED! Player bangkit kembali!")
		return 

	# Jika tidak ada shield & tidak ada second wind -> MATI
	game_over()

func game_over():
	print("Game Over")
	get_tree().reload_current_scene()

func trigger_shockwave():
	# Efek visual (opsional, misal flash layar)
	modulate = Color(10, 10, 10, 1) # Flash putih terang
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.5) # Fade balik ke normal
	
	# LOGIKA MEMBUNUH SEMUA MUSUH
	# Kita panggil grup "enemies" yang sudah kita buat di Langkah 1
	get_tree().call_group("enemies", "take_damage", 9999)
	
func _ready():
	target_position = global_position # Store initial position as center
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("Left", "Right") # (kuganti biar bisa WASD - kaiser)
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
	if Input.is_action_pressed("ui_left"):
		_animation_player.play("left")
	elif Input.is_action_pressed("ui_right"):
		_animation_player.play("right")
	else:
		_animation_player.play("idle")
	
	# rotasi kapal
	rotation_direction = Input.get_axis("Left", "Right") # (kuganti biar bisa WASD - kaiser)
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
	
	# Tambahkan ke Main Scene
	get_parent().add_child(bullet)

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
		
	
