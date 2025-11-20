extends Marker2D

var enemy_scene = preload("res://scenes/dummy.tscn")
@onready var spawn_timer = $SpawnTimer # Referensi ke Node Timer

func _ready():
	# Pastikan Timer dimulai
	randomize() # Agar acakan selalu beda tiap game
	
	# Jika belum autostart, start manual:
	if spawn_timer.is_stopped():
		spawn_timer.start()
		
func _on_spawn_timer_timeout() -> void:
	spawn_random_enemy()
	
	var random_interval = randf_range(2.0, 4.0)
	spawn_timer.start(random_interval)

func spawn_random_enemy():
	var new_enemy = enemy_scene.instantiate()
	var viewport_rect = get_viewport_rect().size
	
	var type_rng = randi() % 2
	
	# --- SOLUSI 1 & 2: POSISI SPAWN ---
	# Kita gunakan 'global_position' agar posisinya fix di layar
	# tidak peduli dimana Anda menaruh node EnemySpawner.
	
	if type_rng == 0: 
		# GUNBOAT (Atas ke Bawah)
		new_enemy.enemy_type = 0
		
		# X: Acak dari kiri (50) sampai kanan ujung (lebar layar - 50)
		var spawn_x = randf_range(50, viewport_rect.x - 50)
		
		# Y: Di atas layar (-60)
		new_enemy.global_position = Vector2(spawn_x, -60)
		
	else: 
		# BOMBER (Kiri ke Kanan)
		new_enemy.enemy_type = 1
		
		# X: Di kiri layar (-60)
		var spawn_x = -60
		
		# Y: Acak dari atas (50) sampai setengah layar
		var spawn_y = randf_range(50, viewport_rect.y / 2)
		
		new_enemy.global_position = Vector2(spawn_x, spawn_y)
	
	# PENTING: Tambahkan musuh ke Scene Utama, bukan sebagai anak Spawner
	# Ini mencegah musuh ikut posisi Spawner yang mungkin salah.
	get_tree().current_scene.add_child(new_enemy)
