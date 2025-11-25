extends Node2D

var obstacle_scene = preload("res://scenes/obstacle.tscn")
var enemy_scene = preload("res://scenes/dummy.tscn") # Load scene musuh untuk spawn Shark

# --- CONFIG MAZE ---
var columns = 8          
var block_size = 60      
var spawn_y = -100       
var rows_to_spawn = 8      
var rows_spawned_count = 0
var maze_row_interval = 2.0
var maze_timer = 0.0

# --- CONFIG SHARK EVENT ---
var is_shark_event_active = false
var shark_timer = 0.0
var next_shark_time = 0.0

# --- GLOBAL STATE ---
var is_maze_active = false # Ganti nama 'is_spawning' jadi lebih jelas
var maze_cooldown_timer = 0.0
var next_maze_time = 45.0 
var current_gap_index = 4  

func _ready():
	var screen_width = get_viewport_rect().size.x
	block_size = screen_width / columns
	randomize()
	
	# Setup waktu event pertama
	next_maze_time = randf_range(50.0, 60.0)
	next_shark_time = randf_range(70.0, 90.0) # Sesuai request (70-90 detik)
	
	print("Next Maze: %.1f | Next Shark: %.1f" % [next_maze_time, next_shark_time])

func _process(delta):
	# LOGIKA UTAMA: Cek apakah ada event yang sedang aktif?
	var any_event_active = is_maze_active or is_shark_event_active
	
	if not any_event_active:
		# --- FASE MENUNGGU (Semua timer jalan) ---
		
		# 1. Hitung Timer Maze
		maze_cooldown_timer += delta
		if maze_cooldown_timer >= next_maze_time:
			start_maze_event()
			return # Prioritas: Langsung return agar tidak cek shark di frame yang sama

		# 2. Hitung Timer Shark
		shark_timer += delta
		if shark_timer >= next_shark_time:
			start_shark_event()
			
	else:
		# --- FASE EVENT SEDANG JALAN ---
		
		# Jika Maze aktif, jalankan logika spawn row maze
		if is_maze_active:
			maze_timer += delta
			if maze_timer >= maze_row_interval:
				maze_timer = 0
				spawn_maze_row()
		
		# Jika Shark aktif, logikanya dihandle via Coroutine (await), 
		# jadi tidak perlu code di _process.

# =========================================
#           LOGIKA SHARK ATTACK
# =========================================

func start_shark_event():
	print("!!! WARNING: SHARK ATTACK EVENT STARTED !!!")
	is_shark_event_active = true
	shark_timer = 0.0 # Reset timer
	
	# 1. Pause Musuh Biasa
	get_tree().call_group("spawner_utama", "pause_spawning")
	
	# 2. Tampilkan Warning 
	# Beri jeda 2 detik agar player siap
	await get_tree().create_timer(2.0).timeout
	
	# 3. Mulai Spawn Gelombang Shark
	spawn_shark_waves()

func spawn_shark_waves():
	# Konfigurasi wave spawn:
	var total_waves = randi_range(2, 4)      # Ada 3-5 gelombang serangan
	
	for i in range(total_waves):
		# Cek jika scene sudah ganti/game over, hentikan loop
		if not is_inside_tree(): return 
		
		var sharks_this_wave = randi_range(5, 10)
		print(">>> Wave %d/%d: Spawning %d Sharks" % [i + 1, total_waves, sharks_this_wave])
		
		# Spawn Hiu dalam wave ini
		for j in range(sharks_this_wave):
			spawn_single_shark()
			# Jeda kecil antar hiu dalam satu wave (biar ga numpuk)
			await get_tree().create_timer(randf_range(0.25, 1.0)).timeout
		
		if i < total_waves - 1: # Rest
			await get_tree().create_timer(randf_range(4.0, 6.0)).timeout
	
	# Selesai semua wave
	end_shark_event()

func spawn_single_shark():
	var shark = enemy_scene.instantiate()
	shark.enemy_type = 4 # TORPEDO SHARK
	
	var viewport_rect = get_viewport_rect().size
	var spawn_pos = Vector2.ZERO
	
	# Random Spawn: Atas, Kiri, atau Kanan (Mirip EnemySpawner)
	var spawn_side = randi() % 3
	
	if spawn_side == 0: # Atas
		spawn_pos.x = randf_range(50, viewport_rect.x - 50)
		spawn_pos.y = -60
	elif spawn_side == 1: # Kiri
		spawn_pos.x = -60
		spawn_pos.y = randf_range(50, viewport_rect.y / 3)
	else: # Kanan
		spawn_pos.x = viewport_rect.x + 60
		spawn_pos.y = randf_range(50, viewport_rect.y / 3)
	
	shark.global_position = spawn_pos
	
	# PENTING: Add ke current_scene agar koordinat aman
	get_tree().current_scene.call_deferred("add_child", shark)

func end_shark_event():
	print("!!! SHARK ATTACK EVENT ENDED !!!")
	is_shark_event_active = false
	
	# Tentukan waktu event Shark berikutnya (Random lagi)
	next_shark_time = randf_range(70.0, 90.0) 
	
	# Resume Musuh Biasa
	get_tree().call_group("spawner_utama", "resume_spawning")


# =========================================
#           LOGIKA MAZE (EXISTING)
# =========================================

func start_maze_event():
	print("!!! EVENT MAZE DIMULAI !!!")
	is_maze_active = true
	rows_spawned_count = 0
	maze_cooldown_timer = 0 

	current_gap_index = randi() % (columns - 2) + 1
	get_tree().call_group("spawner_utama", "pause_spawning")

func end_maze_event():
	print("!!! EVENT MAZE SELESAI !!!")
	is_maze_active = false
	next_maze_time = randf_range(45.0, 70.0) 
	get_tree().call_group("spawner_utama", "resume_spawning")

func spawn_maze_row():
	if rows_spawned_count >= rows_to_spawn:
		end_maze_event()
		return

	rows_spawned_count += 1
	var move = randi() % 3 - 1 
	if randf() < 0.2:
		move = move * 2
	
	current_gap_index += move
	current_gap_index = clamp(current_gap_index, 1, columns - 2)

	for i in range(columns):
		if i == current_gap_index or i == current_gap_index + 1:
			continue 
		if randf() > 0.3:
			spawn_obstacle_at_column(i)

func spawn_obstacle_at_column(col_index):
	var obs = obstacle_scene.instantiate()
	var pos_x = (col_index * block_size) + (block_size / 2)
	obs.position = Vector2(pos_x, spawn_y)
	obs.is_maze_obstacle = true 

	var type_rng = randf()
	if type_rng < 0.7: obs.setup_obstacle(0) 
	else: obs.setup_obstacle(1) 

	add_child(obs)
