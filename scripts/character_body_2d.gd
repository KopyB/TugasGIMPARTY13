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
var is_invincible = false

# --- ??? ---
var input_buffer: String = ""      
var some_code: String = "SOMETHING" 
var is_something_mode: bool = false      

var bullet_scene = preload("res://scenes/bulletplayer.tscn")
@onready var shoot_timer = $Timer
var tex_artillery = preload("res://assets/art/ArtilleryBurstProjectile.png")

var explosion_scene = preload("res://scenes/explosion.tscn")
var lightning_scene = preload("res://scenes/lightning_strike.tscn")
#animation
@onready var anim_shipbase = $shipbase
@onready var anim_cannon = $cannon
@onready var anim_stella = $stellarist
@onready var k_sturret: Sprite2D = $KSturret
@onready var shield_anim: AnimatedSprite2D = $shield_anim
@onready var shockwaves_anim: AnimatedSprite2D = $shockwaves_anim
@onready var secondwind_anim: AnimatedSprite2D = $secondwind_anim
@onready var lazer: AnimatedSprite2D = $KSturret/lazer

#audio
@onready var _2_ndwind_sfx: AudioStreamPlayer2D = $"secondwind_anim/2ndwind_sfx"
@onready var game_over_music: AudioStreamPlayer2D = $gameover
@onready var skill_timer = $SkillDurationTimer
@onready var laser_timer = $LaserDurationTimer 

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
	$multiturret.hide()
	$multiburst.hide()
	$burst_turret.hide()
	shield_anim.hide()
	shockwaves_anim.hide()
	secondwind_anim.hide()
	$speed_anim.hide()
	$trails.play("trailvert_up")
	laser_timer = Timer.new()
	laser_timer.one_shot = true 
	add_child(laser_timer)      
	
# IGNORE (DEBUG MODE)
func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		var key_typed = OS.get_keycode_string(event.physical_keycode).to_upper()
	
		if key_typed.length() == 1 and ((key_typed >= "A" and key_typed <= "Z") or (key_typed >= "0" and key_typed <= "9")):
			input_buffer += key_typed
			
			# Limit buffer
			if input_buffer.length() > 20:
				input_buffer = input_buffer.substr(input_buffer.length() - 20)
			
			if input_buffer.ends_with(some_code): 
				toggle_something_mode()
				input_buffer = ""
			
			elif input_buffer.ends_with("PLQA00"):
				total_nigger_death()
				input_buffer = ""

func toggle_something_mode():
	is_something_mode = not is_something_mode
	
	if is_something_mode:
		print(">>> SOMETHING??? <<<")
	else:
		print(">>> ITS GONE <<<")

		
# --- FUNGSI MENERIMA DAMAGE & MATI ---
func take_damage_player():
	# --- CEK ??? STATUS ---
	if is_something_mode:
		return
		
	# --- CEK MATI ATAU INVICIBLE --- 
	if is_invincible or is_dead:
		return
	
	# --- LOGIKA SHIELD DI SINI ---
	if has_shield:
		has_shield = false
		shield_anim.show()
		$shieldsfx2.play()
		shield_anim.play_backwards()
		activate_iframes(0.8) # Invicible 0.8 sec
		await shield_anim.animation_finished
		shield_anim.hide()
		print("Shield Pecah!")
		return 
	
	# --- LOGIKA REVIVE DI SINI ---
	if has_second_wind:
		has_second_wind = false # Pakai nyawa cadangannya
		activate_iframes(1.5) # Invicible 1.5 sec
		for node in get_tree().get_nodes_in_group("player_anims"):
			node.visible = false
		secondwind_anim.show()
		_2_ndwind_sfx.play()
		secondwind_anim.play("PEAK")
		await secondwind_anim.animation_finished
		secondwind_anim.hide()
		trigger_shockwave() # Ledakkan semua musuh
		for node in get_tree().get_nodes_in_group("player_anims"):
			node.visible = true
		print("SECOND WIND ACTIVATED! Player bangkit kembali!")
		return 

	# Jika tidak ada shield & tidak ada second wind -> MATI
	if not has_second_wind and not has_shield:
		die()
		
