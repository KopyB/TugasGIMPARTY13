extends CharacterBody2D

var target_position : Vector2
const SPEED = 500.0
var rotation_speed = 2
var rotation_direction = 0

var bullet_scene = preload("res://scenes/bulletplayer.tscn")
var is_multishot_active = false
var multishot_timer = null # Kita akan buat timer via kode

func activate_multishot():
	print("Multishot Aktif!")
	is_multishot_active = true
	
	# Reset timer jika ambil bola lagi saat skill masih aktif
	if multishot_timer:
		multishot_timer.time_left = 7.0
	else:
		# Buat timer baru sementara (One Shot)
		multishot_timer = get_tree().create_timer(7.0)
		await multishot_timer.timeout
		
		# Setelah 7 detik:
		is_multishot_active = false
		multishot_timer = null
		print("Multishot Habis.")
		
func _ready():
	target_position = global_position # Store initial position as center
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
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
	
	# rotasi kapal
	rotation_direction = Input.get_axis("ui_left", "ui_right")
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

func _on_timer_timeout() -> void: # BURST MODE
	if is_multishot_active:
		# Tembak 3 peluru (Kiri, Tengah, Kanan)
		spawn_bullet(-15) # -15 derajat
		spawn_bullet(0)   # Lurus
		spawn_bullet(15)  # +15 derajat
	else:
		# Tembak 1 peluru normal
		spawn_bullet(0)
		
	