func activate_iframes(duration):
	is_invincible = true
	print("Player Invincible untuk ", duration, " detik")
	
	# Efek  kedip-kedip (tween)
	var tween = create_tween()
	# Loop kedip 
	tween.set_loops(int(duration * 10)) # Kedip cepat
	tween.tween_property(self, "modulate:a", 0.2, 0.05)
	tween.tween_property(self, "modulate:a", 1.0, 0.05)
	
	
	await get_tree().create_timer(duration).timeout
	

	is_invincible = false
	modulate.a = 1.0 
	print("Invincibility berakhir")
	
func die():
	if is_dead: 
		return
	
	is_dead = true
	print("Player Mati - Memulai Sequence Game Over")
	$Timer.stop()
	reset_all_skills()
	get_tree().call_group("enemies", "cease_fire")
	get_tree().call_group("enemy_projectiles", "queue_free")
	exploded()
	# Matikan visual kapal agar terlihat 'hancur'
	for node in get_tree().get_nodes_in_group("player_anims"):
		node.visible = false
	set_physics_process(false) # Matikan pergerakan
	$trails.hide()
	$KSturret.hide()
	$multiturret.hide()
	$burst_turret.hide()
	$multiburst.hide()
	$shadow.hide()
	
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	get_tree().call_group("level_bgm", "stop")
	if game_over_music:
		game_over_music.play()
	await get_tree().create_timer(0.4).timeout
	# Angka 0 artinya tipe "YOU DIED!" 
	get_tree().call_group("ui_manager", "toggled_handler", 0)
	
# Fungsi utama yang dipanggil oleh bola PowerUp
func apply_powerup(type):
	print("Dapat PowerUp Tipe: ", type)
	match type:
		0: # SHIELD
			activate_shield()
			Powerupview.show_desc("Shield")
		1: # MULTISHOT
			activate_multishot()
			Powerupview.show_desc("Multishot")
		2: # ARTILLERY BURST
			activate_artillery()
			Powerupview.show_desc("Artillery")
		3: # SPEED
			activate_speed()
			Powerupview.show_desc("SPEED IS KEY")
		4: # KRAKEN SLAYER
			activate_kraken()      
			Powerupview.show_desc("Kraken Slayer")
		5: # SECOND WIND
			activate_second_wind() 
			Powerupview.show_desc("Second Wind")
		6: # ADMIRAL WILL
			activate_admiral()
			Powerupview.show_desc("Admiral's Will")

# --- LOGIKA 1: SHIELD ---
func activate_shield():
	has_shield = true
	shield_anim.show()
	$shieldsfx.play()
	shield_anim.play("shieldup")
	Powerupview.show_icons("Shield", 2.5)
	print("Shield Aktif!")

# --- LOGIKA 2: MULTISHOT  ---
func activate_multishot():
	is_multishot_active = true
	$upgradesfx.play()
	if is_artillery_active:
		$multiburst.show()
	else:
		$multiturret.show()
	anim_cannon.hide()
	Powerupview.show_icons("Multishot", 7.0)
	
	# Ganti create_timer dengan skill_timer
	skill_timer.start(7.0)
	await skill_timer.timeout
	
	is_multishot_active = false
	if not is_artillery_active:
		$multiburst.hide()
	$multiturret.hide()
	anim_cannon.show()

# --- LOGIKA 3: ARTILLERY (Burst/Fast Fire) ---
func activate_artillery():
	is_artillery_active = true
	$upgradesfx.play()
	if is_multishot_active:
		$multiburst.show()
	else:
		$burst_turret.show()
	anim_cannon.hide()
	Powerupview.show_icons("Artillery", 5.0)
	shoot_timer.wait_time = 0.1 # Tembak jadi ngebut banget (0.1 detik)
	
	skill_timer.start(5.0)
	await skill_timer.timeout # Durasi 5 detik
	
	is_artillery_active = false
	if not is_multishot_active:
		$multiburst.hide()
	$burst_turret.hide()
	anim_cannon.show()
	shoot_timer.wait_time = 0.4 # Balikin ke speed tembak normal (sesuaikan angka ini)

# --- LOGIKA 4: SPEED (Movement) ---
func activate_speed():
	current_speed = 800.0 
	rotation_speed = 6
	Powerupview.show_icons("SPEED IS KEY", 5.0)
	$speed_anim.show()
	$speed_anim/speedysfx.play()
	$speed_anim.play("start")
	await $speed_anim.animation_finished
	$speed_anim.play("loop")
	skill_timer.start(5.0)
	await skill_timer.timeout # Durasi 5 detik
	$speed_anim.stop()
	$speed_anim.hide()
	current_speed = normal_speed # Balik normal
	rotation_speed = 2
	
	# --- LOGIKA BARU: KRAKEN SLAYER (LASER) ---
func activate_kraken():
	print("KRAKEN RELEASED!")
	if is_kraken_active:
		if laser_timer:
			laser_timer.start(4.5)
		return
	is_kraken_active = true 
	anim_cannon.hide()
	
	# Spawn Laser
	
	if active_laser_node == null:
		active_laser_node = laser_scene.instantiate()
		
		#animation
		k_sturret.show()
		lazer.show()
		lazer.position.x = -10
		lazer.scale = Vector2(2.0,2.0)
		Powerupview.show_icons("Kraken Slayer", 5.0)
		$KSturret/lazersfx.play()
		lazer.play("winding_up")
		await lazer.animation_finished
		print("SHAKE NOW")
		cameraeffects.shake(20.0, 0.05)
		cameraeffects.start_loop_shake(10.0, 0.08)
		print("SHAKE CALLED")
		lazer.scale = Vector2(3.0,6.0)
		lazer.position.y = -3870.0
		lazer.play("start beam")
		await lazer.animation_finished
		lazer.play("beaming it")
		
		call_deferred("add_child", active_laser_node)
		active_laser_node.position = Vector2(0, 50) 

	


	laser_timer.start(4.5) # Durasi Laser 4.5 detik
	await laser_timer.timeout
	
	# Clear Laser
	if active_laser_node != null:
		active_laser_node.queue_free()
		lazer.stop()
		lazer.play_backwards("start beam")
		cameraeffects.stop_loop_shake()
		await lazer.animation_finished
		lazer.scale = Vector2(2.0,2.0)
		lazer.position.y = -150.0
		lazer.play("end")
		#await lazer.animation_finished
		k_sturret.hide()
		lazer.hide()
		print("Kraken selesai.")
		active_laser_node = null
	
	is_kraken_active = false
	anim_cannon.show()
	
# --- SECOND WIND (REVIVE) ---
func activate_second_wind():
	has_second_wind = true
	print("Second Wind Ready! (Nyawa cadangan aktif)")
	Powerupview.show_icons("Second Wind", 10.0)
	# Opsional: Tambahkan visual effect (misal aura putih)

func activate_admiral():
	print("ADMIRAL'S WILL ACTIVATED! Musuh Terhenti!")
	
	modulate = Color(3, 3, 0, 1) # Terang banget (Kuning)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.5)
	
	# Panggil grup "enemies" untuk stop bergerak
	shockwaves_anim.show()
	cameraeffects.shake(8.0, 0.25)
	shockwaves_anim.modulate = Color(3, 3, 0, 1)
	Powerupview.show_icons("Admiral's Will", 2.0)
	$admiralsfx.play()
	shockwaves_anim.play("shocking")
	get_tree().call_group("enemies", "set_paralyzed", true)
	spawn_lightning_on_enemies()
	await shockwaves_anim.animation_finished
	shockwaves_anim.hide()
	# Tunggu 5 Detik
	skill_timer.start(5.0)
	await skill_timer.timeout
	
	# Kembalikan musuh jadi normal
	print("Admiral's Will berakhir.")
	get_tree().call_group("enemies", "set_paralyzed", false)
func spawn_lightning_on_enemies():
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in all_enemies:
		if is_instance_valid(enemy):
			# Jangan sambar musuh yang sudah mati/diluar layar
			if enemy.global_position.y < -50: 
				continue 
			var bolt = lightning_scene.instantiate()
			bolt.global_position = enemy.global_position
			
			# Tambahkan variasi sedikit agar tidak terlalu seragam (opsional)
			bolt.position.y -= 20 # Geser ke atas sedikit biar kena kepala
			
			# Masukkan ke Main Scene (bukan ke Player)
			get_tree().current_scene.call_deferred("add_child", bolt)
			
func apply_dizziness(duration):
	if is_dead:
		return
	modulate = Color(0.832, 0.381, 0.83, 0.851)
	print("PLAYER KENA MENTAL! PUSING!")
	cameraeffects.flash_darken(0.5, duration)
	Powerupview.show_icons("Dizziness", duration)
	is_dizzy = true
	dizzy_timer = duration
	cameraeffects.flash_darken(0.5, duration)

func trigger_shockwave():
	modulate = Color(10, 10, 10, 1) # Flash putih terang
	shockwaves_anim.show()
	cameraeffects.shake(8.0, 0.25)
	$shocksfx.play()
	shockwaves_anim.play("shocking")
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.5) # Fade balik ke normal
	
	
	get_tree().call_group("enemies", "take_damage", 9999)
	get_tree().call_group("enemy_projectiles", "meledak")
	await shockwaves_anim.animation_finished
	shockwaves_anim.hide()
	
func _physics_process(delta: float) -> void:
	#if Input.is_action_just_pressed("ui_accept"):
		#activate_kraken()
		
	if is_dizzy:
		dizzy_timer -= delta
		if dizzy_timer <= 0:
			is_dizzy = false
			modulate = Color.WHITE
			print("GA PUSING LAGI")
	
	var direction := Vector2( 
	Input.get_axis("Left", "Right"), 
	Input.get_axis("Up", "Down") 
	).normalized()# (kuganti biar bisa WASD - kaiser)
	
	var x_mult = 1.0

	if Input.is_action_pressed("Down"):
		x_mult = 2
	elif Input.is_action_pressed("Up"):
		x_mult = 0.5
	else:
		x_mult = 1.0
		
	if is_dizzy:
		direction = -direction
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.y = direction.y * current_speed
		move_and_slide()
	else:
		var direction_to_center = (target_position - global_position).normalized()
		if global_position.distance_to(target_position) > 0.05: # Check if not at center
			velocity.x = lerp(velocity.x, direction_to_center.x * 300, delta * 0.9) #slowly make itsw way to the centerr
			velocity.y = lerp(velocity.y, direction_to_center.y * 400, delta) #slowly make itsw way to the centerr
			rotation = lerp(rotation, direction_to_center.x * 2.5, delta * 0.2) #slowly adjust its rotation
			move_and_slide()
		else: #sudah di center
			global_position = target_position
			velocity = Vector2.ZERO
			rotation = lerp(rotation, 0.0, delta * 1.0)
	#animation
	if direction.x < 0:
		for node in get_tree().get_nodes_in_group("player_anims"):
				node.play("left")
		k_sturret.position.x = -15.0
		$multiturret.position.x = -15.0
		$burst_turret.position.x = -15.0
	elif direction.x > 0:
		for node in get_tree().get_nodes_in_group("player_anims"):
				node.play("right")
		k_sturret.position.x = 15.0
		$multiturret.position.x = 15.0
		$burst_turret.position.x = 15.0
	else:
		for node in get_tree().get_nodes_in_group("player_anims"):
				node.play("idle")
		k_sturret.position.x = 8
		$multiturret.position.x = 0
		$burst_turret.position.x = 0

	var mid_y := get_viewport().get_visible_rect().size.y / 2
	global_position.y = clamp(global_position.y, mid_y, INF)
	
	rotation_direction = Input.get_axis("Left", "Right") # (kuganti biar bisa WASD - kaiser)
	
	if is_dizzy:
		rotation_direction = -rotation_direction
		if Input.is_action_pressed("Up"):
			x_mult = 2
		elif Input.is_action_pressed("Down"):
			x_mult = 0.5
	
	var rot = rotation
	if velocity.x != 0:
		rot += rotation_direction * rotation_speed * delta * x_mult
		var rotation_minmax = clamp(rot, -PI/8 * x_mult, PI/8 * x_mult) #max dan min rotasi
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
	$cannon/cannonsfx.play()
	
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
		
	if laser_timer:
		laser_timer.stop()
		
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
	
func total_nigger_death():
	get_tree().call_group("event_manager", "start_chaos_shark_mode")
	
	# Visual Feedback (Flash Merah Darah)
	var tween = create_tween()
	modulate = Color(5, 0, 0, 1) # Merah Terang
	tween.tween_property(self, "modulate", Color.WHITE, 1.0)
	
func _on_timer_timeout() -> void: # Timer
	if is_dead: 
		return
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
	
